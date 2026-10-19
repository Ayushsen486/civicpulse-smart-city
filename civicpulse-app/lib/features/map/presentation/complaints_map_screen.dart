import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../issue/application/issue_controller.dart';
import '../../issue/data/issue_repository.dart';
import '../../issue/domain/issue_model.dart';

enum MapLayerType {
  googleRoads,
  googleSatellite,
  googleTerrain,
  openStreetMap,
}

/// Full-screen Interactive Geospatial Complaints Command Map for Flutter
/// Matches the CivicPulse Admin Portal map with authentic Google raster tiles,
/// live stage markers, area pulse intelligence, radius radar, and citizen upvoting.
class ComplaintsMapScreen extends ConsumerStatefulWidget {
  final String? initialIssueId;

  const ComplaintsMapScreen({
    super.key,
    this.initialIssueId,
  });

  @override
  ConsumerState<ComplaintsMapScreen> createState() => _ComplaintsMapScreenState();
}

class _ComplaintsMapScreenState extends ConsumerState<ComplaintsMapScreen>
    with TickerProviderStateMixin {
  late final MapController _mapController;

  // Map layer type (Google Roadmap by default)
  MapLayerType _currentLayer = MapLayerType.googleRoads;

  // Live user location (Default: Delhi / City Center)
  double _userLat = 28.6139;
  double _userLng = 77.2090;
  bool _hasUserLocation = false;
  bool _isLocating = false;

  // Filters
  String _selectedStatus = 'ALL';
  String _selectedCategory = 'ALL';
  double? _radiusFilterKm; // null = all city, 1, 3, 5 km
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Selected issue for bottom sheet details
  IssueModel? _selectedIssue;

  // Animation controller for pulsing radar
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );

    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation({bool animated = false}) async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        if (mounted) {
          setState(() {
            _userLat = pos.latitude;
            _userLng = pos.longitude;
            _hasUserLocation = true;
            _isLocating = false;
          });
          if (animated) {
            _animatedMapMove(LatLng(_userLat, _userLng), 15.5);
          }
        }
      } else {
        if (mounted) setState(() => _isLocating = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Silky smooth 60fps camera pan & zoom animation
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    final animation =
        CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }

  String _getTileUrl() {
    switch (_currentLayer) {
      case MapLayerType.googleRoads:
        return 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
      case MapLayerType.googleSatellite:
        return 'https://mt{s}.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
      case MapLayerType.googleTerrain:
        return 'https://mt{s}.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
      case MapLayerType.openStreetMap:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> _getSubdomains() {
    if (_currentLayer == MapLayerType.openStreetMap) {
      return const ['a', 'b', 'c'];
    }
    return const ['0', '1', '2', '3'];
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
      case 'REPORTED':
        return const Color(0xFF2563EB); // Vibrant Blue
      case 'ACKNOWLEDGED':
      case 'ASSIGNED':
        return const Color(0xFF7C3AED); // Regal Purple
      case 'IN_PROGRESS':
        return const Color(0xFFD97706); // Amber
      case 'RESOLVED':
        return const Color(0xFF059669); // Emerald Green
      case 'CLOSED':
      case 'REJECTED':
        return const Color(0xFF64748B); // Slate
      default:
        return AppColors.primary;
    }
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('road') || lower.contains('pothole')) return Icons.add_road;
    if (lower.contains('light') || lower.contains('lamp') || lower.contains('pole')) {
      return Icons.lightbulb_outline;
    }
    if (lower.contains('water') || lower.contains('pipe') || lower.contains('drain')) {
      return Icons.water_drop_outlined;
    }
    if (lower.contains('waste') || lower.contains('garbage') || lower.contains('trash')) {
      return Icons.delete_outline;
    }
    if (lower.contains('traffic') || lower.contains('signal')) return Icons.traffic;
    return Icons.report_problem_outlined;
  }

  void _openDirections(double lat, double lng) async {
    final googleMapsUrl =
        Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Target coordinates: $lat, $lng')),
        );
      }
    }
  }

  void _showAreaPulseSummary(List<IssueModel> allIssues) {
    final total = allIssues.length;
    final inProgress =
        allIssues.where((i) => i.status == 'IN_PROGRESS' || i.status == 'ASSIGNED').length;
    final resolved =
        allIssues.where((i) => i.status == 'RESOLVED' || i.status == 'CLOSED').length;
    final critical = allIssues.where((i) => i.priority == 'CRITICAL').length;
    final resolutionRate = total > 0 ? ((resolved / total) * 100).round() : 100;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Neighborhood Area Intelligence',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Real-time municipal health & dispatch overview',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PulseStatBox(
                      title: 'Total Active',
                      value: '$total',
                      color: AppColors.primary,
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PulseStatBox(
                      title: 'Work in Progress',
                      value: '$inProgress',
                      color: const Color(0xFFD97706),
                      icon: Icons.pending_actions,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PulseStatBox(
                      title: 'Resolution Rate',
                      value: '$resolutionRate%',
                      color: const Color(0xFF059669),
                      icon: Icons.verified_outlined,
                    ),
                  ),
                ],
              ),
              if (critical > 0) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.priorityCritical.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.priorityCritical.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.priorityCritical, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$critical Critical Emergency priority complaints require immediate municipal dispatch.',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.priorityCritical,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    context.push('/report');
                  },
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Report New Issue at My Location'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLayerSelector() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Map Tile Layer',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Google Tiles',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.map, color: Colors.blue),
                title: const Text('Google Roadmap (Default)'),
                subtitle: const Text('Crisp vector-rendered roads, landmarks and buildings'),
                trailing: _currentLayer == MapLayerType.googleRoads
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _currentLayer = MapLayerType.googleRoads);
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.satellite_alt, color: Colors.teal),
                title: const Text('Google Satellite (Hybrid)'),
                subtitle: const Text('High-resolution aerial satellite imagery with street labels'),
                trailing: _currentLayer == MapLayerType.googleSatellite
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _currentLayer = MapLayerType.googleSatellite);
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.terrain, color: Colors.green),
                title: const Text('Google Terrain & Topo'),
                subtitle: const Text('Topographical elevation, elevation shading, and trails'),
                trailing: _currentLayer == MapLayerType.googleTerrain
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _currentLayer = MapLayerType.googleTerrain);
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.public, color: Colors.indigo),
                title: const Text('OpenStreetMap Standard'),
                subtitle: const Text('Community open data tile fallback layer'),
                trailing: _currentLayer == MapLayerType.openStreetMap
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _currentLayer = MapLayerType.openStreetMap);
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final issuesAsync = ref.watch(issueListProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: issuesAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading geospatial map...',
                style: TextStyle(color: AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 54, color: AppColors.priorityHigh),
                const SizedBox(height: 16),
                const Text('Failed to load complaints map',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(issueListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Connection'),
                ),
              ],
            ),
          ),
        ),
        data: (allIssues) {
          // If first time and issues available, center on initial issue or first item
          if (!_hasUserLocation && allIssues.isNotEmpty) {
            final target = widget.initialIssueId != null
                ? allIssues.firstWhere((i) => i.id == widget.initialIssueId,
                    orElse: () => allIssues.first)
                : allIssues.first;
            _userLat = target.latitude;
            _userLng = target.longitude;
          }

          // 1. Filter by Status
          var filtered = _selectedStatus == 'ALL'
              ? allIssues
              : allIssues.where((i) => i.status.toUpperCase() == _selectedStatus).toList();

          // 2. Filter by Category
          if (_selectedCategory != 'ALL') {
            filtered = filtered.where((i) => i.categoryName == _selectedCategory).toList();
          }

          // 3. Filter by Radius Radar
          if (_radiusFilterKm != null && _hasUserLocation) {
            filtered = filtered.where((i) {
              final distMeters = Geolocator.distanceBetween(
                _userLat,
                _userLng,
                i.latitude,
                i.longitude,
              );
              return distMeters <= (_radiusFilterKm! * 1000);
            }).toList();
          }

          // 4. Filter by Search Query
          if (_searchQuery.isNotEmpty) {
            filtered = filtered.where((i) {
              final tMatch = i.title.toLowerCase().contains(_searchQuery);
              final dMatch = i.description?.toLowerCase().contains(_searchQuery) ?? false;
              final rMatch = i.issueReference?.toLowerCase().contains(_searchQuery) ?? false;
              final aMatch = (i.address ?? '').toLowerCase().contains(_searchQuery);
              return tMatch || dMatch || rMatch || aMatch;
            }).toList();
          }

          // Markers generation
          final markers = <Marker>[];

          // A. User GPS location marker with pulsing ripple radar
          if (_hasUserLocation) {
            markers.add(
              Marker(
                point: LatLng(_userLat, _userLng),
                width: 44,
                height: 44,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 28 + (_pulseAnimation.value * 16),
                          height: 28 + (_pulseAnimation.value * 16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.withValues(alpha: 0.25 - (_pulseAnimation.value * 0.15)),
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }

          // B. Complaint Markers
          for (final issue in filtered) {
            final isSelected = _selectedIssue?.id == issue.id;
            final statusColor = _getStatusColor(issue.status);
            final isCritical = issue.priority.toUpperCase() == 'CRITICAL';

            markers.add(
              Marker(
                point: LatLng(issue.latitude, issue.longitude),
                width: isSelected ? 54 : 44,
                height: isSelected ? 54 : 44,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedIssue = issue);
                    _animatedMapMove(LatLng(issue.latitude, issue.longitude), 16.0);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glowing halo if critical or selected
                      if (isCritical || isSelected)
                        Container(
                          width: isSelected ? 52 : 44,
                          height: isSelected ? 52 : 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isSelected ? AppColors.primary : AppColors.priorityCritical)
                                .withValues(alpha: 0.35),
                          ),
                        ),
                      // Main stage circle pin
                      Container(
                        width: isSelected ? 40 : 34,
                        height: isSelected ? 40 : 34,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : statusColor,
                            width: isSelected ? 3.0 : 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _getCategoryIcon(issue.categoryName),
                            size: isSelected ? 20 : 16,
                            color: isSelected ? Colors.white : statusColor,
                          ),
                        ),
                      ),
                      // Priority pip (Red dot for critical / high)
                      if (isCritical)
                        Positioned(
                          right: 2,
                          top: 2,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppColors.priorityCritical,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Stack(
            children: [
              // 1. The Full Screen Interactive Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(_userLat, _userLng),
                  initialZoom: 14.2,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onTap: (tapPosition, point) {
                    if (_selectedIssue != null) {
                      setState(() => _selectedIssue = null);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: _getTileUrl(),
                    subdomains: _getSubdomains(),
                    userAgentPackageName: 'com.civicpulse.civicpulse_app',
                  ),
                  // User 1km / radius radar ring
                  if (_hasUserLocation)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: LatLng(_userLat, _userLng),
                          color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                          borderColor: const Color(0xFF2563EB).withValues(alpha: 0.45),
                          borderStrokeWidth: 1.5,
                          useRadiusInMeter: true,
                          radius: (_radiusFilterKm ?? 1.0) * 1000,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // 2. Top Controls & Intelligence Header
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Floating Search Bar & Status Header
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: AppColors.primary, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search complaints by area or title...',
                                    hintStyle: TextStyle(
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onChanged: (q) =>
                                      setState(() => _searchQuery = q.trim().toLowerCase()),
                                ),
                              ),
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                ),
                              // Total filtered badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${filtered.length} pins',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Area Intelligence Pill Bar (Tappable for Area Report)
                      GestureDetector(
                        onTap: () => _showAreaPulseSummary(allIssues),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.grey.shade900 : Colors.white)
                                .withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF059669),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Area Pulse: ${allIssues.length} total • ${_radiusFilterKm != null ? "${_radiusFilterKm!.toStringAsFixed(0)}km radius" : "Citywide"}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.keyboard_arrow_down, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Horizontal Category Filter Pills
                      categoriesAsync.maybeWhen(
                        data: (categories) => SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _FilterChipPill(
                                label: 'All Categories',
                                isSelected: _selectedCategory == 'ALL',
                                onTap: () => setState(() => _selectedCategory = 'ALL'),
                              ),
                              ...categories.map(
                                (c) => _FilterChipPill(
                                  label: c.name,
                                  isSelected: _selectedCategory == c.name,
                                  onTap: () => setState(() => _selectedCategory = c.name),
                                ),
                              ),
                            ],
                          ),
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 6),

                      // Horizontal Status Filter Pills
                      SizedBox(
                        height: 30,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _StatusFilterPill(
                              label: 'All Statuses',
                              isSelected: _selectedStatus == 'ALL',
                              color: AppColors.primary,
                              onTap: () => setState(() => _selectedStatus = 'ALL'),
                            ),
                            _StatusFilterPill(
                              label: 'Reported',
                              isSelected: _selectedStatus == 'SUBMITTED',
                              color: const Color(0xFF2563EB),
                              onTap: () => setState(() => _selectedStatus = 'SUBMITTED'),
                            ),
                            _StatusFilterPill(
                              label: 'In Progress',
                              isSelected: _selectedStatus == 'IN_PROGRESS',
                              color: const Color(0xFFD97706),
                              onTap: () => setState(() => _selectedStatus = 'IN_PROGRESS'),
                            ),
                            _StatusFilterPill(
                              label: 'Resolved',
                              isSelected: _selectedStatus == 'RESOLVED',
                              color: const Color(0xFF059669),
                              onTap: () => setState(() => _selectedStatus = 'RESOLVED'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Right-Side Map Tool Controls
              Positioned(
                right: 16,
                bottom: _selectedIssue != null ? 310 : 32,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Layer Switcher FAB
                    FloatingActionButton.small(
                      heroTag: 'map_layer',
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 4,
                      tooltip: 'Change map layer (Satellite / Terrain / Road)',
                      onPressed: _showLayerSelector,
                      child: const Icon(Icons.layers_outlined, size: 20),
                    ),
                    const SizedBox(height: 8),

                    // Radius Radar Filter FAB
                    FloatingActionButton.small(
                      heroTag: 'map_radar',
                      backgroundColor: _radiusFilterKm != null
                          ? AppColors.primary
                          : (isDark ? Colors.grey.shade800 : Colors.white),
                      foregroundColor: _radiusFilterKm != null ? Colors.white : AppColors.primary,
                      elevation: 4,
                      tooltip: 'Toggle nearby radius (1km / 3km / 5km / All)',
                      onPressed: () {
                        setState(() {
                          if (_radiusFilterKm == null) {
                            _radiusFilterKm = 1.0;
                          } else if (_radiusFilterKm == 1.0) {
                            _radiusFilterKm = 3.0;
                          } else if (_radiusFilterKm == 3.0) {
                            _radiusFilterKm = 5.0;
                          } else {
                            _radiusFilterKm = null;
                          }
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _radiusFilterKm != null
                                  ? 'Radius filter: Showing issues within ${_radiusFilterKm!.toStringAsFixed(0)} km'
                                  : 'Showing all citywide complaints',
                            ),
                            duration: const Duration(milliseconds: 1400),
                          ),
                        );
                      },
                      child: const Icon(Icons.radar, size: 20),
                    ),
                    const SizedBox(height: 8),

                    // Locate Me GPS FAB
                    FloatingActionButton.small(
                      heroTag: 'map_locate',
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                      foregroundColor: _isLocating ? Colors.orange : const Color(0xFF2563EB),
                      elevation: 4,
                      tooltip: 'Recenter to my current GPS location',
                      onPressed: () => _getCurrentLocation(animated: true),
                      child: _isLocating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, size: 20),
                    ),
                    const SizedBox(height: 8),

                    // Zoom In
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_in',
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                      foregroundColor: Colors.grey.shade800,
                      elevation: 3,
                      onPressed: () {
                        _animatedMapMove(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 1.0,
                        );
                      },
                      child: const Icon(Icons.add, size: 20),
                    ),
                    const SizedBox(height: 6),

                    // Zoom Out
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_out',
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.white,
                      foregroundColor: Colors.grey.shade800,
                      elevation: 3,
                      onPressed: () {
                        _animatedMapMove(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 1.0,
                        );
                      },
                      child: const Icon(Icons.remove, size: 20),
                    ),
                  ],
                ),
              ),

              // 4. Interactive Bottom Sheet Preview Card
              if (_selectedIssue != null)
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: _ComplaintDetailSheetCard(
                    issue: _selectedIssue!,
                    userLat: _userLat,
                    userLng: _userLng,
                    onClose: () => setState(() => _selectedIssue = null),
                    onDirections: () => _openDirections(
                      _selectedIssue!.latitude,
                      _selectedIssue!.longitude,
                    ),
                    onUpvoteToggled: () async {
                      final updated = await ref
                          .read(issueRepositoryProvider)
                          .toggleUpvote(_selectedIssue!.id);
                      ref.invalidate(issueListProvider);
                      setState(() {
                        _selectedIssue = _selectedIssue!.copyWith(
                          hasUpvoted: updated,
                          upvotesCount: updated
                              ? _selectedIssue!.upvotesCount + 1
                              : max(0, _selectedIssue!.upvotesCount - 1),
                        );
                      });
                    },
                    onViewFull: () => context.push('/issues/${_selectedIssue!.id}'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _StatusFilterPill({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseStatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _PulseStatBox({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
          ),
        ],
      ),
    );
  }
}

/// Rich Glassmorphic Bottom Sheet Preview Card
class _ComplaintDetailSheetCard extends StatelessWidget {
  final IssueModel issue;
  final double userLat;
  final double userLng;
  final VoidCallback onClose;
  final VoidCallback onDirections;
  final VoidCallback onUpvoteToggled;
  final VoidCallback onViewFull;

  const _ComplaintDetailSheetCard({
    required this.issue,
    required this.userLat,
    required this.userLng,
    required this.onClose,
    required this.onDirections,
    required this.onUpvoteToggled,
    required this.onViewFull,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Approximate distance
    final distMeters = Geolocator.distanceBetween(
      userLat,
      userLng,
      issue.latitude,
      issue.longitude,
    );
    final distText = distMeters < 1000
        ? '${distMeters.round()} m away'
        : '${(distMeters / 1000).toStringAsFixed(1)} km away';

    final thumbnailUrl = issue.attachments.isNotEmpty
        ? ApiEndpoints.getImageUrl(issue.attachments.first.fileUrl)
        : null;

    final priorityColor = AppColors.getPriorityColor(issue.priority);

    return Card(
      elevation: 8,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Reference, Priority & Close
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    issue.issueReference ?? 'CP-${issue.issueNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    issue.priority,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Title and Thumbnail
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        issue.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$distText • ${issue.address ?? issue.wardName ?? "Municipal Ward"}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (thumbnailUrl != null) ...[
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // Stage Stepper
            _StageStepper(status: issue.status),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                // Upvote Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: issue.hasUpvoted ? Colors.red : null,
                    side: BorderSide(
                      color: issue.hasUpvoted ? Colors.red : Colors.grey.shade400,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: onUpvoteToggled,
                  icon: Icon(
                    issue.hasUpvoted ? Icons.favorite : Icons.favorite_border,
                    size: 16,
                    color: issue.hasUpvoted ? Colors.red : null,
                  ),
                  label: Text('${issue.upvotesCount}'),
                ),
                const SizedBox(width: 8),

                // Directions Button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_outlined, size: 16),
                  label: const Text('Directions'),
                ),
                const Spacer(),

                // View Details Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: onViewFull,
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageStepper extends StatelessWidget {
  final String status;

  const _StageStepper({required this.status});

  int _getStepIndex() {
    switch (status.toUpperCase()) {
      case 'SUBMITTED':
      case 'REPORTED':
        return 0;
      case 'ACKNOWLEDGED':
      case 'ASSIGNED':
        return 1;
      case 'IN_PROGRESS':
        return 2;
      case 'RESOLVED':
      case 'CLOSED':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _getStepIndex();
    final stages = ['Reported', 'Assigned', 'In Work', 'Resolved'];

    return Row(
      children: List.generate(stages.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBefore = index ~/ 2;
          final isCompleted = stepBefore < currentStep;
          return Expanded(
            child: Container(
              height: 2.5,
              color: isCompleted ? const Color(0xFF059669) : Colors.grey.shade300,
            ),
          );
        } else {
          // Circle node
          final step = index ~/ 2;
          final isCompleted = step <= currentStep;
          final isCurrent = step == currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? (isCurrent ? AppColors.primary : const Color(0xFF059669))
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                ),
                child: isCompleted && !isCurrent
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 3),
              Text(
                stages[step],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent
                      ? AppColors.primary
                      : isCompleted
                          ? const Color(0xFF059669)
                          : Colors.grey.shade500,
                ),
              ),
            ],
          );
        }
      }),
    );
  }
}
