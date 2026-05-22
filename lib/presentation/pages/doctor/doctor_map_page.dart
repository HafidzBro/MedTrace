import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:medtrace/data/models/models.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/providers/feature_providers.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

class DoctorMapPage extends ConsumerStatefulWidget {
  const DoctorMapPage({super.key});

  @override
  ConsumerState<DoctorMapPage> createState() => _DoctorMapPageState();
}

class _DoctorMapPageState extends ConsumerState<DoctorMapPage> {
  final MapController _mapController = MapController();
  String _filterBy = 'all';

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authProvider).user?.id;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Map')),
        body: const Center(child: Text('Not authenticated')),
      );
    }

    final patientsState = ref.watch(doctorPatientsProvider(userId));
    final locationsState = ref.watch(doctorPatientLocationsProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Patient Map'), centerTitle: true, elevation: 0),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildChip('Critical', 'critical'),
                  const SizedBox(width: 8),
                  _buildChip('At Risk', 'warning'),
                  const SizedBox(width: 8),
                  _buildChip('Good', 'good'),
                ],
              ),
            ),
          ),
          // Map
          Expanded(
            child: locationsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _getCenter(locationsState.locations),
                      initialZoom: 10,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.medtrace.app',
                      ),
                      MarkerLayer(markers: _buildMarkers(locationsState.locations, patientsState)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _filterBy == value;
    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (s) => setState(() => _filterBy = s ? value : 'all'),
      visualDensity: VisualDensity.compact,
    );
  }

  LatLng _getCenter(List<PatientLocationModel> locations) {
    if (locations.isEmpty) return const LatLng(-6.2, 106.8); // Jakarta default
    final lat = locations.map((l) => l.latitude).reduce((a, b) => a + b) / locations.length;
    final lng = locations.map((l) => l.longitude).reduce((a, b) => a + b) / locations.length;
    return LatLng(lat, lng);
  }

  List<Marker> _buildMarkers(List<PatientLocationModel> locations, DoctorPatientsState patientsState) {
    final patientAdherence = <String, double>{};
    for (final p in patientsState.patients) {
      patientAdherence[p.patient.id] = p.adherencePercentage;
    }

    return locations.where((loc) {
      final adherence = patientAdherence[loc.patientId] ?? 0;
      return switch (_filterBy) {
        'critical' => adherence < 60,
        'warning' => adherence >= 60 && adherence < 80,
        'good' => adherence >= 80,
        _ => true,
      };
    }).map((loc) {
      final adherence = patientAdherence[loc.patientId] ?? 0;
      final color = adherence >= 80
          ? AppColors.success
          : adherence >= 60
              ? AppColors.warning
              : AppColors.error;

      return Marker(
        point: LatLng(loc.latitude, loc.longitude),
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => _showPatientInfo(loc, adherence),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ),
      );
    }).toList();
  }

  void _showPatientInfo(PatientLocationModel loc, double adherence) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient Location', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('Lat: ${loc.latitude.toStringAsFixed(6)}', style: AppTypography.bodySmall),
            Text('Lng: ${loc.longitude.toStringAsFixed(6)}', style: AppTypography.bodySmall),
            Text('Adherence: ${adherence.toStringAsFixed(0)}%', style: AppTypography.bodySmall),
            Text('Recorded: ${loc.recordedAt.day}/${loc.recordedAt.month}/${loc.recordedAt.year}', style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }
}
