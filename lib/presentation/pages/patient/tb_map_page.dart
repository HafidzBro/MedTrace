import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medtrace/presentation/providers/app_providers.dart';
import 'package:medtrace/presentation/providers/feature_providers.dart';
import 'package:medtrace/shared/theme/app_theme.dart';

/// TB Map visualization page
/// Shows patient location and TB distribution in geographic area
class TbMapPage extends ConsumerStatefulWidget {
  const TbMapPage({Key? key}) : super(key: key);

  @override
  ConsumerState<TbMapPage> createState() => _TbMapPageState();
}

class _TbMapPageState extends ConsumerState<TbMapPage> {
  late MapController _mapController;
  late LatLng _currentLocation;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLocation = const LatLng(0, 0);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final newPermission = await Geolocator.requestPermission();
        if (newPermission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission is required')),
            );
          }
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController.move(_currentLocation, 13);

      // Record location in database
      if (mounted) {
        final authState = ref.read(authProvider);
        final userId = authState.user?.id;
        if (userId != null) {
          ref.read(patientLocationsProvider(userId).notifier).recordLocation(
                latitude: position.latitude,
                longitude: position.longitude,
              );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('TB Map')),
        body: const Center(child: Text('Not authenticated')),
      );
    }

    final locationsState = ref.watch(patientLocationsProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('TB Distribution Map'),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 13,
              onPositionChanged: (_, __) {},
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.medtrace.app',
              ),
              CircleLayer(circles: _buildCircles(locationsState)),
              MarkerLayer(markers: _buildMarkers(locationsState)),
            ],
          ),

          // Loading indicator
          if (_isLoadingLocation)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Bottom sheet with location info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildLocationInfo(locationsState),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(dynamic locationsState) {
    if (locationsState.locations.isEmpty) {
      return [];
    }

    // Current location marker
    List<Marker> markers = [
      Marker(
        point: _currentLocation,
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () => _showLocationDetails(null),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.patient,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.patient.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
          ),
        ),
      ),
    ];

    // Previous location markers
    for (final location in locationsState.locations) {
      markers.add(
        Marker(
          point: LatLng(location.latitude, location.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _showLocationDetails(location),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warning.withOpacity(0.8),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.location_history,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<CircleMarker> _buildCircles(dynamic locationsState) {
    if (locationsState.locations.isEmpty) {
      return [];
    }

    List<CircleMarker> circles = [];

    // Add radius circles to show coverage
    for (final location in locationsState.locations) {
      circles.add(
        CircleMarker(
          point: LatLng(location.latitude, location.longitude),
          radius: 100, // 100 meters
          useRadiusInMeter: true,
          color: AppColors.warning.withOpacity(0.2),
          borderStrokeWidth: 1,
          borderColor: AppColors.warning.withOpacity(0.5),
        ),
      );
    }

    return circles;
  }

  Widget _buildLocationInfo(dynamic locationsState) {
    if (locationsState.isLoading) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (locationsState.locations.isEmpty) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location History',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No location records yet',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 40,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location History',
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.vertical,
                    itemCount: locationsState.locations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final location = locationsState.locations[index];
                      return _buildLocationTile(location);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile(dynamic location) {
    return GestureDetector(
      onTap: () => _showLocationDetails(location),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.borderColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: AppColors.patient, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.address ?? 'Unknown location',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    location.recordedAt.formattedDateTime,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationDetails(dynamic location) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location == null ? 'Current Location' : 'Location History',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (location == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Latitude',
                    _currentLocation.latitude.toStringAsFixed(6),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Longitude',
                    _currentLocation.longitude.toStringAsFixed(6),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Recorded', 'Just now'),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Address', location.address ?? 'N/A'),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Latitude',
                    location.latitude.toStringAsFixed(6),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Longitude',
                    location.longitude.toStringAsFixed(6),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Accuracy',
                    '±${location.accuracy?.toStringAsFixed(0) ?? 'N/A'} meters',
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Recorded',
                    location.recordedAt.formattedDateTime,
                  ),
                ],
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Close'),
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
}
