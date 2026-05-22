import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrace/core/extensions/extensions.dart';
import 'package:medtrace/domain/entities/entities.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/providers/feature_providers.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

/// Patient reminders page
/// Shows upcoming medication and appointment reminders
class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reminders')),
        body: const Center(child: Text('Not authenticated')),
      );
    }

    final remindersState = ref.watch(patientRemindersProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reminders'),
        elevation: 0,
        centerTitle: true,
      ),
      body: remindersState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : remindersState.reminders.isEmpty
              ? _buildEmptyState(context, userId)
              : _buildRemindersList(
                  context, remindersState.reminders, ref, userId),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateReminderDialog(context, userId, ref),
        backgroundColor: AppColors.patient,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.alarm_off,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No reminders yet',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a reminder to stay on track',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showCreateReminderDialog(context, userId, ref),
            icon: const Icon(Icons.add),
            label: const Text('Create Reminder'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.patient),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersList(
    BuildContext context,
    List<Reminder> reminders,
    WidgetRef ref,
    String userId,
  ) {
    // Separate upcoming and past reminders
    final now = DateTime.now();
    final upcoming =
        reminders.where((r) => r.scheduledDate.isAfter(now)).toList();
    final past = reminders.where((r) => r.scheduledDate.isBefore(now)).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(patientRemindersProvider(userId));
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upcoming reminders
              if (upcoming.isNotEmpty) ...[
                Text(
                  'Upcoming',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: upcoming.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildReminderCard(
                    context,
                    upcoming[index],
                    ref,
                    userId,
                    isUpcoming: true,
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Past reminders
              if (past.isNotEmpty) ...[
                Text(
                  'History',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: past.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildReminderCard(
                    context,
                    past[index],
                    ref,
                    userId,
                    isUpcoming: false,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    Reminder reminder,
    WidgetRef ref,
    String userId, {
    required bool isUpcoming,
  }) {
    final icon = _getReminderIcon(reminder.reminderType);
    final isOverdue = !isUpcoming && !reminder.isSent;
    final color = isOverdue
        ? AppColors.error
        : isUpcoming
            ? AppColors.patient
            : AppColors.textTertiary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.error.withOpacity(0.05)
            : isUpcoming
                ? AppColors.patient.withOpacity(0.05)
                : AppColors.borderColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withOpacity(0.3)
              : isUpcoming
                  ? AppColors.patient.withOpacity(0.2)
                  : AppColors.borderColor,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reminder.title,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isOverdue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'OVERDUE',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    if (reminder.isSent && !isUpcoming)
                      Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${reminder.reminderType.toString().split('.').last} • ${reminder.scheduledDate.formatReminderTime}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton(
            itemBuilder: (context) => [
              if (isOverdue)
                PopupMenuItem(
                  child: const Text('Mark Completed'),
                  onTap: () => _markCompleted(context, reminder, userId, ref),
                ),
              PopupMenuItem(
                child: const Text('Edit'),
                onTap: () =>
                    _showEditReminderDialog(context, reminder, userId, ref),
              ),
              PopupMenuItem(
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => _deleteReminder(context, reminder, userId, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _markCompleted(
    BuildContext context,
    Reminder reminder,
    String userId,
    WidgetRef ref,
  ) {
    ref.read(patientRemindersProvider(userId).notifier).updateReminder(
          reminderId: reminder.id,
          title: reminder.title,
          description: reminder.description,
          scheduledDate: reminder.scheduledDate,
          scheduledTime: reminder.scheduledTime,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder marked as completed')),
    );
  }

  void _showCreateReminderDialog(
    BuildContext context,
    String userId,
    WidgetRef ref,
  ) {
    String title = '';
    String reminderType = 'medication';
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title input
                TextField(
                  onChanged: (value) => title = value,
                  decoration: InputDecoration(
                    hintText: 'Reminder title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Type dropdown
                Text(
                  'Type',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: reminderType,
                  isExpanded: true,
                  items: ['medication', 'appointment', 'checkup', 'custom']
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.capitalize),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => reminderType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Date picker
                Text(
                  'Date',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate.formatDateOnly,
                          style: AppTypography.bodySmall,
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppColors.patient,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time picker
                Text(
                  'Time',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedTime.format(context),
                          style: AppTypography.bodySmall,
                        ),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.patient,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: title.isNotEmpty
                  ? () async {
                      final scheduledTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      await ref
                          .read(patientRemindersProvider(userId).notifier)
                          .createReminder(
                            title: title,
                            reminderType: reminderType,
                            scheduledDate: selectedDate,
                            scheduledTime: scheduledTime,
                          );

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reminder created'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditReminderDialog(
    BuildContext context,
    Reminder reminder,
    String userId,
    WidgetRef ref,
  ) {
    final titleController = TextEditingController(text: reminder.title);
    DateTime selectedDate = reminder.scheduledDate;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(reminder.scheduledTime);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Reminder title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 1),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDate.formatDateOnly,
                          style: AppTypography.bodySmall,
                        ),
                        const Icon(Icons.calendar_today, size: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedTime.format(context),
                          style: AppTypography.bodySmall,
                        ),
                        const Icon(Icons.access_time, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final scheduledTime = DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                );

                await ref
                    .read(patientRemindersProvider(userId).notifier)
                    .updateReminder(
                      reminderId: reminder.id,
                      title: titleController.text.trim(),
                      description: reminder.description,
                      scheduledDate: selectedDate,
                      scheduledTime: scheduledTime,
                    );

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteReminder(
    BuildContext context,
    Reminder reminder,
    String userId,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref
                  .read(patientRemindersProvider(userId).notifier)
                  .deleteReminder(reminder.id);

              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reminder deleted'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getReminderIcon(String reminderType) {
    switch (reminderType.toLowerCase()) {
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.calendar_today;
      case 'checkup':
        return Icons.local_hospital;
      default:
        return Icons.notifications;
    }
  }
}

extension _DateTimeFormatX on DateTime {
  String get formatReminderTime {
    if (isToday) {
      return 'Today at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } else if (isTomorrow) {
      return 'Tomorrow at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    } else {
      return '$day/$month/$year at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
  }

  String get formatDateOnly {
    if (isToday) {
      return 'Today';
    } else if (isTomorrow) {
      return 'Tomorrow';
    } else {
      return '$day/$month/$year';
    }
  }
}

extension _StringX on String {
  String get capitalize => '${this[0].toUpperCase()}${substring(1)}';
}
