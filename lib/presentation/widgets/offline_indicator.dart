import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:medtrace/services/connectivity_service.dart';

class OfflineIndicator extends StatefulWidget {
  final Widget child;
  const OfflineIndicator({required this.child, super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOffline = false;
  StreamSubscription<ConnectivityResult>? _sub;

  @override
  void initState() {
    super.initState();
    _loadInitialStatus();
    _sub = Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      setState(() => _isOffline = result == ConnectivityResult.none);
    });
  }

  Future<void> _loadInitialStatus() async {
    final isConnected = await ConnectivityService.instance.isConnected;
    if (!mounted) return;
    setState(() => _isOffline = !isConnected);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.grey.shade800,
            child: const Text(
              'No internet connection',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
