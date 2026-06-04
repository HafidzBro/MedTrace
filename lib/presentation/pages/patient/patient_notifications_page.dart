import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/data/models/notification_model.dart';
import 'package:medtrace/presentation/pages/patient/patient_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

class PatientNotificationsPage extends ConsumerWidget {
  const PatientNotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(currentPatientNotificationsProvider);

    return PatientMockScaffold(
      currentIndex: -1,
      appBar: PatientTopBar(
        title: 'Notifications',
        showBack: true,
        onLeadingTap: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.patientDashboard);
          }
        },
        actions: const [SizedBox(width: 12)],
      ),
      child: notifications.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: patientTeal),
        ),
        error: (error, _) => _NotificationMessage(
          icon: Icons.notifications_off_outlined,
          title: 'Notifications unavailable',
          message: error.toString(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _NotificationMessage(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              message: 'Updates from your care team will appear here.',
            );
          }

          return RefreshIndicator(
            color: patientTeal,
            onRefresh: () async {
              ref.invalidate(currentPatientNotificationsProvider);
              await ref.read(currentPatientNotificationsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(26, 24, 26, 104),
              children: [
                _NotificationSummary(items: items),
                const SizedBox(height: 22),
                ...items.map(
                  (notification) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _NotificationTile(notification: notification),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  final List<NotificationModel> items;

  const _NotificationSummary({required this.items});

  @override
  Widget build(BuildContext context) {
    final unread = items.where((item) => !item.isRead).length;

    return PatientCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      color: unread > 0 ? patientMintSoft : Colors.white,
      borderColor: unread > 0 ? const Color(0xFFBFEFE6) : patientBorder,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: unread > 0 ? patientTeal : patientNeutral,
              shape: BoxShape.circle,
            ),
            child: Icon(
              unread > 0
                  ? Icons.notifications_active_outlined
                  : Icons.done_all_rounded,
              color: unread > 0 ? Colors.white : patientMuted,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unread > 0 ? '$unread unread notification' : 'All caught up',
                  style: const TextStyle(
                    color: patientText,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${items.length} total updates',
                  style: const TextStyle(color: patientMuted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !notification.isRead;
    final accent = _accentColor(notification.type);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openNotification(context, ref),
      child: PatientCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        borderColor: unread ? accent.withValues(alpha: 0.45) : patientBorder,
        color: unread ? accent.withValues(alpha: 0.07) : Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: unread ? 0.16 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(notification.type), color: accent, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: patientText,
                            fontSize: 16,
                            fontWeight:
                                unread ? FontWeight.w800 : FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _relativeTime(notification.createdAt),
                        style: const TextStyle(
                          color: patientMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      color: Color(0xFF50585C),
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      PatientChip(
                        label: _typeLabel(notification.type),
                        color: accent.withValues(alpha: 0.13),
                        textColor: accent,
                      ),
                      if (unread) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: patientTeal,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNotification(BuildContext context, WidgetRef ref) async {
    if (!notification.isRead) {
      try {
        await ref
            .read(supabaseServiceProvider)
            .markPatientNotificationRead(notification.notificationId);
        ref.invalidate(currentPatientNotificationsProvider);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
        return;
      }
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static IconData _icon(String type) {
    switch (type) {
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'reminder':
        return Icons.alarm_rounded;
      case 'therapy':
        return Icons.auto_graph_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  static Color _accentColor(String type) {
    switch (type) {
      case 'alert':
        return const Color(0xFFC5161D);
      case 'reminder':
        return patientTeal;
      case 'therapy':
        return const Color(0xFF177C38);
      default:
        return const Color(0xFF5F686B);
    }
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'alert':
        return 'Alert';
      case 'reminder':
        return 'Reminder';
      case 'therapy':
        return 'Therapy';
      default:
        return 'Update';
    }
  }

  static String _relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}

class _NotificationMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _NotificationMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PatientAvatar(icon: icon, radius: 30),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: patientText,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: patientMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
