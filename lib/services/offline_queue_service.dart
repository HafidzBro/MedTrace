import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medtrace/services/connectivity_service.dart';

class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  static const _queueBoxName = 'offline_queue';
  late Box<String> _box;

  Future<void> initialize() async {
    _box = await Hive.openBox<String>(_queueBoxName);
    ConnectivityService.instance.onReconnect.listen((_) => syncAll());
  }

  Future<void> enqueue(OfflineAction action) async {
    final key = DateTime.now().microsecondsSinceEpoch.toString();
    await _box.put(key, jsonEncode(action.toJson()));
  }

  Future<void> syncAll() async {
    final keys = _box.keys.toList();
    for (final key in keys) {
      final raw = _box.get(key);
      if (raw == null) continue;
      final action = OfflineAction.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      final success = await action.execute();
      if (success) await _box.delete(key);
    }
  }

  int get pendingCount => _box.length;
}

class OfflineAction {
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  OfflineAction({required this.type, required this.payload, DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  factory OfflineAction.fromJson(Map<String, dynamic> json) => OfflineAction(
        type: json['type'] as String,
        payload: json['payload'] as Map<String, dynamic>,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Future<bool> execute() async {
    try {
      final client = Supabase.instance.client;
      switch (type) {
        case 'mark_taken':
          await client.from('medication_logs').update({
            'status': 'taken',
            'taken_at': DateTime.now().toIso8601String(),
          }).eq('id', payload['logId']);
          return true;
        case 'mark_missed':
          await client.from('medication_logs').update({
            'status': 'missed',
          }).eq('id', payload['logId']);
          return true;
        case 'create_reminder':
          await client.from('reminders').insert(payload['data']);
          return true;
        case 'delete_reminder':
          await client.from('reminders').delete().eq('id', payload['reminderId']);
          return true;
        case 'record_location':
          await client.from('patient_locations').insert(payload['data']);
          return true;
        default:
          return false;
      }
    } catch (_) {
      return false;
    }
  }
}
