import 'package:flutter/foundation.dart';
import '../../core/services/mqtt_service.dart';
import '../../core/services/firebase_service.dart';
import '../models/room_model.dart';

class AreaProvider extends ChangeNotifier {
  List<AreaStatus> _areas = [];
  bool _isLoading = true;
  String?  _errorMessage;

  List<AreaStatus> get areas => _areas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  int get totalAreas => _areas.length;
  int get onlineAreas => _areas.where((a) => a.isOn).length;  // ✅ isOn dari getter model
  int get offlineAreas => _areas.where((a) => !a.isOn).length;
  
  AreaStatus? getAreaById(String areaId) {
    try {
      return _areas.firstWhere((area) => area.name == areaId);
    } catch (e) {
      return null;
    }
  }

  Future<void> initialize() async {
    if (kDebugMode) print('🔌 [AreaProvider] Initializing MQTT.. .');
    
    final success = await MqttService.connect();
    
    if (success) {
      if (kDebugMode) print('[AreaProvider] MQTT connected');

      MqttService.addRoomStatusListener(_handleRoomStatus);
      
      _areas = ['R1', 'R2', 'R3'].map((id) => AreaStatus.empty(id)).toList();
      _isLoading = false;
      notifyListeners();
    } else {
      if (kDebugMode) print('❌ [AreaProvider] MQTT connection failed');
      _errorMessage = 'Failed to connect MQTT';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void _handleRoomStatus(String room, Map<String, dynamic> status) {
    if (kDebugMode) print('📥 [AreaProvider] Update from $room:  $status');
    
    final index = _areas.indexWhere((a) => a.name == room);
    if (index == -1) return;
    
    // ✅ Mapping MQTT → AreaStatus
    _areas[index] = AreaStatus(
      name: room,
      ledState: status['state'] ?? 'OFF',
      currentMode: status['mode'] ?? 0,
      isOccupied: status['occupied'] ??  false,
      adminForced: status['forced'] ?? false,
      pwmTarget: 0,
      pwmCurrent: 0,
      updatedAt: DateTime.now().toIso8601String(),
      timestampEpoch: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      deviceId: 'esp32-01',
      firmware: 'v2.0-mqtt',
    );
    
    notifyListeners();
  }
  
  Future<bool> setAreaOutput(String areaId, String output) async {
    if (kDebugMode) print('📤 [AreaProvider] setAreaOutput:   $areaId → $output');
    
    MqttService.publish(areaId, output);
    FirebaseService.setAreaOutputRequest(areaId, output);
    
    return true;
  }
  
  Future<bool> setAreaMode(String areaId, int mode) async {
    if (kDebugMode) print('📤 [AreaProvider] setAreaMode:  $areaId → $mode');
    
    final command = ['AUTO', 'MANUAL', 'ON', 'OFF'][mode];
    MqttService.publish(areaId, command);
    FirebaseService.setAreaModeRequest(areaId, mode);
    
    return true;
  }
  
  Future<bool> emergencyStopAll() async {
    if (kDebugMode) print('🚨 [AreaProvider] Emergency stop all');
    
    for (var area in _areas) {
      MqttService.publish(area.name, 'OFF');
    }
    FirebaseService.emergencyStopAll();
    
    return true;
  }
  
  Future<void> refresh() async {
    if (kDebugMode) print('↻ [AreaProvider] Refresh');
    
    _isLoading = true;
    notifyListeners();
    
    await MqttService.connect();
    MqttService.addRoomStatusListener(_handleRoomStatus);
    
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
  
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  @override
  void dispose() {
    MqttService.removeRoomStatusListener(_handleRoomStatus);
    MqttService.disconnect();
    super.dispose();
  }
}