import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/presentation/pages/patient/patient_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';
import 'package:medtrace/services/notification_service.dart';
import 'package:medtrace/services/supabase_service.dart';

class PatientProfilePage extends ConsumerStatefulWidget {
  const PatientProfilePage({super.key});

  @override
  ConsumerState<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends ConsumerState<PatientProfilePage> {
  bool? _notificationOverride;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final summary = ref.watch(currentPatientProfileSummaryProvider);
    final notificationEnabled =
        ref.watch(currentPatientNotificationEnabledProvider);
    final fullName = user?.fullName.trim();
    final name =
        fullName != null && fullName.isNotEmpty ? fullName : 'Sarah Jenkins';
    final email = user?.email ?? 'sarah.jenkins@example.com';
    final summaryValue = summary.valueOrNull;
    final patient = summaryValue?.patient;
    final profile = summaryValue?.profile;
    final doctor = summaryValue?.doctor;
    final facilityName = summaryValue?.facilityName;
    final reminder = summaryValue?.medicationReminder;
    final reminderEnabled =
        _notificationOverride ?? notificationEnabled.valueOrNull ?? true;

    if (summary.isLoading && summaryValue == null) {
      return Scaffold(
        backgroundColor: patientBg,
        appBar: PatientTopBar(
          title: 'Profile',
          showBack: true,
          onLeadingTap: () => context.go(AppRoutes.patientDashboard),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: patientTeal),
        ),
      );
    }

    if (summary.hasError && summaryValue == null) {
      return Scaffold(
        backgroundColor: patientBg,
        appBar: PatientTopBar(
          title: 'Profile',
          showBack: true,
          onLeadingTap: () => context.go(AppRoutes.patientDashboard),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              summary.error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: patientMuted),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: patientBg,
      appBar: PatientTopBar(
        title: 'Profile',
        showBack: true,
        onLeadingTap: () => context.go(AppRoutes.patientDashboard),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 32, 26, 34),
        child: Column(
          children: [
            PatientCard(
              padding: const EdgeInsets.fromLTRB(24, 42, 24, 28),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const PatientAvatar(icon: Icons.person, radius: 44),
                      Positioned(
                        right: -6,
                        bottom: -2,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: patientTeal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: patientText,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Patient ID: ${patient?.patientCode ?? 'Generating...'}',
                    style: const TextStyle(color: patientMuted, fontSize: 15),
                  ),
                  const SizedBox(height: 28),
                  Container(height: 1, color: patientBorder),
                  const SizedBox(height: 24),
                  _InfoRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: email,
                  ),
                  const SizedBox(height: 22),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: profile?.phoneNumber?.trim().isNotEmpty == true
                        ? profile!.phoneNumber!
                        : 'Belum diisi',
                  ),
                  const SizedBox(height: 22),
                  _InfoRow(
                    icon: Icons.home_outlined,
                    label: 'Address',
                    value: patient?.address?.trim().isNotEmpty == true
                        ? patient!.address!
                        : 'Belum diisi',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 56),
            PatientCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    icon: Icons.add_box_outlined,
                    title: 'Treatment Account',
                  ),
                  const SizedBox(height: 20),
                  _TreatmentAccountTile(
                    icon: Icons.business_rounded,
                    label: 'Primary Facility',
                    title: facilityName?.trim().isNotEmpty == true
                        ? facilityName!
                        : 'Assigned Care Team',
                    subtitle: 'Primary treatment facility',
                  ),
                  const SizedBox(height: 18),
                  _TreatmentAccountTile(
                    icon: Icons.person,
                    label: 'Lead Clinician',
                    title: doctor?.fullName.trim().isNotEmpty == true
                        ? doctor!.fullName
                        : doctor?.email ?? 'Assigned Doctor',
                    subtitle: 'Lead clinician',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PatientCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications',
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: _SettingsText(
                          title: 'Daily Reminders',
                          subtitle: 'Show medication pop-up notifications',
                        ),
                      ),
                      Switch(
                        value: reminderEnabled,
                        onChanged: user == null || notificationEnabled.isLoading
                            ? null
                            : (value) => _updateReminderEnabled(
                                  context,
                                  ref,
                                  user.id,
                                  value,
                                ),
                        activeThumbColor: Colors.white,
                        activeTrackColor: patientTeal,
                      ),
                    ],
                  ),
                  const _Divider(),
                  _SettingsValue(
                    title: 'Reminder Time',
                    subtitle: 'When to alert you',
                    value: _formatReminderTime(reminder?.reminderTime),
                    onTap: user == null
                        ? null
                        : () => _pickReminderTime(context, ref, user.id),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 34),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (!context.mounted) return;
                  context.go(AppRoutes.login);
                },
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: patientText,
                  side: const BorderSide(color: patientBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateReminderEnabled(
    BuildContext context,
    WidgetRef ref,
    String userId,
    bool enabled,
  ) async {
    setState(() => _notificationOverride = enabled);
    await ref
        .read(notificationPreferenceServiceProvider)
        .setMedicationNotificationEnabled(
          userId: userId,
          enabled: enabled,
        );

    final summary = ref.read(currentPatientProfileSummaryProvider).valueOrNull;
    if (summary != null) {
      await _syncLocalMedicationNotification(
        summary,
        notificationsEnabled: enabled,
      );
    }

    ref.invalidate(currentPatientNotificationEnabledProvider);
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final summary = ref.read(currentPatientProfileSummaryProvider).valueOrNull;
    final current = summary?.medicationReminder.reminderTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current?.hour ?? 8,
        minute: current?.minute ?? 0,
      ),
    );
    if (picked == null) return;

    final reminderTime = DateTime(0, 1, 1, picked.hour, picked.minute);
    final updated = await ref
        .read(supabaseServiceProvider)
        .updateMedicationReminderPreference(
          userId: userId,
          reminderTime: reminderTime,
        );
    final notificationsEnabled = await ref
        .read(notificationPreferenceServiceProvider)
        .isMedicationNotificationEnabled(userId);
    await _syncLocalMedicationNotification(
      updated,
      notificationsEnabled: notificationsEnabled,
    );
    ref.invalidate(currentPatientProfileSummaryProvider);
  }

  Future<void> _syncLocalMedicationNotification(
    PatientProfileSummary summary, {
    required bool notificationsEnabled,
  }) async {
    final notificationId = summary.medicationReminder.id.hashCode;
    if (!notificationsEnabled) {
      await NotificationService.instance.cancel(notificationId);
      return;
    }

    final reminderTime = summary.medicationReminder.reminderTime;
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await NotificationService.instance.cancel(notificationId);
    await NotificationService.instance.scheduleReminderNotification(
      id: notificationId,
      title: 'Medication Reminder',
      body: 'Time to take your TB medication.',
      when: scheduled,
      repeatsDaily: true,
    );
  }

  String _formatReminderTime(DateTime? time) {
    final value = time ?? DateTime(0, 1, 1, 8);
    final hour = value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:$minute $suffix';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF4C8384), size: 22),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: patientMuted)),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: patientText,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: patientTeal, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: patientText,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TreatmentAccountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String title;
  final String subtitle;

  const _TreatmentAccountTile({
    required this.icon,
    required this.label,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F4),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: patientBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: patientTeal),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: patientMuted)),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: patientText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: patientMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SettingsText({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: patientText, fontSize: 15)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: patientMuted)),
      ],
    );
  }
}

class _SettingsValue extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback? onTap;

  const _SettingsValue({
    required this.title,
    required this.subtitle,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(child: _SettingsText(title: title, subtitle: subtitle)),
          Text(
            value,
            style: const TextStyle(
              color: patientTeal,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded, color: patientTeal),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Container(height: 1, color: patientBorder),
    );
  }
}
