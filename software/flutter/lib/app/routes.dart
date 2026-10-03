import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/room_control/room_control_screen.dart';
import '../features/history/history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/notifications/notifications_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppConstants.routeDashboard: (context) => const DashboardScreen(),
      AppConstants.routeRoomControl: (context) => const RoomControlScreen(),
      AppConstants.routeHistory: (context) => const HistoryScreen(),
      AppConstants.routeSettings: (context) => const SettingsScreen(),
      AppConstants.routeNotifications: (context) => const NotificationsScreen(),
    };
  }
}