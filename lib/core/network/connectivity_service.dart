import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/app_logger.dart';

/// Connectivity states for the application
enum ConnectivityStatus {
  /// Connected to WiFi network
  wifi,

  /// Connected to mobile network
  mobile,

  /// No internet connection
  offline,
}

/// Service for monitoring network connectivity
class ConnectivityService {
  final AppLogger _logger;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<ConnectivityResult>? _subscription;
  final StateNotifier<ConnectivityStatus> _statusNotifier;

  /// Creates a new instance of [ConnectivityService]
  ConnectivityService({required AppLogger logger})
      : _logger = logger,
        _statusNotifier =
            ConnectivityStatusNotifier(ConnectivityStatus.offline);

  /// Current connectivity status
  ConnectivityStatus get status => _statusNotifier.state;

  /// Stream of connectivity status changes
  StateNotifierProvider<StateNotifier<ConnectivityStatus>, ConnectivityStatus>
      get statusProvider => StateNotifierProvider<
          StateNotifier<ConnectivityStatus>,
          ConnectivityStatus>((ref) => _statusNotifier);

  /// Initialize the connectivity service
  Future<void> initialize() async {
    _logger.i('ConnectivityService: Initializing...');

    // Get initial connectivity status
    final initialResult = await _connectivity.checkConnectivity();
    _updateStatus(initialResult);

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);

    _logger.i(
        'ConnectivityService: Initialized with status ${_statusNotifier.state}');
  }

  /// Updates the connectivity status based on the connectivity result
  void _updateStatus(ConnectivityResult result) {
    final newStatus = switch (result) {
      ConnectivityResult.wifi => ConnectivityStatus.wifi,
      ConnectivityResult.mobile => ConnectivityStatus.mobile,
      _ => ConnectivityStatus.offline,
    };

    if (newStatus != _statusNotifier.state) {
      _logger.i(
          'ConnectivityService: Status changed from ${_statusNotifier.state} to $newStatus');
      _statusNotifier.state = newStatus;
    }
  }

  /// Dispose of resources
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _logger.i('ConnectivityService: Disposed');
  }

  /// Check if the device is currently connected to the internet
  bool get isConnected => _statusNotifier.state != ConnectivityStatus.offline;

  /// Check if the device is connected to a WiFi network
  bool get isWifi => _statusNotifier.state == ConnectivityStatus.wifi;

  /// Check if the device is connected to a mobile network
  bool get isMobile => _statusNotifier.state == ConnectivityStatus.mobile;
}

class ConnectivityStatusNotifier extends StateNotifier<ConnectivityStatus> {
  ConnectivityStatusNotifier(super.state);
}
