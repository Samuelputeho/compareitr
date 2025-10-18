import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkStateManager extends ChangeNotifier {
  static final NetworkStateManager _instance = NetworkStateManager._internal();
  factory NetworkStateManager() => _instance;
  NetworkStateManager._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  ConnectivityResult _connectionType = ConnectivityResult.none;

  bool get isOnline => _isOnline;
  ConnectivityResult get connectionType => _connectionType;
  bool get isOffline => !_isOnline;

  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();
    
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _onConnectivityChanged(result);
    } catch (e) {
      if (kDebugMode) {
        print('Error checking connectivity: $e');
      }
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _connectionType = results.first;
    
    // Consider online if we have any connection (wifi, mobile, ethernet)
    _isOnline = results.any((result) => 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.mobile ||
      result == ConnectivityResult.ethernet
    );

    // Only notify if status changed
    if (wasOnline != _isOnline) {
      notifyListeners();
      if (kDebugMode) {
        print('Network status changed: ${_isOnline ? 'Online' : 'Offline'}');
      }
    }
  }

  String get connectionStatusText {
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

  String get connectionTypeText {
    switch (_connectionType) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      default:
        return 'No Connection';
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}





