import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';

MqttClient buildMqttClient(String host, String clientId) {
  final wsUrl = 'wss://$host:8884/mqtt';
  return MqttBrowserClient(wsUrl, clientId);
}

void configureWebProtocols(MqttClient client) {
  (client as MqttBrowserClient).websocketProtocols =
      MqttClientConstants.protocolsMultipleDefault;
}
