import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Production-grade Connectivity Service that listens to real-time hardware
/// connectivity changes and verifies WAN internet reachability via socket lookup.
class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = true;
  bool _isChecking = false;
  ConnectivityResult _connectionType = ConnectivityResult.none;

  bool get isConnected => _isConnected;
  bool get isChecking => _isChecking;
  ConnectivityResult get connectionType => _connectionType;

  final StreamController<bool> _connectivityStreamController =
      StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _connectivityStreamController.stream;

  ConnectivityService() {
    _initConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _handleConnectivityChange(results);
    } catch (e) {
      debugPrint('ConnectivityService init error: $e');
    }
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    _isChecking = true;
    notifyListeners();

    final hasHardwareConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!hasHardwareConnection) {
      _setConnectivityStatus(false, ConnectivityResult.none);
      return;
    }

    _connectionType = results.firstWhere(
      (result) => result != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );

    // Active WAN Internet Reachability Ping
    final hasInternet = await _checkWanInternetReachability();
    _setConnectivityStatus(hasInternet, _connectionType);
  }

  Future<bool> _checkWanInternetReachability() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 4),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _setConnectivityStatus(bool connected, ConnectivityResult type) {
    final statusChanged = _isConnected != connected;
    _isConnected = connected;
    _connectionType = type;
    _isChecking = false;

    notifyListeners();

    if (statusChanged) {
      _connectivityStreamController.add(connected);
    }
  }

  /// Manually force a connection re-check.
  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    await _handleConnectivityChange(results);
    return _isConnected;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _connectivityStreamController.close();
    super.dispose();
  }
}
