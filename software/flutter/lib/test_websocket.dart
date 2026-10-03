import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TestWebSocket extends StatefulWidget {
  @override
  _TestWebSocketState createState() => _TestWebSocketState();
}

class _TestWebSocketState extends State<TestWebSocket> {
  String _status = 'Ready to test';
  io.WebSocket? _ws;

  Future<void> _testConnection() async {
    if (kIsWeb) {
      setState(() => _status = 'Web platform: gunakan browser DevTools untuk test WebSocket.');
      return;
    }
    setState(() => _status = 'Connecting...');
    try {
      _ws = await io.WebSocket.connect(
        'wss://5bfa9f7980ac429fb1cfa0433d7bcc07.s1.eu.hivemq.cloud:8884/mqtt',
        protocols: ['mqtt'],
      );
      setState(() => _status = 'CONNECTED!\n\nWebSocket berhasil!\nProblem di MQTT library.');
      if (kDebugMode) print('WebSocket OPEN');
      _ws!.listen(
        (data) => print('WS data: $data'),
        onError: (e) {
          if (kDebugMode) print('WebSocket ERROR: $e');
          setState(() => _status = 'ERROR\n\n$e');
        },
        onDone: () {
          if (kDebugMode) print('WebSocket CLOSED: ${_ws?.closeCode}');
          setState(() => _status += '\n\nClosed: ${_ws?.closeCode}');
        },
      );
      await Future.delayed(const Duration(seconds: 2));
      await _ws?.close();
    } catch (e) {
      if (kDebugMode) print('Exception: $e');
      setState(() => _status = 'EXCEPTION\n\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Debug'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _status.contains('CONNECTED') ? Icons.check_circle :
                _status.contains('ERROR') || _status.contains('EXCEPTION') ? Icons.error :
                Icons.network_check,
                size: 80,
                color: _status.contains('CONNECTED') ? Colors.green :
                       _status.contains('ERROR') || _status.contains('EXCEPTION') ? Colors.red :
                       Colors.blue,
              ),
              const SizedBox(height: 30),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, height: 1.5),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _testConnection,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: const Text(
                  'Test Connection',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Testing: wss://...hivemq.cloud:8884/mqtt',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ws?.close();
    super.dispose();
  }
}
