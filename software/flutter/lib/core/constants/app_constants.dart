class AppConstants {
  // App Info - ✅ UPDATED TO CLASSROOM
  static const String appName = 'Smart Classroom';
  static const String appVersion = '1.0.0';
  
  // Firebase Paths - ✅ KEEP SAME (ESP32 masih menggunakan Smart_room_iot)
  static const String deviceName = 'Smart_room_iot'; // KEEP - ESP32 config
  static const String devicesPath = '/devices';
  static const String currentStatusPath = '/current_status';
  static const String controlsPath = '/controls';
  static const String historyPath = '/history';
  static const String streetlightPath = '/streetlight';
  
  // Room Configuration - ✅ UPDATED TO CLASSROOM CONTEXT
  static const List<String> roomNames = ['R1', 'R2', 'R3'];
  static const List<String> roomDisplayNames = [
    'Classroom 1',      // ✅ UPDATED - Area Depan
    'Classroom 2',     // ✅ UPDATED - Area Tengah  
    'Classroom 3'       // ✅ UPDATED - Area Belakang
  ];
  
  // Room Modes - ✅ KEEP SAME
  static const Map<int, String> roomModes = {
    0: 'Auto',
    1: 'Manual', 
    2: 'Force ON',
    3: 'Force OFF',
  };
  
  // Streetlight Modes - ✅ UPDATED TO CLASSROOM CONTEXT
  static const Map<int, String> streetModes = {
    1: 'Manual',
    2: 'Always ON',     // ✅ UPDATED - Selalu Nyala
    3: 'Always OFF',    // ✅ UPDATED - Selalu Mati
  };
  
  // Colors for Modes - ✅ KEEP SAME
  static const Map<int, String> modeColors = {
    0: '#2196F3', // Blue for Auto
    1: '#FF9800', // Orange for Manual
    2: '#4CAF50', // Green for Force ON
    3: '#F44336', // Red for Force OFF
  };
  
  // Refresh Intervals - ✅ KEEP SAME
  static const int defaultRefreshInterval = 5; // seconds
  static const int minRefreshInterval = 2;
  static const int maxRefreshInterval = 30;
  
  // Notification Settings - ✅ UPDATED
  static const String notificationChannelId = 'smart_classroom_notifications';
  static const String notificationChannelName = 'Smart Classroom Alerts';
  
  // SharedPreferences Keys - ✅ KEEP SAME
  static const String keyFirstLaunch = 'first_launch';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyAutoRefresh = 'auto_refresh';
  static const String keyRefreshInterval = 'refresh_interval';
  static const String keyDarkMode = 'dark_mode';
  static const String keyLastConnectionCheck = 'last_connection_check';
  
  // Routes - ✅ KEEP SAME
  static const String routeSplash = '/';
  static const String routeDashboard = '/dashboard';
  static const String routeRoomControl = '/room-control';
  static const String routeHistory = '/history';
  static const String routeSettings = '/settings';
  static const String routeNotifications = '/notifications';
}