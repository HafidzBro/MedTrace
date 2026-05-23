import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final _onReconnect = StreamController<void>.broadcast();

  Stream<void> get onReconnect => _onReconnect.stream;
  bool _wasOffline = false;

  void initialize() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final isOffline = _isOfflineResult(results);
      if (_wasOffline && !isOffline) {
        _onReconnect.add(null);
      }
      _wasOffline = isOffline;
    });
  }

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return !_isOfflineResult(results);
  }

  void dispose() {
    _subscription?.cancel();
    _onReconnect.close();
  }

  bool _isOfflineResult(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
  }
}
