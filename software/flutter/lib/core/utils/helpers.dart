import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  /// Format timestamp to readable string
  static String formatTimestamp(int timestamp) {
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return DateFormat('MMM dd, yyyy HH:mm').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Format duration from seconds
  static String formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${(seconds ~/ 60)}m';
    return '${(seconds ~/ 3600)}h ${((seconds % 3600) ~/ 60)}m';
  }

  /// Show snackbar message
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Get color from hex string
  static Color colorFromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}