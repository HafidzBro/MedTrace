import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  static const _boxName = 'medtrace_cache';
  late Box<String> _box;

  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
  }

  Future<void> put(String key, dynamic data) async {
    final json = jsonEncode({'data': data, 'cachedAt': DateTime.now().toIso8601String()});
    await _box.put(key, json);
  }

  T? get<T>(String key, {Duration maxAge = const Duration(hours: 24)}) {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(decoded['cachedAt'] as String);
      if (DateTime.now().difference(cachedAt) > maxAge) return null;
      return decoded['data'] as T?;
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async => _box.delete(key);

  Future<void> clear() async => _box.clear();
}
