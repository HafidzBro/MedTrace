import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:medtrace/presentation/pages/doctor/doctor_mockup_widgets.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/services/supabase_service.dart';

enum _MapStatusFilter { all, onTreatment, atRisk, failed, completed }

class DoctorMapPage extends ConsumerStatefulWidget {
  const DoctorMapPage({super.key});

  @override
  ConsumerState<DoctorMapPage> createState() => _DoctorMapPageState();
}

class _DoctorMapPageState extends ConsumerState<DoctorMapPage> {
  late final MapController _mapController;
  _MapStatusFilter _statusFilter = _MapStatusFilter.all;
  bool _summaryExpanded = false;
  String? _focusedLocationId;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summaryState = ref.watch(currentDoctorMapSummaryProvider);
    final summary = summaryState.valueOrNull;
    final cases = _filteredCases(summary?.cases ?? const []);
    final center = _mapCenter(cases, summary?.cases ?? const []);
    _focusInitialMarker(cases, summary?.cases ?? const []);

    return DoctorMockScaffold(
      currentIndex: 2,
      appBar: const DoctorTopBar(
        title: 'MedTrace',
        leadingIcon: Icons.person_outline,
      ),
      backgroundColor: const Color(0xFFB8BDBD),
      extendBody: false,
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: cases.isEmpty ? 5.2 : 12,
                minZoom: 3,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.medtrace.app',
                ),
                CircleLayer(circles: _buildCircles(cases)),
                MarkerLayer(markers: _buildMarkers(cases)),
              ],
            ),
          ),
          Positioned(
            left: 20,
            top: 18,
            child: _StatusFilterChip(
              value: _statusFilter,
              onChanged: (value) =>
                  _selectStatusFilter(value, summary?.cases ?? const []),
            ),
          ),
          const Positioned(
            right: 16,
            top: 18,
            child: _MapLegend(),
          ),
          if (summaryState.isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.32),
              child: const Center(
                child: CircularProgressIndicator(color: doctorTeal),
              ),
            ),
          if (summaryState.hasError && summary == null)
            Center(
              child: _MapMessageCard(
                icon: Icons.error_outline_rounded,
                title: 'Unable to load map',
                message: summaryState.error.toString(),
                onRetry: () => ref.invalidate(currentDoctorMapSummaryProvider),
              ),
            )
          else if (!summaryState.isLoading && (summary?.cases.isEmpty ?? true))
            Center(
              child: _MapMessageCard(
                icon: Icons.location_off_outlined,
                title: 'No current patient locations',
                message:
                    'Patient markers will appear after patients share their current treatment location.',
                onRetry: () => ref.invalidate(currentDoctorMapSummaryProvider),
              ),
            )
          else if (!summaryState.isLoading && cases.isEmpty)
            Center(
              child: _MapMessageCard(
                icon: Icons.filter_alt_off_outlined,
                title: 'No cases match this filter',
                message: 'Try another therapy status filter.',
                onRetry: () => _selectStatusFilter(
                  _MapStatusFilter.all,
                  summary?.cases ?? const [],
                ),
              ),
            ),
          Positioned(
            right: 18,
            bottom: _summaryExpanded ? 206 : 84,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapActionButton(
                  heroTag: 'north_doctor_map',
                  icon: Icons.explore_outlined,
                  tooltip: 'North up',
                  onPressed: () => _mapController.rotate(0),
                ),
                const SizedBox(height: 10),
                _MapActionButton(
                  heroTag: 'refresh_doctor_map',
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh map',
                  onPressed: () =>
                      ref.invalidate(currentDoctorMapSummaryProvider),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _VisibleCasesSummary(
              expanded: _summaryExpanded,
              total: cases.length,
              atRisk: cases.where((item) => item.isAtRisk).length,
              onTreatment: cases.where((item) => item.isOnTreatment).length,
              failed: cases.where((item) => item.isFailed).length,
              completed: cases.where((item) => item.isCompleted).length,
              onToggle: () =>
                  setState(() => _summaryExpanded = !_summaryExpanded),
            ),
          ),
        ],
      ),
    );
  }

  List<DoctorMapCase> _filteredCases(List<DoctorMapCase> cases) {
    return switch (_statusFilter) {
      _MapStatusFilter.onTreatment =>
        cases.where((item) => item.isOnTreatment).toList(),
      _MapStatusFilter.atRisk => cases.where((item) => item.isAtRisk).toList(),
      _MapStatusFilter.failed => cases.where((item) => item.isFailed).toList(),
      _MapStatusFilter.completed =>
        cases.where((item) => item.isCompleted).toList(),
      _MapStatusFilter.all => cases,
    };
  }

  void _focusInitialMarker(
    List<DoctorMapCase> visibleCases,
    List<DoctorMapCase> allCases,
  ) {
    final focusCases = visibleCases.isNotEmpty ? visibleCases : allCases;
    if (focusCases.isEmpty) return;

    final target = focusCases.first.location;
    if (_focusedLocationId == target.patientLocationId) return;
    _focusedLocationId = target.patientLocationId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(
        LatLng(target.latitude, target.longitude),
        13,
      );
    });
  }

  void _selectStatusFilter(
    _MapStatusFilter value,
    List<DoctorMapCase> allCases,
  ) {
    setState(() => _statusFilter = value);

    final selectedCases = _casesForFilter(value, allCases);
    final focusCases = selectedCases.isNotEmpty ? selectedCases : allCases;
    if (focusCases.isEmpty) return;

    final target = focusCases.first.location;
    _focusedLocationId = target.patientLocationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(
        LatLng(target.latitude, target.longitude),
        13,
      );
    });
  }

  List<DoctorMapCase> _casesForFilter(
    _MapStatusFilter value,
    List<DoctorMapCase> cases,
  ) {
    return switch (value) {
      _MapStatusFilter.onTreatment =>
        cases.where((item) => item.isOnTreatment).toList(),
      _MapStatusFilter.atRisk => cases.where((item) => item.isAtRisk).toList(),
      _MapStatusFilter.failed => cases.where((item) => item.isFailed).toList(),
      _MapStatusFilter.completed =>
        cases.where((item) => item.isCompleted).toList(),
      _MapStatusFilter.all => cases,
    };
  }

  List<Marker> _buildMarkers(List<DoctorMapCase> cases) {
    return cases.map((item) {
      final color = _caseColor(item);
      return Marker(
        point: LatLng(item.location.latitude, item.location.longitude),
        width: 42,
        height: 42,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => _showCaseDetails(context, item),
          child: _MapCluster(
            count: item.isAtRisk || item.isFailed
                ? '${item.item.missedCount}'
                : '',
            color: color,
            small: !item.isAtRisk && !item.isFailed,
          ),
        ),
      );
    }).toList();
  }

  List<CircleMarker> _buildCircles(List<DoctorMapCase> cases) {
    return cases
        .map(
          (item) => CircleMarker(
            point: LatLng(item.location.latitude, item.location.longitude),
            radius: 90,
            useRadiusInMeter: true,
            color: _caseColor(item).withValues(alpha: 0.14),
            borderColor: _caseColor(item).withValues(alpha: 0.22),
            borderStrokeWidth: 1,
          ),
        )
        .toList();
  }

  void _showCaseDetails(BuildContext context, DoctorMapCase item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: doctorBorder,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _MapCluster(
                        count: '', color: _caseColor(item), small: true),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.patientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: doctorText,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _caseStatusLabel(item),
                            style: TextStyle(
                              color: _caseColor(item),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _DetailLine(
                    label: 'Patient ID', value: _shortId(item.patientCode)),
                _DetailLine(
                  label: 'Location',
                  value: item.location.address ?? 'Current location recorded',
                ),
                _DetailLine(
                  label: 'Updated',
                  value: DateFormat('d MMM yyyy, HH:mm')
                      .format(item.location.recordedAt),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final _MapStatusFilter value;
  final ValueChanged<_MapStatusFilter> onChanged;

  const _StatusFilterChip({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MapStatusFilter>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: _MapStatusFilter.all, child: Text('All Statuses')),
        PopupMenuItem(
          value: _MapStatusFilter.onTreatment,
          child: Text('On Treatment'),
        ),
        PopupMenuItem(value: _MapStatusFilter.atRisk, child: Text('At Risk')),
        PopupMenuItem(value: _MapStatusFilter.failed, child: Text('Failed')),
        PopupMenuItem(
            value: _MapStatusFilter.completed, child: Text('Completed')),
      ],
      child: _MapFilter(
        icon: Icons.filter_alt_outlined,
        label: _statusFilterLabel(value),
      ),
    );
  }
}

class _MapFilter extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MapFilter({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: doctorTeal),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 118),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: doctorText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: doctorMuted,
            size: 18,
          ),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LEGEND', style: TextStyle(color: doctorMuted, fontSize: 10)),
          SizedBox(height: 8),
          _LegendDot(color: doctorTeal2, label: 'On Treatment'),
          SizedBox(height: 7),
          _LegendDot(color: doctorDanger, label: 'At Risk'),
          SizedBox(height: 7),
          _LegendDot(color: Color(0xFF263238), label: 'Failed'),
          SizedBox(height: 7),
          _LegendDot(color: doctorMint, label: 'Completed'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: doctorText, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _MapCluster extends StatelessWidget {
  final String count;
  final Color color;
  final bool small;

  const _MapCluster({
    required this.count,
    required this.color,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 22.0 : 36.0;
    final text = count == '0' ? '' : count;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 6),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MapActionButton({
    required this.heroTag,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: heroTag,
      tooltip: tooltip,
      backgroundColor: Colors.white,
      foregroundColor: doctorTeal,
      elevation: 4,
      onPressed: onPressed,
      child: Icon(icon, size: 22),
    );
  }
}

class _VisibleCasesSummary extends StatelessWidget {
  final bool expanded;
  final int total;
  final int atRisk;
  final int onTreatment;
  final int failed;
  final int completed;
  final VoidCallback onToggle;

  const _VisibleCasesSummary({
    required this.expanded,
    required this.total,
    required this.atRisk,
    required this.onTreatment,
    required this.failed,
    required this.completed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(28, 10, 28, expanded ? 18 : 12),
      decoration: const BoxDecoration(
        color: doctorBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        border: Border(top: BorderSide(color: doctorBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: doctorBorder,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      expanded ? 'Filtered Cases Summary' : 'Visible Cases',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: doctorText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _CompactMetric(value: total, label: 'Total'),
                  const SizedBox(width: 10),
                  _CompactMetric(value: atRisk, label: 'Risk', danger: true),
                  const SizedBox(width: 6),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: doctorTeal,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryBox(
                        value: '$total',
                        label: 'Total in View',
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _SummaryBox(
                        value: '$atRisk',
                        label: 'At Risk',
                        danger: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SmallSummary(
                        label: 'On Treatment',
                        value: onTreatment,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SmallSummary(
                        label: 'Failed',
                        value: failed,
                        danger: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SmallSummary(
                        label: 'Completed',
                        value: completed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final int value;
  final String label;
  final bool danger;

  const _CompactMetric({
    required this.value,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: danger ? doctorDangerSoft : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: danger ? const Color(0xFFFFB1B1) : doctorBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: danger ? doctorDanger : doctorTeal,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: danger ? doctorDanger : doctorMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String value;
  final String label;
  final bool danger;

  const _SummaryBox({
    required this.value,
    required this.label,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: danger ? doctorDangerSoft : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: danger ? const Color(0xFFFF9D9D) : const Color(0xFFB7C3C3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: danger ? doctorDanger : doctorTeal,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: danger ? doctorDanger : doctorText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallSummary extends StatelessWidget {
  final String label;
  final int value;
  final bool danger;

  const _SmallSummary({
    required this.label,
    required this.value,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: doctorBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: doctorMuted, fontSize: 13),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              color: danger ? doctorDanger : doctorTeal,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _MapMessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 286,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: doctorTeal, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: doctorText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: doctorMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;

  const _DetailLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(color: doctorMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: doctorText,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

LatLng _mapCenter(List<DoctorMapCase> cases, List<DoctorMapCase> fallback) {
  final source = cases.isNotEmpty ? cases : fallback;
  if (source.isEmpty) return const LatLng(-2.5489, 118.0149);

  final lat =
      source.map((item) => item.location.latitude).reduce((a, b) => a + b) /
          source.length;
  final lng =
      source.map((item) => item.location.longitude).reduce((a, b) => a + b) /
          source.length;
  return LatLng(lat, lng);
}

Color _caseColor(DoctorMapCase item) {
  if (item.isFailed) return const Color(0xFF263238);
  if (item.isAtRisk) return doctorDanger;
  if (item.isCompleted) return doctorMint;
  return doctorTeal2;
}

String _caseStatusLabel(DoctorMapCase item) {
  if (item.isFailed) {
    return item.item.missedCount > 0
        ? 'Failed (${item.item.missedCount} missed)'
        : 'Failed';
  }
  if (item.isAtRisk) {
    return item.item.missedCount > 0
        ? 'At Risk (${item.item.missedCount} missed)'
        : 'At Risk';
  }
  if (item.isCompleted) return 'Completed';
  return 'On Treatment';
}

String _statusFilterLabel(_MapStatusFilter value) {
  return switch (value) {
    _MapStatusFilter.onTreatment => 'On Treatment',
    _MapStatusFilter.atRisk => 'At Risk',
    _MapStatusFilter.failed => 'Failed',
    _MapStatusFilter.completed => 'Completed',
    _MapStatusFilter.all => 'Therapy Status',
  };
}

String _shortId(String value) {
  final compact = value.replaceAll('-', '').toUpperCase();
  if (compact.length <= 8) return compact;
  return 'TBM-${compact.substring(compact.length - 6)}';
}
