import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class AreaStatus {
  final String name;
  final String ledState;
  final int currentMode;
  final bool isOccupied;
  final bool adminForced;
  final int pwmTarget;
  final int pwmCurrent;
  final String updatedAt;
  final int timestampEpoch;
  final String deviceId;
  final String firmware;

  AreaStatus({
    required this.name,
    required this.ledState,
    required this.currentMode,
    required this.isOccupied,
    required this.adminForced,
    required this.pwmTarget,
    required this.pwmCurrent,
    required this.updatedAt,
    required this.timestampEpoch,
    required this.deviceId,
    required this.firmware,
  });

  factory AreaStatus.fromJson(Map<dynamic, dynamic> json) {
    return AreaStatus(
      name: json['name']?.toString() ?? '',
      ledState: json['ledState']?.toString() ?? 'OFF',
      currentMode: json['currentMode'] ?? 0,
      isOccupied: json['isOccupied'] ?? false,
      adminForced: json['adminForced'] ?? false,
      pwmTarget: json['pwmTarget'] ?? 0,
      pwmCurrent: json['pwmCurrent'] ?? 0,
      updatedAt: json['updatedAt']?.toString() ?? '',
      timestampEpoch: json['timestampEpoch'] ?? 0,
      deviceId: json['deviceId']?.toString() ?? '',
      firmware: json['firmware']?.toString() ?? '',
    );
  }

  factory AreaStatus.empty(String areaName) {
    return AreaStatus(
      name: areaName,
      ledState: 'OFF',
      currentMode: 0,
      isOccupied: false,
      adminForced: false,
      pwmTarget: 0,
      pwmCurrent: 0,
      updatedAt: DateTime.now().toIso8601String(),
      timestampEpoch: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      deviceId: 'esp32-01',
      firmware: 'v1.1.1-fixed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ledState': ledState,
      'currentMode': currentMode,
      'isOccupied': isOccupied,
      'adminForced': adminForced,
      'pwmTarget': pwmTarget,
      'pwmCurrent': pwmCurrent,
      'updatedAt': updatedAt,
      'timestampEpoch': timestampEpoch,
      'deviceId': deviceId,
      'firmware': firmware,
    };
  }

  // ✅ ADDED: Getters for computed properties
  bool get isOn => ledState == 'ON';
  
  String get modeText => AppConstants.roomModes[currentMode] ?? 'Unknown';
  
  String get displayName {
    int index = AppConstants.roomNames.indexOf(name);
    if (index >= 0 && index < AppConstants.roomDisplayNames.length) {
      return AppConstants.roomDisplayNames[index];
    }
    return name;
  }
  
  Color get statusColor => AppTheme.getStatusColor(isOn, currentMode);
  
  Color get modeColor => AppTheme.getModeColor(currentMode);
  
  IconData get statusIcon {
    if (!isOn) return Icons.lightbulb_outline;
    return Icons.lightbulb;
  }
  
  IconData get modeIcon {
    switch (currentMode) {
      case 0: return Icons.auto_mode;
      case 1: return Icons.touch_app;
      case 2: return Icons.power_settings_new;
      case 3: return Icons.power_off;
      default: return Icons.help_outline;
    }
  }
  
  double get brightnessPercentage {
    if (pwmTarget == 0) return 0.0;
    return (pwmCurrent / 200.0) * 100.0;
  }
  
  // ✅ ADDED: Missing method lastUpdatedFormatted
  String get lastUpdatedFormatted {
    try {
      DateTime dateTime = DateTime.parse(updatedAt);
      DateTime now = DateTime.now();
      Duration difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  // Copy with method for updates
  AreaStatus copyWith({
    String? name,
    String? ledState,
    int? currentMode,
    bool? isOccupied,
    bool? adminForced,
    int? pwmTarget,
    int? pwmCurrent,
    String? updatedAt,
    int? timestampEpoch,
    String? deviceId,
    String? firmware,
  }) {
    return AreaStatus(
      name: name ?? this.name,
      ledState: ledState ?? this.ledState,
      currentMode: currentMode ?? this.currentMode,
      isOccupied: isOccupied ?? this.isOccupied,
      adminForced: adminForced ?? this.adminForced,
      pwmTarget: pwmTarget ?? this.pwmTarget,
      pwmCurrent: pwmCurrent ?? this.pwmCurrent,
      updatedAt: updatedAt ?? this.updatedAt,
      timestampEpoch: timestampEpoch ?? this.timestampEpoch,
      deviceId: deviceId ?? this.deviceId,
      firmware: firmware ?? this.firmware,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AreaStatus &&
        other.name == name &&
        other.ledState == ledState &&
        other.currentMode == currentMode &&
        other.isOccupied == isOccupied &&
        other.adminForced == adminForced &&
        other.timestampEpoch == timestampEpoch;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      ledState,
      currentMode,
      isOccupied,
      adminForced,
      timestampEpoch,
    );
  }

  @override
  String toString() {
    return 'AreaStatus(name: $name, ledState: $ledState, mode: $currentMode, occupied: $isOccupied)';
  }
}