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
      final isOffline = results.contains(ConnectivityResult.none);
      if (_wasOffline && !isOffline) {
        _onReconnect.add(null);
      }
      _wasOffline = isOffline;
    });
  }

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
    _onReconnect.close();
  }
}
