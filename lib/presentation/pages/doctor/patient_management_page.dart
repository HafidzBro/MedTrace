import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medtrace/core/extensions/extensions.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/providers/feature_providers.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

/// Doctor's patient management page
/// Shows list of patients under doctor's care with treatment status
class PatientManagementPage extends ConsumerStatefulWidget {
  const PatientManagementPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientManagementPage> createState() =>
      _PatientManagementPageState();
}

class _PatientManagementPageState extends ConsumerState<PatientManagementPage> {
  TextEditingController _searchController = TextEditingController();
  String _filterBy = 'all'; // all, good, warning, critical

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Management')),
        body: const Center(child: Text('Not authenticated')),
      );
    }

    final patientsState = ref.watch(doctorPatientsProvider(userId));
    final patients = patientsState.patients.where((overview) {
      final query = _searchController.text.trim().toLowerCase();
      final fullName = overview.patient.fullName ?? '';
      final matchesSearch = query.isEmpty ||
          fullName.toLowerCase().contains(query) ||
          overview.patient.email.toLowerCase().contains(query);

      final matchesFilter = switch (_filterBy) {
        'good' => overview.adherencePercentage >= 80,
        'warning' => overview.adherencePercentage >= 60 &&
            overview.adherencePercentage < 80,
        'critical' => overview.adherencePercentage < 60,
        _ => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search and filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search patients...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(
                        color: AppColors.borderColor,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter chips
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Good Adherence', 'good'),
                      const SizedBox(width: 8),
                      _buildFilterChip('At Risk', 'warning'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Critical', 'critical'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Patient list
          Expanded(
            child: patientsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : patients.isEmpty
                    ? _buildEmptyState(context, userId)
                    : _buildPatientsList(context, patients, userId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGenerateDoctorCodeDialog(context),
        backgroundColor: AppColors.doctor,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterBy == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterBy = selected ? value : 'all');
      },
      backgroundColor:
          isSelected ? AppColors.doctor.withOpacity(0.2) : Colors.white,
      selectedColor: AppColors.doctor.withOpacity(0.1),
      side: BorderSide(
        color: isSelected ? AppColors.doctor : AppColors.borderColor,
      ),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.doctor : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String userId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.textTertiary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No patients yet',
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate a patient code to onboard new patients',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showGenerateDoctorCodeDialog(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Generate Patient Code'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.doctor),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList(
    BuildContext context,
    List<DoctorPatientOverview> patients,
    String doctorId,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(doctorPatientsProvider(doctorId).notifier)
            .loadPatients();
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: patients.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) =>
            _buildPatientCard(context, patients[index]),
      ),
    );
  }

  Widget _buildPatientCard(
    BuildContext context,
    DoctorPatientOverview overview,
  ) {
    final patient = overview.patient;
    final patientName = patient.fullName?.trim().isNotEmpty == true
        ? patient.fullName!
        : 'Unknown Patient';
    final adherence = overview.adherencePercentage;
    final phaseStatus = overview.phase.capitalizeFirst;
    final lastUpdate = overview.lastUpdatedAt ?? DateTime.now();

    Color adherenceColor = adherence > 80
        ? AppColors.success
        : adherence > 60
            ? AppColors.warning
            : AppColors.error;

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Patient $patientName selected'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Patient header
            Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.doctor.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      patientName.isNotEmpty
                          ? patientName[0].toUpperCase()
                          : 'P',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.doctor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Patient info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientName,
                        style: AppTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient.email,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status indicator
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: adherenceColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Treatment status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.borderColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Phase',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phaseStatus,
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Adherence',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${adherence.toStringAsFixed(0)}%',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: adherenceColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Last update
            Text(
              'Last update: ${lastUpdate.formatUpdateTime}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGenerateDoctorCodeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Patient Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A unique 6-character code will be generated. Share this code with the patient to allow them to register.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.borderColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code Validity',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Valid for 30 days from generation\n'
                    '• Can be used by 1 patient only\n'
                    '• Can regenerate after expiry',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authState = ref.read(authProvider);
              final doctorId = authState.user?.id;
              if (doctorId == null) {
                Navigator.pop(context);
                return;
              }

              Navigator.pop(context);

              String code;
              try {
                code = await ref
                    .read(doctorCodeRepositoryProvider)
                    .generateCode(doctorId: doctorId, expiryDays: 30);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to generate code: $e')),
                );
                return;
              }

              if (!context.mounted) return;
              _showGeneratedCodeDialog(context, code);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.doctor),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }

  void _showGeneratedCodeDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Patient Code Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this code with your patient:',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.doctor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.doctor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code,
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.doctor,
                      letterSpacing: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Valid for 30 days. One patient per code.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.doctor),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

extension _DateTimeFormatX on DateTime {
  String get formatUpdateTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day ago';
    } else {
      return '$day/$month/$year';
    }
  }
}
