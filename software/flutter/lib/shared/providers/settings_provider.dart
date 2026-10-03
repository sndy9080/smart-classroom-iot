import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _autoRefresh = true;
  int _refreshInterval = AppConstants.defaultRefreshInterval;
  bool _isInitialized = false;

  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoRefresh => _autoRefresh;
  int get refreshInterval => _refreshInterval;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isDarkMode = prefs.getBool(AppConstants.keyDarkMode) ?? false;
      _notificationsEnabled = prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
      _autoRefresh = prefs.getBool(AppConstants.keyAutoRefresh) ?? true;
      _refreshInterval = prefs.getInt(AppConstants.keyRefreshInterval) ?? AppConstants.defaultRefreshInterval;
      
      _isInitialized = true;
      notifyListeners();
      
      print('✅ Settings loaded successfully');
    } catch (e) {
      print('❌ Error loading settings: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool value) async {
    try {
      _isDarkMode = value;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyDarkMode, value);
    } catch (e) {
      print('❌ Error saving dark mode: $e');
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    try {
      _notificationsEnabled = value;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyNotificationsEnabled, value);
    } catch (e) {
      print('❌ Error saving notifications setting: $e');
    }
  }

  Future<void> setAutoRefresh(bool value) async {
    try {
      _autoRefresh = value;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyAutoRefresh, value);
    } catch (e) {
      print('❌ Error saving auto refresh: $e');
    }
  }

  Future<void> setRefreshInterval(int value) async {
    try {
      if (value >= AppConstants.minRefreshInterval && 
          value <= AppConstants.maxRefreshInterval) {
        _refreshInterval = value;
        notifyListeners();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(AppConstants.keyRefreshInterval, value);
      }
    } catch (e) {
      print('❌ Error saving refresh interval: $e');
    }
  }

  Future<void> resetToDefaults() async {
    try {
      _isDarkMode = false;
      _notificationsEnabled = true;
      _autoRefresh = true;
      _refreshInterval = AppConstants.defaultRefreshInterval;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('❌ Error resetting settings: $e');
    }
  }
}