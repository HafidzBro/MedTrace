import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/data/models/medication_log_model.dart';
import 'package:medtrace/services/supabase/dashboard_service.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

class PatientManagementPage extends ConsumerStatefulWidget {
  const PatientManagementPage({super.key});

  @override
  ConsumerState<PatientManagementPage> createState() =>
      _PatientManagementPageState();
}

class _PatientManagementPageState extends ConsumerState<PatientManagementPage> {
  String _query = '';
  _TherapyFilter _filter = _TherapyFilter.all;

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(currentDoctorDashboardSummaryProvider);
    final items = _filteredItems(summary.valueOrNull?.directoryItems ?? []);

    return DoctorMockScaffold(
      currentIndex: 1,
      appBar: DoctorTopBar(
        title: 'MedTrace',
        onLeadingTap: () => context.go(AppRoutes.doctorProfile),
        actions: [
          IconButton(
            onPressed: () => context.go(AppRoutes.alerts),
            icon: const Icon(Icons.notifications_none_rounded),
            color: doctorTeal,
          ),
          const SizedBox(width: 14),
        ],
      ),
      child: RefreshIndicator(
        color: doctorTeal,
        onRefresh: () async {
          ref.invalidate(currentDoctorDashboardSummaryProvider);
          await ref.read(currentDoctorDashboardSummaryProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 104),
          children: [
            const Text(
              'Patient Directory',
              style: TextStyle(
                color: doctorText,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage and monitor active therapy regimens.',
              style: TextStyle(color: doctorMuted, fontSize: 15),
            ),
            const SizedBox(height: 34),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF657174),
                        ),
                        hintText: 'Search by name, ID, or phone...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF7B8588),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide:
                              const BorderSide(color: Color(0xFFB7C3C3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(7),
                          borderSide: const BorderSide(color: doctorTeal),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _FilterMenu(
                  value: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (summary.isLoading && summary.valueOrNull == null)
              const _DirectoryStateCard(
                icon: Icons.hourglass_empty_rounded,
                title: 'Loading patients',
                message: 'Fetching assigned patients from Supabase.',
              )
            else if (summary.hasError && summary.valueOrNull == null)
              _DirectoryStateCard(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load patients',
                message: summary.error.toString(),
                danger: true,
              )
            else if (items.isEmpty)
              const _DirectoryStateCard(
                icon: Icons.person_search_rounded,
                title: 'No patients found',
                message: 'Try changing the search or therapy status filter.',
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: _PatientDirectoryCard(
                    item: item,
                    onTap: () => context.go(
                      AppRoutes.patientDetail,
                      extra: {
                        'patientId': item.patient.patientId,
                        'patientName': _patientName(item),
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<DoctorPatientDirectoryItem> _filteredItems(
    List<DoctorPatientDirectoryItem> items,
  ) {
    final normalizedQuery = _query.trim().toLowerCase();
    return items.where((item) {
      final matchesQuery = normalizedQuery.isEmpty ||
          [
            item.profile.fullName,
            item.profile.email,
            item.profile.phoneNumber,
            item.patient.patientCode,
            item.patient.patientId,
          ]
              .whereType<String>()
              .any((value) => value.toLowerCase().contains(normalizedQuery));
      if (!matchesQuery) return false;

      return switch (_filter) {
        _TherapyFilter.all => true,
        _TherapyFilter.onTreatment => _isOnTreatment(item),
        _TherapyFilter.atRisk => _isAtRisk(item),
        _TherapyFilter.completed => item.therapy?.isCompleted ?? false,
      };
    }).toList();
  }
}

enum _TherapyFilter { all, onTreatment, atRisk, completed }

class _FilterMenu extends StatelessWidget {
  final _TherapyFilter value;
  final ValueChanged<_TherapyFilter> onChanged;

  const _FilterMenu({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_TherapyFilter>(
      initialValue: value,
      onSelected: onChanged,
      tooltip: 'Filter therapy status',
      itemBuilder: (context) => const [
        PopupMenuItem(value: _TherapyFilter.all, child: Text('All patients')),
        PopupMenuItem(
          value: _TherapyFilter.onTreatment,
          child: Text('On Treatment'),
        ),
        PopupMenuItem(value: _TherapyFilter.atRisk, child: Text('At Risk')),
        PopupMenuItem(value: _TherapyFilter.completed, child: Text('Complete')),
      ],
      child: Container(
        width: 60,
        height: 46,
        decoration: BoxDecoration(
          color: value == _TherapyFilter.all ? Colors.white : doctorMintSoft,
          border: Border.all(
            color: value == _TherapyFilter.all
                ? const Color(0xFFB7C3C3)
                : doctorTeal,
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          Icons.filter_list_rounded,
          color: value == _TherapyFilter.all ? doctorText : doctorTeal,
        ),
      ),
    );
  }
}

class _PatientDirectoryCard extends StatelessWidget {
  final DoctorPatientDirectoryItem item;
  final VoidCallback onTap;

  const _PatientDirectoryCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = _patientName(item);
    final status = _therapyStatus(item);
    final days = item.therapy?.treatmentDaysElapsed.clamp(0, 180) ?? 0;
    final progress = (days / 180).clamp(0.0, 1.0);
    final lastLog = _lastLogLabel(item.lastLog);
    final patientCode = item.patient.patientCode?.trim().isNotEmpty == true
        ? item.patient.patientCode!
        : _shortId(item.patient.patientId);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: DoctorCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: status.avatarColor,
                  child: Text(
                    _initials(name),
                    style: TextStyle(
                      color: status.avatarText,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: doctorText,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ID: $patientCode',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: doctorText, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            DoctorChip(
              label: status.label,
              icon: Icons.circle,
              color: status.color,
              textColor: status.textColor,
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: doctorBorder),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Days on Therapy',
                        style: TextStyle(color: doctorMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: const TextStyle(color: doctorText),
                          children: [
                            TextSpan(
                              text: days.toString(),
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const TextSpan(
                              text: ' / 180',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: doctorNeutral,
                          valueColor:
                              AlwaysStoppedAnimation(status.progressColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Last Log',
                        style: TextStyle(color: doctorMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            lastLog.icon,
                            size: 16,
                            color: lastLog.color,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              lastLog.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: doctorText,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectoryStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool danger;

  const _DirectoryStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(18),
      color: danger ? doctorDangerSoft : Colors.white,
      borderColor: danger ? const Color(0xFFFFB4AE) : doctorBorder,
      child: Row(
        children: [
          Icon(icon, color: danger ? doctorDanger : doctorTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: danger ? doctorDanger : doctorText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: danger ? doctorDanger : doctorMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusView {
  final String label;
  final Color color;
  final Color textColor;
  final Color progressColor;
  final Color avatarColor;
  final Color avatarText;

  const _StatusView({
    required this.label,
    required this.color,
    required this.textColor,
    required this.progressColor,
    required this.avatarColor,
    required this.avatarText,
  });
}

class _LastLogView {
  final String label;
  final IconData icon;
  final Color color;

  const _LastLogView({
    required this.label,
    required this.icon,
    required this.color,
  });
}

bool _isAtRisk(DoctorPatientDirectoryItem item) {
  final therapy = item.therapy;
  return item.missedCount > 0 ||
      (therapy?.isDefaulted ?? false) ||
      ((therapy?.isOngoing ?? false) &&
          (therapy?.adherencePercentage ?? 100) < 80);
}

bool _isOnTreatment(DoctorPatientDirectoryItem item) {
  return (item.therapy?.isOngoing ?? false) && !_isAtRisk(item);
}

String _patientName(DoctorPatientDirectoryItem item) {
  final fullName = item.profile.fullName.trim();
  if (fullName.isNotEmpty) return fullName;
  final email = item.profile.email.trim();
  if (email.isNotEmpty) return email;
  return 'Patient';
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'PT';
  final first = parts.first.substring(0, 1);
  final second = parts.length > 1 ? parts.last.substring(0, 1) : '';
  return '$first$second'.toUpperCase();
}

String _shortId(String value) {
  final compact = value.replaceAll('-', '').toUpperCase();
  if (compact.length <= 8) return compact;
  return 'TBM-${compact.substring(compact.length - 6)}';
}

_StatusView _therapyStatus(DoctorPatientDirectoryItem item) {
  final therapy = item.therapy;
  if (therapy?.isCompleted ?? false) {
    return const _StatusView(
      label: 'Complete',
      color: doctorMintSoft,
      textColor: doctorTeal,
      progressColor: doctorTeal2,
      avatarColor: doctorTeal2,
      avatarText: Colors.white,
    );
  }

  if (_isAtRisk(item)) {
    final missed = item.missedCount;
    return _StatusView(
      label: missed > 0 ? 'At Risk ($missed Missed)' : 'At Risk',
      color: doctorDangerSoft,
      textColor: doctorDanger,
      progressColor: doctorDanger,
      avatarColor: doctorDangerSoft,
      avatarText: doctorDanger,
    );
  }

  if (therapy?.isOngoing ?? false) {
    return const _StatusView(
      label: 'On Treatment',
      color: doctorMintSoft,
      textColor: doctorTeal,
      progressColor: doctorTeal2,
      avatarColor: doctorTeal2,
      avatarText: Colors.white,
    );
  }

  return const _StatusView(
    label: 'No Active Therapy',
    color: doctorNeutral,
    textColor: Color(0xFF4F585B),
    progressColor: Color(0xFF7D8788),
    avatarColor: doctorNeutral,
    avatarText: Color(0xFF5D6668),
  );
}

_LastLogView _lastLogLabel(MedicationLogModel? log) {
  if (log == null) {
    return const _LastLogView(
      label: 'No logs yet',
      icon: Icons.schedule_rounded,
      color: doctorMuted,
    );
  }

  final now = DateTime.now();
  final date = DateTime(
      log.scheduledAt.year, log.scheduledAt.month, log.scheduledAt.day);
  final today = DateTime(now.year, now.month, now.day);
  final daysAgo = today.difference(date).inDays;
  final hour = log.scheduledAt.hour.toString().padLeft(2, '0');
  final minute = log.scheduledAt.minute.toString().padLeft(2, '0');

  if (log.isMissed) {
    return _LastLogView(
      label: daysAgo <= 0
          ? 'Missed today'
          : daysAgo == 1
              ? 'Yesterday'
              : '$daysAgo days ago',
      icon: Icons.warning_amber_rounded,
      color: doctorDanger,
    );
  }

  if (daysAgo <= 0) {
    return _LastLogView(
      label: 'Today, $hour:$minute',
      icon: Icons.check_circle_outline_rounded,
      color: doctorTeal,
    );
  }

  return _LastLogView(
    label: daysAgo == 1 ? 'Yesterday' : '$daysAgo days ago',
    icon: Icons.check_circle_outline_rounded,
    color: doctorTeal,
  );
}
