import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/domain/entities/entities.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/providers/feature_providers.dart';
import 'package:medtrace/presentation/router/app_router.dart';
import 'package:medtrace/presentation/widgets/shimmer_loading.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

/// Doctor alerts page
/// Shows alerts for medication adherence issues and critical patient events
class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  String _filterSeverity = 'all'; // all, critical, high, medium, low

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Alerts')),
        body: const Center(child: Text('Not authenticated')),
      );
    }

    final alertsState = ref.watch(doctorAlertsProvider(userId));
    final alerts = alertsState.alerts.where((alert) {
      final matchesFilter = switch (_filterSeverity) {
        'critical' => alert.severity == 'critical',
        'high' => alert.severity == 'high',
        'medium' => alert.severity == 'medium',
        'low' => alert.severity == 'low',
        _ => true,
      };
      return matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Alerts'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Severity filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildSeverityChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildSeverityChip('Critical', 'critical'),
                  const SizedBox(width: 8),
                  _buildSeverityChip('High', 'high'),
                  const SizedBox(width: 8),
                  _buildSeverityChip('Medium', 'medium'),
                  const SizedBox(width: 8),
                  _buildSeverityChip('Low', 'low'),
                ],
              ),
            ),
          ),

          // Alerts list
          Expanded(
            child: alertsState.isLoading
                ? const ShimmerLoading(type: ShimmerType.card)
                : alerts.isEmpty
                    ? _buildEmptyState()
                    : _buildAlertsList(alerts, userId),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityChip(String label, String value) {
    final isSelected = _filterSeverity == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterSeverity = selected ? value : 'all');
      },
      backgroundColor:
          isSelected ? _getSeverityColor(value).withOpacity(0.2) : Colors.white,
      selectedColor: _getSeverityColor(value).withOpacity(0.1),
      side: BorderSide(
        color: isSelected ? _getSeverityColor(value) : AppColors.borderColor,
      ),
      labelStyle: TextStyle(
        color: isSelected ? _getSeverityColor(value) : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No alerts',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All patients are on track',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList(List<Alert> alerts, String userId) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(doctorAlertsProvider(userId).notifier).loadAlerts();
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildAlertCard(context, alerts[index], userId),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, Alert alert, String userId) {
    final severityColor = _getSeverityColor(alert.severity);
    final icon = _getSeverityIcon(alert.severity);

    return GestureDetector(
      onTap: () => _showAlertDetails(context, alert),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: severityColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: severityColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: severityColor.withOpacity(0.2),
                  ),
                  child: Icon(icon, color: severityColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alert.severity.capitalize,
                        style: AppTypography.caption.copyWith(
                          color: severityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!alert.isRead)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: severityColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Alert type and timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  alert.alertType.capitalize,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  alert.createdAt.formatAlertTime,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),

            // Action buttons
            if (!alert.actionTaken) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.go(AppRoutes.patientDetail, extra: {
                          'patientId': alert.patientId,
                          'patientName': 'Patient',
                        });
                      },
                      icon: const Icon(Icons.person),
                      label: const Text('View Patient'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.doctor,
                        side: const BorderSide(color: AppColors.doctor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _markAlertAsResolved(context, alert, userId),
                      icon: const Icon(Icons.check),
                      label: const Text('Resolved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: severityColor,
                      ),
                    ),
                  ),
                ],
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Resolved',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAlertDetails(BuildContext context, Alert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  alert.title,
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Alert details
            _buildDetailRow('Type', alert.alertType.capitalize),
            const SizedBox(height: 12),
            _buildDetailRow('Severity', alert.severity.capitalize),
            const SizedBox(height: 12),
            _buildDetailRow('Time', alert.createdAt.formatDetailedTime),
            const SizedBox(height: 12),
            _buildDetailRow('Status', alert.actionTaken ? 'Resolved' : 'Open'),

            const SizedBox(height: 24),

            // Action buttons
            if (!alert.actionTaken)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alert marked as resolved'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getSeverityColor(alert.severity),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Mark Resolved'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _markAlertAsResolved(BuildContext context, Alert alert, String userId) {
    ref.read(doctorAlertsProvider(userId).notifier).markAsResolved(alert.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert marked as resolved'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return const Color(0xFFFBBF24);
      default:
        return AppColors.info;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}

extension _StringX on String {
  String get capitalize => '${this[0].toUpperCase()}${substring(1)}';
}

extension _DateTimeFormatX on DateTime {
  String get formatAlertTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '$day/$month';
    }
  }

  String get formatDetailedTime {
    return '$day/$month/$year at ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
