import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class StreetlightStatus {
  final String name;
  final String ledState;
  final int currentMode;
  final bool adminForced;
  final int pwmTarget;
  final int pwmCurrent;
  final String updatedAt;
  final int timestampEpoch;

  StreetlightStatus({
    required this.name,
    required this.ledState,
    required this.currentMode,
    required this.adminForced,
    required this.pwmTarget,
    required this.pwmCurrent,
    required this.updatedAt,
    required this.timestampEpoch,
  });

  factory StreetlightStatus.fromJson(Map<dynamic, dynamic> json) {
    return StreetlightStatus(
      name: json['name']?.toString() ?? 'Main Lighting',
      ledState: json['ledState']?.toString() ?? 'OFF',
      currentMode: json['currentMode'] ?? 1,
      adminForced: json['adminForced'] ?? false,
      pwmTarget: json['pwmTarget'] ?? 0,
      pwmCurrent: json['pwmCurrent'] ?? 0,
      updatedAt: json['updatedAt']?.toString() ?? '',
      timestampEpoch: json['timestampEpoch'] ?? 0,
    );
  }

  factory StreetlightStatus.empty() {
    return StreetlightStatus(
      name: 'Main Lighting',
      ledState: 'OFF',
      currentMode: 1,
      adminForced: false,
      pwmTarget: 0,
      pwmCurrent: 0,
      updatedAt: DateTime.now().toIso8601String(),
      timestampEpoch: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ledState': ledState,
      'currentMode': currentMode,
      'adminForced': adminForced,
      'pwmTarget': pwmTarget,
      'pwmCurrent': pwmCurrent,
      'updatedAt': updatedAt,
      'timestampEpoch': timestampEpoch,
    };
  }

  // Getters
  bool get isOn => ledState == 'ON';
  String get modeText => AppConstants.streetModes[currentMode] ?? 'Unknown';
  Color get statusColor => AppTheme.getStatusColor(isOn, currentMode);
  Color get modeColor => AppTheme.getModeColor(currentMode);
  
  IconData get statusIcon {
    if (!isOn) return Icons.lightbulb_outline;
    return Icons.lightbulb;
  }
  
  IconData get modeIcon {
    switch (currentMode) {
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
      return 'Unknown';
    }
  }

  StreetlightStatus copyWith({
    String? name,
    String? ledState,
    int? currentMode,
    bool? adminForced,
    int? pwmTarget,
    int? pwmCurrent,
    String? updatedAt,
    int? timestampEpoch,
  }) {
    return StreetlightStatus(
      name: name ?? this.name,
      ledState: ledState ?? this.ledState,
      currentMode: currentMode ?? this.currentMode,
      adminForced: adminForced ?? this.adminForced,
      pwmTarget: pwmTarget ?? this.pwmTarget,
      pwmCurrent: pwmCurrent ?? this.pwmCurrent,
      updatedAt: updatedAt ?? this.updatedAt,
      timestampEpoch: timestampEpoch ?? this.timestampEpoch,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreetlightStatus &&
        other.name == name &&
        other.ledState == ledState &&
        other.currentMode == currentMode &&
        other.adminForced == adminForced &&
        other.timestampEpoch == timestampEpoch;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      ledState,
      currentMode,
      adminForced,
      timestampEpoch,
    );
  }

  @override
  String toString() {
    return 'StreetlightStatus(name: $name, ledState: $ledState, mode: $currentMode)';
  }
}