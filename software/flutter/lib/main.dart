import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/services/firebase_service.dart';
import 'app/app.dart';  // ✅ RESTORED

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
    // Ensure Firebase Service ready
    await FirebaseService.ensureInitialized();
    
    // Debug probe (optional)
    if (kDebugMode) {
      print('🔎 Running Firebase probe...');
      await FirebaseService.debugProbeStatusNodes();
    }
    
    // Initialize Notifications (mobile only)
    if (!kIsWeb) {
      await NotificationService.initialize();
      print('✅ Notifications initialized successfully');
    } else {
      print('ℹ️ Notifications skipped for web platform');
    }
    
  } catch (e, stackTrace) {
    print('❌ Initialization error: $e');
    if (kDebugMode) {
      print('Stack trace:  $stackTrace');
    }
  }
  
  // ✅ RESTORED TO PRODUCTION:
  runApp(const SmartClassroomApp());
}