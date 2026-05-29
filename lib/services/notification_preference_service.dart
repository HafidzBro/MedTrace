import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferenceService {
  const NotificationPreferenceService();

  static const _prefix = 'medication_notifications_enabled_';

  Future<bool> isMedicationNotificationEnabled(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$userId') ?? true;
  }

  Future<void> setMedicationNotificationEnabled({
    required String userId,
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$userId', enabled);
  }
}
