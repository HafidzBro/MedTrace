import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseServiceContext {
  final SupabaseClient client;
  final Logger logger;

  SupabaseServiceContext({
    required this.client,
    Logger? logger,
  }) : logger = logger ?? Logger();

  String generateCode({int length = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final seed = DateTime.now().microsecondsSinceEpoch;
    return List.generate(length, (index) {
      return chars[(seed + index * 17) % chars.length];
    }).join();
  }

  String toDateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String timeToString(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
