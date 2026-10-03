import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient buildMqttClient(String host, String clientId) {
  final client = MqttServerClient.withPort(host, clientId, 8883);
  client.secure = true;
  client.securityContext = SecurityContext.defaultContext;
  return client;
}

void configureWebProtocols(MqttClient client) {}
