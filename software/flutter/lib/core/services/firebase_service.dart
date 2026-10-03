import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/room_model.dart';
import '../../shared/models/streetlight_model.dart';
import '../constants/app_constants.dart';
import 'dart:async';

class FirebaseService {
  static FirebaseDatabase?  _databaseInstance;
  static const String _devicePath = '${AppConstants.devicesPath}/${AppConstants.deviceName}';

  static FirebaseDatabase get _database {
    if (_databaseInstance == null) {
      _databaseInstance = FirebaseDatabase.instance;
    }
    return _databaseInstance!;
  }

  static Future<void> debugProbeStatusNodes() async {
    final String roomsPath = '$_devicePath${AppConstants.currentStatusPath}/rooms';
    final String streetlightPath = '$_devicePath${AppConstants.streetlightPath}/current_status';

    try {
      final roomsSnap = await _database.ref(roomsPath).get();
      debugPrint('🔎 [Probe] rooms exists=${roomsSnap.exists} path=$roomsPath');
      if (roomsSnap.exists) {
        debugPrint('🔎 [Probe] rooms raw type=${roomsSnap.value.runtimeType}');
        debugPrint('🔎 [Probe] rooms value=${roomsSnap.value}');
      } else {
        debugPrint('⚠️ [Probe] rooms node not found at $roomsPath');
      }
    } catch (e) {
      debugPrint('❌ [Probe] rooms get() error: $e');
    }

    try {
      final streetSnap = await _database.ref(streetlightPath).get();
      debugPrint('🔎 [Probe] streetlight exists=${streetSnap.exists} path=$streetlightPath');
      if (streetSnap.exists) {
        debugPrint('🔎 [Probe] streetlight raw type=${streetSnap.value.runtimeType}');
        debugPrint('🔎 [Probe] streetlight value=${streetSnap.value}');
      } else {
        debugPrint('⚠️ [Probe] streetlight node not found at $streetlightPath');
      }
    } catch (e) {
      debugPrint('❌ [Probe] streetlight get() error: $e');
    }
  }

  static Future<void> ensureInitialized() async {
    if (Firebase.apps.isEmpty) {
      if (kDebugMode) debugPrint('⚠️ Firebase not initialized — call Firebase.initializeApp() with options first.');
    } else {
      if (kDebugMode) debugPrint('Firebase already initialized (${Firebase.apps.length} app(s)).');
    }
  }

  // ===========================
  // STREAM:  ROOMS (AREAS)
  // ===========================
  static Stream<List<AreaStatus>> getAllAreasStatusStream() {
    final String refPath = '$_devicePath${AppConstants.currentStatusPath}/rooms';
    if (kDebugMode) debugPrint('🔗 [Areas] subscribing to RTDB path: $refPath');

    final Stream<DatabaseEvent> raw = _database.ref(refPath).onValue;

    final Stream<List<AreaStatus>> instrumented = raw.transform(
      StreamTransformer<DatabaseEvent, List<AreaStatus>>.fromHandlers(
        handleData: (event, sink) {
          try {
            final snapshot = event.snapshot;
            if (kDebugMode) {
              debugPrint('✅ [Areas] onData:  exists=${snapshot.exists} key=${snapshot.key}');
            }

            final List<AreaStatus> areas = <AreaStatus>[];

            if (snapshot.value != null) {
              final Map<dynamic, dynamic> data = snapshot.value as Map;

              for (final String areaId in AppConstants.roomNames) {
                if (data.containsKey(areaId) && data[areaId] is Map) {
                  areas.add(
                    AreaStatus.fromJson(Map<String, dynamic>.from(data[areaId] as Map)),
                  );
                } else {
                  areas.add(AreaStatus.empty(areaId));
                }
              }
            } else {
              for (final String areaId in AppConstants.roomNames) {
                areas.add(AreaStatus.empty(areaId));
              }
            }

            sink.add(areas);
          } catch (e, st) {
            if (kDebugMode) debugPrint('❌ [Areas] parse error: $e\n$st');
            sink.addError(e, st);
          }
        },
        handleError: (error, stack, sink) {
          if (kDebugMode) debugPrint('❌ [Areas] stream error: $error');
          sink.addError(error, stack);
        },
        handleDone: (sink) {
          if (kDebugMode) debugPrint('ℹ️ [Areas] stream done');
          sink.close();
        },
      ),
    ).timeout(
      const Duration(seconds: 12),
      onTimeout: (sink) {
        final error = TimeoutException('Areas stream timeout (12s) – no events');
        if (kDebugMode) debugPrint('⏰ [Areas] timeout: $error');
        sink.addError(error);
      },
    ).handleError((error) {
      if (kDebugMode) debugPrint('⚠️ [Areas] handleError fallback -> returning empty list');
      return <AreaStatus>[];
    });

    return instrumented;
  }

  // ===========================
  // STREAM: STREETLIGHT (MAIN)
  // ===========================
  static Stream<StreetlightStatus> getStreetlightStatusStream() {
    final String refPath = '$_devicePath${AppConstants.streetlightPath}/current_status';
    if (kDebugMode) debugPrint('🔗 [Streetlight] subscribing to RTDB path: $refPath');

    final Stream<DatabaseEvent> raw = _database.ref(refPath).onValue;

    final Stream<StreetlightStatus> instrumented = raw.transform(
      StreamTransformer<DatabaseEvent, StreetlightStatus>.fromHandlers(
        handleData: (event, sink) {
          try {
            final snapshot = event.snapshot;
            if (kDebugMode) {
              debugPrint('✅ [Streetlight] onData: exists=${snapshot.exists} key=${snapshot.key}');
            }

            if (snapshot.value != null && snapshot.value is Map) {
              final Map<String, dynamic> json =
                  Map<String, dynamic>.from(snapshot.value as Map);
              sink.add(StreetlightStatus.fromJson(json));
            } else {
              sink.add(StreetlightStatus.empty());
            }
          } catch (e, st) {
            if (kDebugMode) debugPrint('❌ [Streetlight] parse error:  $e\n$st');
            sink.addError(e, st);
          }
        },
        handleError: (error, stack, sink) {
          if (kDebugMode) debugPrint('❌ [Streetlight] stream error: $error');
          sink.addError(error, stack);
        },
        handleDone: (sink) {
          if (kDebugMode) debugPrint('ℹ️ [Streetlight] stream done');
          sink.close();
        },
      ),
    ).timeout(
      const Duration(seconds: 12),
      onTimeout: (sink) {
        final error = TimeoutException('Streetlight stream timeout (12s) – no events');
        if (kDebugMode) debugPrint('⏰ [Streetlight] timeout: $error');
        sink.addError(error);
      },
    ).handleError((error) {
      if (kDebugMode) debugPrint('⚠️ [Streetlight] handleError fallback -> returning empty status');
      return StreetlightStatus.empty();
    });

    return instrumented;
  }

  // ===========================
  // CONTROLS
  // ===========================
  static Future<bool> setAreaModeRequest(String areaId, int mode) async {
    try {
      if (mode < 0 || mode > 3) {
        throw ArgumentError('Invalid area mode: $mode.  Must be 0-3.');
      }

      final String path = '$_devicePath${AppConstants.controlsPath}/rooms/$areaId/requestedMode';
      await _database.ref(path).set(mode);

      if (kDebugMode) debugPrint('✅ Area $areaId mode request sent:  $mode (path: $path)');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error setting area mode: $e');
      return false;
    }
  }

  static Future<bool> setAreaOutputRequest(String areaId, String output) async {
    try {
      if (output != 'ON' && output != 'OFF') {
        throw ArgumentError('Invalid output:  $output. Must be "ON" or "OFF".');
      }

      final String path = '$_devicePath${AppConstants.controlsPath}/rooms/$areaId/requestedOutput';
      await _database.ref(path).set(output);

      if (kDebugMode) debugPrint('✅ Area $areaId output request sent: $output (path: $path)');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error setting area output: $e');
      return false;
    }
  }

  static Future<bool> setStreetlightModeRequest(int mode) async {
    try {
      if (mode < 1 || mode > 3) {
        throw ArgumentError('Invalid streetlight mode: $mode. Must be 1-3.');
      }

      final String path = '$_devicePath${AppConstants.controlsPath}/streetlight/requestedMode';
      await _database.ref(path).set(mode);

      if (kDebugMode) debugPrint('✅ Streetlight mode request sent: $mode (path: $path)');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error setting streetlight mode: $e');
      return false;
    }
  }

  static Future<bool> setStreetlightOutputRequest(String output) async {
    try {
      if (output != 'ON' && output != 'OFF') {
        throw ArgumentError('Invalid output: $output. Must be "ON" or "OFF".');
      }

      final String path = '$_devicePath${AppConstants.controlsPath}/streetlight/requestedOutput';
      await _database.ref(path).set(output);

      if (kDebugMode) debugPrint('✅ Streetlight output request sent: $output (path: $path)');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error setting streetlight output:  $e');
      return false;
    }
  }

  static Future<bool> emergencyStopAll() async {
    try {
      final Map<String, Object> updates = {};

      for (final String areaId in AppConstants.roomNames) {
        updates['$_devicePath${AppConstants.controlsPath}/rooms/$areaId/requestedMode'] = 3;
      }
      updates['$_devicePath${AppConstants.controlsPath}/streetlight/requestedMode'] = 3;

      await _database.ref().update(updates);
      if (kDebugMode) debugPrint('🚨 Emergency stop executed - all devices set to OFF');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error in emergency stop: $e');
      return false;
    }
  }

  // ===========================
  // HISTORY
  // ===========================
  static Future<List<Map<String, dynamic>>> getClassroomHistory({
    String? areaId,
    int limit = 100,
  }) async {
    try {
      final String historyPath = '$_devicePath${AppConstants.historyPath}';
      Query query = _database.ref(historyPath);
      query = query.orderByChild('timestampEpoch').limitToLast(limit);

      final DataSnapshot snapshot = await query.get();
      final List<Map<String, dynamic>> history = [];

      if (snapshot.exists && snapshot.value is Map) {
        final Map<dynamic, dynamic> data = snapshot.value as Map;
        data.forEach((key, value) {
          try {
            final Map<String, dynamic> event = Map<String, dynamic>.from(value as Map);

            if (areaId == null ||
                event['room'] == areaId ||
                (areaId == 'Streetlight' && event['type'] == 'street_event')) {
              event['key'] = key;
              history. add(event);
            }
          } catch (e) {
            if (kDebugMode) debugPrint('⚠️ Skipping malformed history entry: $e');
          }
        });

          history.sort((a, b) => (b['timestampEpoch'] ?? 0).compareTo(a['timestampEpoch'] ?? 0));
        if (kDebugMode) debugPrint('✅ Loaded ${history.length} history entries from $historyPath');
      } else {
        if (kDebugMode) {
          debugPrint('ℹ️ History snapshot empty at path $historyPath (exists=${snapshot.exists})');
        }
      }

      return history;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting classroom history: $e');
      return [];
    }
  }

  static Future<bool> testConnection() async {
    try {
      final snapshot = await _database.ref(_devicePath).get();
      if (kDebugMode) debugPrint('✅ Firebase connection test successful, exists=${snapshot.exists}');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Firebase connection test failed: $e');
      return false;
    }
  }
}