import 'package:mqtt_client/mqtt_client.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'mqtt_client_mobile.dart'
    if (dart.library.js_interop) 'mqtt_client_web.dart';

class MqttService {
  static MqttClient? _client;
  static bool _isConnected = false;

  static final List<Function(String room, Map<String, dynamic> status)>
      _roomStatusListeners = [];

  static void addRoomStatusListener(
      Function(String room, Map<String, dynamic> status) listener) {
    _roomStatusListeners.add(listener);
  }

  static void removeRoomStatusListener(
      Function(String room, Map<String, dynamic> status) listener) {
    _roomStatusListeners.remove(listener);
  }

  static Future<bool> connect() async {
    if (_isConnected &&
        _client?.connectionStatus?.state == MqttConnectionState.connected) {
      if (kDebugMode) print('Already connected, skipping...');
      return true;
    }

    try {
      final clientId = 'flutter_app_${DateTime.now().millisecondsSinceEpoch}';
      const host = '5bfa9f7980ac429fb1cfa0433d7bcc07.s1.eu.hivemq.cloud';

      if (kDebugMode) print('Platform: ${kIsWeb ? "Web" : "Mobile"}');

      _client = buildMqttClient(host, clientId);

      _client!.setProtocolV311();

      configureWebProtocols(_client!);

      _client!.keepAlivePeriod = 20;
      _client!.autoReconnect = true;
      _client!.resubscribeOnAutoReconnect = true;
      _client!.onConnected = _onConnected;
      _client!.onDisconnected = _onDisconnected;
      _client!.onSubscribed = _onSubscribed;
      _client!.logging(on: kDebugMode);

      final connMessage = MqttConnectMessage()
          .authenticateAs('smart_classroom_app', 'Sendy0908')
          .withClientIdentifier(clientId)
          .withWillQos(MqttQos.atLeastOnce)
          .startClean()
          .withWillRetain();

      _client!.connectionMessage = connMessage;

      if (kDebugMode) print('Connecting to MQTT (timeout: 30s)...');

      try {
        await _client!.connect().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            if (kDebugMode) print('Connection timeout');
            _client?.disconnect();
            throw TimeoutException('MQTT connection timeout');
          },
        );
      } catch (e) {
        if (kDebugMode) print('Connection exception: $e');
        _client?.disconnect();
        _isConnected = false;
        return false;
      }

      if (_client?.connectionStatus?.state == MqttConnectionState.connected) {
        if (kDebugMode) print('MQTT Connected!');
        _isConnected = true;

        subscribe('room/R1/status');
        subscribe('room/R2/status');
        subscribe('room/R3/status');
        subscribe('room/streetlight/status');

        _client!.updates!.listen(
          (List<MqttReceivedMessage<MqttMessage>> c) {
            final recMessage = c[0].payload as MqttPublishMessage;
            final payload = MqttPublishPayload.bytesToStringAsString(
                recMessage.payload.message);

            try {
              final data = jsonDecode(payload) as Map<String, dynamic>;
              final topic = c[0].topic;
              final room = topic.split('/')[1];

              if (kDebugMode) print('MQTT: $topic => $data');

              for (final listener in _roomStatusListeners) {
                listener(room, data);
              }
            } catch (e) {
              if (kDebugMode) print('Parse error: $e');
            }
          },
          onError: (error) {
            if (kDebugMode) print('Stream error: $error');
          },
        );

        return true;
      } else {
        if (kDebugMode) {
          print('Connection failed: ${_client?.connectionStatus?.state}');
          print('Return code: ${_client?.connectionStatus?.returnCode}');
        }
        _isConnected = false;
        return false;
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('MQTT error: $e');
        print('Stack: $stack');
      }
      _isConnected = false;
      return false;
    }
  }

  static void subscribe(String topic) {
    if (_client == null || !_isConnected) {
      if (kDebugMode) print('Cannot subscribe: not connected');
      return;
    }
    _client!.subscribe(topic, MqttQos.atLeastOnce);
    if (kDebugMode) print('Subscribed: $topic');
  }

  static void publish(String room, String command) {
    if (_client == null || !_isConnected) {
      if (kDebugMode) print('Cannot publish: not connected');
      return;
    }

    final topic = 'room/$room/control';
    final builder = MqttClientPayloadBuilder();
    builder.addString(command);

    _client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    if (kDebugMode) print('Published: $topic => $command');
  }

  static void _onConnected() {
    _isConnected = true;
    if (kDebugMode) print('onConnected callback');
  }

  static void _onDisconnected() {
    _isConnected = false;
    if (kDebugMode) print('onDisconnected callback');
  }

  static void _onSubscribed(String topic) {
    if (kDebugMode) print('onSubscribed: $topic');
  }

  static void disconnect() {
    _client?.disconnect();
    _isConnected = false;
    if (kDebugMode) print('Disconnected');
  }

  static bool get isConnected => _isConnected;
}
