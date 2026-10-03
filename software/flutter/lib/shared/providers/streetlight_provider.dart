import 'package:flutter/foundation.dart';
import '../../core/services/mqtt_service.dart';
import '../../core/services/firebase_service.dart';
import '../models/streetlight_model.dart';

class StreetlightProvider extends ChangeNotifier {
  StreetlightStatus _streetlight = StreetlightStatus.empty();
  bool _isLoading = true;
  String? _errorMessage;

  StreetlightStatus get streetlight => _streetlight;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (kDebugMode) print('🔌 [StreetlightProvider] Initializing.. .');
    
    final success = await MqttService.connect();
    
    if (success) {
      MqttService.addRoomStatusListener(_handleStatus);
      
      _streetlight = StreetlightStatus.empty();
      _isLoading = false;
      notifyListeners();
    } else {
      _errorMessage = 'Failed to connect MQTT';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _handleStatus(String room, Map<String, dynamic> status) {
    if (room != 'streetlight') return;
    
    if (kDebugMode) print('📥 [StreetlightProvider] Update:  $status');
    
    // ✅ MAPPING MQTT payload → StreetlightStatus model
    _streetlight = StreetlightStatus(
      name: 'Streetlight',
      ledState:  status['state'] ?? 'OFF',  // MQTT: "state" → Model: "ledState"
      currentMode: status['mode'] ?? 1,
      adminForced: status['forced'] ??  false,
      pwmTarget:  0,
      pwmCurrent: 0,
      updatedAt: DateTime.now().toIso8601String(),
      timestampEpoch: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    
    notifyListeners();
  }
  
  Future<bool> setOutput(String output) async {
    if (kDebugMode) print('📤 [StreetlightProvider] setOutput: $output');
    
    MqttService.publish('streetlight', output);
    FirebaseService.setStreetlightOutputRequest(output);
    
    return true;
  }
  
  Future<bool> setMode(int mode) async {
    if (kDebugMode) print('📤 [StreetlightProvider] setMode: $mode');
    
    final command = mode == 1 ? 'MANUAL' : (mode == 2 ? 'ON' : 'OFF');
    MqttService.publish('streetlight', command);
    FirebaseService.setStreetlightModeRequest(mode);
    
    return true;
  }
  
  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    
    await MqttService.connect();
    MqttService.addRoomStatusListener(_handleStatus);
    
    _isLoading = false;
    notifyListeners();
  }
  
  @override
  void dispose() {
    MqttService.removeRoomStatusListener(_handleStatus);
    super.dispose();
  }
}