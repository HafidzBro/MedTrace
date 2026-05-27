import 'package:medtrace/data/models/notification_model.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class NotificationDataService {
  final SupabaseServiceContext context;

  const NotificationDataService(this.context);

  Future<NotificationModel> create({
    required String profileId,
    required String title,
    required String message,
    required String type,
  }) async {
    final response = await context.client
        .from('notifications')
        .insert({
          'profile_id': profileId,
          'title': title,
          'message': message,
          'type': type,
        })
        .select()
        .single();

    return NotificationModel.fromJson(response);
  }

  Future<List<NotificationModel>> listForProfile(String profileId) async {
    final response = await context.client
        .from('notifications')
        .select()
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => NotificationModel.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<NotificationModel> markRead(String notificationId) async {
    final response = await context.client
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('notification_id', notificationId)
        .select()
        .single();

    return NotificationModel.fromJson(response);
  }
}
