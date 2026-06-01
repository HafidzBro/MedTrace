import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:medtrace/data/models/doctor_code_model.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/router/app_routes.dart';

class DoctorProfilePage extends ConsumerStatefulWidget {
  const DoctorProfilePage({super.key});

  @override
  ConsumerState<DoctorProfilePage> createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends ConsumerState<DoctorProfilePage> {
  bool _isGeneratingCode = false;
  String? _generatedCode;

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider).user;
    final profileState = ref.watch(currentDoctorProfileSummaryProvider);
    final dashboardState = ref.watch(currentDoctorDashboardSummaryProvider);
    final doctorCodesState = ref.watch(currentDoctorCodesProvider);
    final profileSummary = profileState.valueOrNull;
    final dashboard = dashboardState.valueOrNull;
    final doctorCodes = doctorCodesState.valueOrNull ?? const [];
    final activeCode = _generatedCode ?? _latestUsableCode(doctorCodes)?.code;
    final profile = profileSummary?.profile ?? authUser;
    final fullName = profile?.fullName.trim() ?? '';
    final displayName =
        fullName.isEmpty ? 'Doctor' : _withDoctorTitle(fullName);
    final email = profile?.email.trim();
    final phone = profile?.phoneNumber?.trim();
    final facility = profileSummary?.doctor?.facilityName?.trim();

    return Scaffold(
      backgroundColor: doctorBg,
      appBar: DoctorTopBar(
        title: 'Profile',
        showBack: true,
        onLeadingTap: () => context.go(AppRoutes.doctorDashboard),
        actions: [
          IconButton(
            onPressed: () => context.go(AppRoutes.alerts),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: RefreshIndicator(
        color: doctorTeal,
        onRefresh: () async {
          ref.invalidate(currentDoctorProfileSummaryProvider);
          ref.invalidate(currentDoctorDashboardSummaryProvider);
          ref.invalidate(currentDoctorCodesProvider);
          await Future.wait([
            ref.read(currentDoctorProfileSummaryProvider.future),
            ref.read(currentDoctorDashboardSummaryProvider.future),
            ref.read(currentDoctorCodesProvider.future),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(26, 32, 26, 34),
          children: [
            if (profileState.hasError && profileSummary == null) ...[
              _ErrorCard(
                message: profileState.error.toString(),
                onRetry: () =>
                    ref.invalidate(currentDoctorProfileSummaryProvider),
              ),
              const SizedBox(height: 18),
            ],
            DoctorCard(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 26),
              radius: 10,
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      DoctorAvatar(
                        initials: _initials(fullName),
                        icon: Icons.medical_services_rounded,
                        radius: 46,
                      ),
                      Positioned(
                        right: -4,
                        bottom: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: doctorTeal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: doctorText,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DoctorChip(
                    label: profileState.isLoading
                        ? 'Loading profile'
                        : 'Healthcare Worker',
                    color: doctorMintSoft,
                    textColor: doctorTeal,
                    icon: Icons.local_hospital_rounded,
                  ),
                  const SizedBox(height: 26),
                  Container(height: 1, color: doctorBorder),
                  const SizedBox(height: 24),
                  _InfoRow(
                    icon: Icons.mail_outline_rounded,
                    label: 'Email',
                    value: _display(email),
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: _display(phone),
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(
                    icon: Icons.business_rounded,
                    label: 'Facility',
                    value: _display(facility),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            DoctorCard(
              padding: const EdgeInsets.all(24),
              radius: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    icon: Icons.qr_code_2_rounded,
                    title: 'Doctor Code',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate a new registration code when the previous code has expired or reached its usage limit.',
                    style: TextStyle(
                      color: doctorMuted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _DoctorCodeBox(
                    code: activeCode,
                    isLoading: doctorCodesState.isLoading,
                    onCopy: activeCode == null
                        ? null
                        : () => _copyDoctorCode(context, activeCode),
                  ),
                  const SizedBox(height: 14),
                  if (doctorCodesState.hasError &&
                      doctorCodesState.valueOrNull == null) ...[
                    Text(
                      doctorCodesState.error.toString(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: doctorDanger, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: authUser == null || _isGeneratingCode
                          ? null
                          : () => _generateDoctorCode(context, authUser.id),
                      icon: _isGeneratingCode
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_circle_outline_rounded),
                      label: Text(
                        _isGeneratingCode
                            ? 'Generating...'
                            : 'Generate New Code',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: doctorTeal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DoctorCard(
              padding: const EdgeInsets.all(24),
              radius: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    icon: Icons.monitor_heart_outlined,
                    title: 'Care Overview',
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Patients',
                          value: dashboardState.isLoading
                              ? '...'
                              : (dashboard?.totalPatients ?? 0).toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricTile(
                          label: 'Active',
                          value: dashboardState.isLoading
                              ? '...'
                              : (dashboard?.activeTherapies ?? 0).toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricTile(
                          label: 'Alerts',
                          value: dashboardState.isLoading
                              ? '...'
                              : (dashboard?.highPriorityAlerts ?? 0).toString(),
                          danger: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DoctorCard(
              padding: const EdgeInsets.all(24),
              radius: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(
                    icon: Icons.settings_outlined,
                    title: 'Account',
                  ),
                  const SizedBox(height: 18),
                  _ActionTile(
                    icon: Icons.groups_rounded,
                    title: 'Patient Management',
                    subtitle: 'Review assigned patient list',
                    onTap: () => context.go(AppRoutes.patientManagement),
                  ),
                  const _Divider(),
                  _ActionTile(
                    icon: Icons.warning_amber_rounded,
                    title: 'Alert Center',
                    subtitle: 'Follow up on clinical risk alerts',
                    onTap: () => context.go(AppRoutes.alerts),
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
                  foregroundColor: doctorText,
                  side: const BorderSide(color: doctorBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _withDoctorTitle(String value) {
    if (value.startsWith('Dr.')) return value;
    return 'Dr. $value';
  }

  static String _display(String? value) {
    if (value == null || value.isEmpty) return 'Not available';
    return value;
  }

  static String? _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$second'.toUpperCase();
  }

  static DoctorCodeModel? _latestUsableCode(List<DoctorCodeModel> codes) {
    for (final code in codes) {
      if (code.canBeUsed) return code;
    }
    return null;
  }

  Future<void> _generateDoctorCode(
    BuildContext context,
    String doctorId,
  ) async {
    setState(() => _isGeneratingCode = true);
    try {
      final code = await ref.read(supabaseServiceProvider).generateDoctorCode(
            doctorId: doctorId,
            maxUses: 1,
            expiryDays: 30,
          );
      if (!context.mounted) return;
      setState(() => _generatedCode = code);
      ref.invalidate(currentDoctorCodesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Doctor code $code generated.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate code: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingCode = false);
      }
    }
  }

  Future<void> _copyDoctorCode(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Doctor code copied.')),
    );
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
        Icon(icon, color: doctorTeal2, size: 22),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: doctorMuted)),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: doctorText,
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
        Icon(icon, color: doctorTeal, size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: doctorText,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;

  const _MetricTile({
    required this.label,
    required this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: danger ? doctorDangerSoft : const Color(0xFFF2F4F4),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: danger ? const Color(0xFFFFB4AE) : doctorBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: danger ? doctorDanger : doctorTeal,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: danger ? doctorDanger : doctorMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorCodeBox extends StatelessWidget {
  final String? code;
  final bool isLoading;
  final VoidCallback? onCopy;

  const _DoctorCodeBox({
    required this.code,
    required this.isLoading,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final hasCode = code != null && code!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasCode ? doctorMintSoft : const Color(0xFFF2F4F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: doctorBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasCode ? Icons.key_rounded : Icons.key_off_rounded,
              color: hasCode ? doctorTeal : doctorMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading
                      ? 'Checking code'
                      : hasCode
                          ? 'Active Registration Code'
                          : 'No active code available',
                  style: const TextStyle(
                    color: doctorMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading
                      ? '...'
                      : hasCode
                          ? code!
                          : 'Generate a new code',
                  style: TextStyle(
                    color: hasCode ? doctorText : doctorMuted,
                    fontSize: hasCode ? 21 : 15,
                    fontWeight: hasCode ? FontWeight.w800 : FontWeight.w600,
                    letterSpacing: hasCode ? 1 : 0,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Default limit: 1 use, expires in 30 days',
                  style: TextStyle(color: doctorMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded),
            color: hasCode ? doctorTeal : doctorMuted,
            tooltip: 'Copy doctor code',
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: doctorMintSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: doctorTeal, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: doctorText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(color: doctorMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: doctorMuted),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return DoctorCard(
      padding: const EdgeInsets.all(18),
      color: doctorDangerSoft,
      borderColor: const Color(0xFFFFB4AE),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: doctorDanger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: doctorDanger, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
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
      child: Container(height: 1, color: doctorBorder),
    );
  }
}
