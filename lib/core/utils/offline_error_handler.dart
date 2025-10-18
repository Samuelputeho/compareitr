import 'package:flutter/material.dart';
import 'package:compareitr/core/common/cache/cache.dart';
import 'package:compareitr/core/error/failures.dart';

class OfflineErrorHandler {
  // Check if error should be shown based on network status
  static bool shouldShowError(Failure failure) {
    // If offline, don't show server errors - show offline message instead
    if (CacheManager.isOffline) {
      return false; // Don't show server errors when offline
    }
    return true; // Show errors when online
  }

  // Get user-friendly error message based on network status
  static String getErrorMessage(Failure failure) {
    if (CacheManager.isOffline) {
      return 'You\'re offline. Some features may not work properly.';
    }
    return failure.message;
  }

  // Show offline-aware error dialog
  static void showErrorDialog(BuildContext context, Failure failure) {
    if (!shouldShowError(failure)) {
      return; // Don't show error dialogs when offline
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(getErrorMessage(failure)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show offline-aware snackbar
  static void showErrorSnackBar(BuildContext context, Failure failure) {
    if (!shouldShowError(failure)) {
      return; // Don't show error snackbars when offline
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(getErrorMessage(failure)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show offline status snackbar
  static void showOfflineSnackBar(BuildContext context) {
    if (!CacheManager.isOffline) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('You\'re offline - Using cached data'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

