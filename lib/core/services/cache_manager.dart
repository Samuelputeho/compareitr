import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class CacheManager {
  static final Map<String, dynamic> _cache = {};
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  static bool _isOnline = true;
  static ConnectivityResult _connectionType = ConnectivityResult.none;

  // Network state getters
  static bool get isOnline => _isOnline;
  static bool get isOffline => !_isOnline;
  static ConnectivityResult get connectionType => _connectionType;

  // Initialize network monitoring
  static Future<void> init() async {
    await _checkConnectivity();
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  static Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      print('🔍 Initial connectivity check: $result');
      _onConnectivityChanged(result);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
    }
  }

  static void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _connectionType = results.first;
    
    _isOnline = results.any((result) => 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet
    );

    if (wasOnline != _isOnline) {
      // Cache network state
      cache('network_status', _isOnline);
      cache('connection_type', _connectionType.toString());
      
      if (kDebugMode) {
        print('Network status changed: ${_isOnline ? 'Online' : 'Offline'}');
      }
    }
  }

  // Cache method
  static void cache(String key, dynamic value) {
    _cache[key] = value;
  }

  // Retrieve from cache
  static dynamic getCache(String key) {
    return _cache[key];
  }

  // Clear a specific cache item
  static void clearCache(String key) {
    _cache.remove(key);
  }

  // Clear all cache
  static void clearAllCache() {
    _cache.clear();
  }

  // Get network status text
  static String get connectionStatusText {
    if (_isOnline) {
      switch (_connectionType) {
        case ConnectivityResult.wifi:
          return 'Connected via WiFi';
        case ConnectivityResult.mobile:
          return 'Connected via Mobile';
        case ConnectivityResult.ethernet:
          return 'Connected via Ethernet';
        default:
          return 'Connected';
      }
    } else {
      return 'Offline';
    }
  }

  // Dispose network monitoring
  static void dispose() {
    _connectivitySubscription?.cancel();
  }
}




