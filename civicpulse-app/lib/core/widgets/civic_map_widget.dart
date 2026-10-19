import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:civicpulse_app/core/theme/app_colors.dart';
import 'package:civicpulse_app/features/issue/domain/issue_model.dart';

/// Reusable OpenStreetMap component for CivicPulse
class CivicMapWidget extends StatefulWidget {
  final double centerLatitude;
  final double centerLongitude;
  final double initialZoom;
  final List<IssueModel> issues;
  final IssueModel? selectedIssue;
  final void Function(IssueModel issue)? onIssueSelected;
  final void Function(LatLng position)? onMapTapped;
  final bool showUserRadar;
  final bool interactive;
  final double height;
  final LatLng? customPin;

  const CivicMapWidget({
    super.key,
    required this.centerLatitude,
    required this.centerLongitude,
    this.initialZoom = 14.5,
    this.issues = const [],
    this.selectedIssue,
    this.onIssueSelected,
    this.onMapTapped,
    this.showUserRadar = true,
    this.interactive = true,
    this.height = 240,
    this.customPin,
  });

  @override
  State<CivicMapWidget> createState() => _CivicMapWidgetState();
}

class _CivicMapWidgetState extends State<CivicMapWidget> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant CivicMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.centerLatitude != widget.centerLatitude ||
        oldWidget.centerLongitude != widget.centerLongitude) {
      _mapController.move(
        LatLng(widget.centerLatitude, widget.centerLongitude),
        widget.initialZoom,
      );
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.centerLatitude, widget.centerLongitude);

    final markers = <Marker>[];

    // 1. User/center location marker
    if (widget.showUserRadar) {
      markers.add(
        Marker(
          point: center,
          width: 38,
          height: 38,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade600,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.45),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 18),
          ),
        ),
      );
    }

    // 2. Custom selected or tapped pin (for report screen picker)
    if (widget.customPin != null) {
      markers.add(
        Marker(
          point: widget.customPin!,
          width: 44,
          height: 44,
          child: const Column(
            children: [
              Icon(Icons.location_on, color: AppColors.primary, size: 38),
            ],
          ),
        ),
      );
    }

    // 3. Issue markers
    for (final issue in widget.issues) {
      final isSelected = widget.selectedIssue?.id == issue.id;
      final statusColor = AppColors.getStatusColor(issue.status);

      markers.add(
        Marker(
          point: LatLng(issue.latitude, issue.longitude),
          width: isSelected ? 48 : 40,
          height: isSelected ? 48 : 40,
          child: GestureDetector(
            onTap: () => widget.onIssueSelected?.call(issue),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : statusColor,
                  width: isSelected ? 3 : 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _getCategoryIcon(issue.categoryName),
                size: isSelected ? 22 : 18,
                color: isSelected ? Colors.white : statusColor,
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: widget.initialZoom,
                interactionOptions: InteractionOptions(
                  flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
                ),
                onTap: (tapPosition, point) {
                  if (widget.onMapTapped != null) {
                    widget.onMapTapped!(point);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                  subdomains: const ['0', '1', '2', '3'],
                  userAgentPackageName: 'com.civicpulse.civicpulse_app',
                ),
                if (widget.showUserRadar)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: center,
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderColor: Colors.blue.withValues(alpha: 0.5),
                        borderStrokeWidth: 1.5,
                        useRadiusInMeter: true,
                        radius: 650, // 650 meter radar radius
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
            // Recenter Floating Button if interactive
            if (widget.interactive)
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: null,
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 3,
                  onPressed: () {
                    _mapController.move(center, widget.initialZoom);
                  },
                  child: const Icon(Icons.my_location, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('road') || lower.contains('pothole')) return Icons.add_road;
    if (lower.contains('light') || lower.contains('lamp')) return Icons.lightbulb_outline;
    if (lower.contains('water') || lower.contains('drain') || lower.contains('leak')) return Icons.water_drop_outlined;
    if (lower.contains('waste') || lower.contains('garbage') || lower.contains('trash')) return Icons.delete_outline;
    if (lower.contains('traffic') || lower.contains('signal')) return Icons.traffic;
    return Icons.report_problem_outlined;
  }
}
