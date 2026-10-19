import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:civicpulse_app/core/theme/app_colors.dart';
import 'package:latlong2/latlong.dart';
import 'package:civicpulse_app/core/widgets/civic_map_widget.dart';
import 'package:civicpulse_app/features/issue/application/issue_controller.dart';
import 'package:civicpulse_app/features/issue/data/issue_repository.dart';
import 'package:civicpulse_app/features/issue/domain/category_model.dart';
import 'package:civicpulse_app/features/issue/domain/intelligence_model.dart';

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();

  CategoryModel? _selectedCategory;
  String _selectedPriority = 'MEDIUM';
  double _latitude = 28.6139; // Default municipal center
  double _longitude = 77.2090;
  bool _isLocating = false;
  bool _isSubmitting = false;

  // Photo attachment state
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  // AI draft intelligence state
  IntelligenceModel? _aiSuggestion;
  bool _isAnalyzingAI = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
    _titleController.addListener(_onTextChanged);
    _descController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      final title = _titleController.text.trim();
      if (title.length >= 5) {
        _triggerAiSuggestion(title, _descController.text.trim());
      }
    });
  }

  Future<void> _triggerAiSuggestion(String title, String desc) async {
    setState(() => _isAnalyzingAI = true);
    try {
      final repo = ref.read(issueRepositoryProvider);
      final suggestion = await repo.getDraftSuggestion(
        title: title,
        description: desc,
      );
      if (mounted) {
        setState(() {
          _aiSuggestion = suggestion;
          _isAnalyzingAI = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isAnalyzingAI = false);
      }
    }
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 6),
          ),
        );
        if (mounted) {
          setState(() {
            _latitude = pos.latitude;
            _longitude = pos.longitude;
          });
        }
      }
    } catch (_) {
      // Fallback coordinates preserved
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _applyAiSuggestion(List<CategoryModel> categories) {
    if (_aiSuggestion == null) return;

    if (_aiSuggestion!.suggestedCategoryId != null) {
      final matched = categories.firstWhere(
        (c) => c.id == _aiSuggestion!.suggestedCategoryId,
        orElse: () => categories.first,
      );
      setState(() => _selectedCategory = matched);
    }

    setState(() => _selectedPriority = _aiSuggestion!.suggestedPriority);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Applied AI recommendations!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open camera/gallery: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an issue category')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(issueRepositoryProvider);
      final issue = await repo.createIssue(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _selectedCategory!.id,
        priority: _selectedPriority,
        latitude: _latitude,
        longitude: _longitude,
        address: _addressController.text.trim(),
        landmark: _landmarkController.text.trim(),
      );

      // Upload evidentiary photo if attached
      if (_selectedImage != null && _selectedImageBytes != null) {
        try {
          await repo.uploadAttachment(
            issueId: issue.id,
            filePath: _selectedImage!.path,
            fileBytes: _selectedImageBytes,
            originalFilename: _selectedImage!.name,
            attachmentType: 'REPORT',
            isBefore: true,
          );
        } catch (uploadError) {
          debugPrint('Attachment upload warning: $uploadError');
        }
      }

      // Refresh issue feed
      ref.invalidate(issueListProvider);

      if (mounted) {
        context.pushReplacement(
          '/report-success/${issue.id}',
          extra: {
            'referenceNumber': issue.issueReference,
            'categoryName': issue.categoryName,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Report Civic Issue', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Issue Title *',
                      hintText: 'e.g., Deep pothole on 5th Avenue',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => v == null || v.trim().length < 5
                        ? 'Please enter a descriptive title (min 5 characters)'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Detailed Description',
                      hintText: 'Describe location, hazard severity, or surrounding landmarks...',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI Intelligence Advisory Card
                  if (_isAnalyzingAI || _aiSuggestion != null)
                    categoriesAsync.maybeWhen(
                      data: (categories) => _buildAiAdvisoryCard(categories),
                      orElse: () => const SizedBox.shrink(),
                    ),

                  const SizedBox(height: 16),

                  // Category Selector
                  categoriesAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text('Could not load categories: $err'),
                    data: (categories) {
                      if (_selectedCategory == null && categories.isNotEmpty) {
                        _selectedCategory = categories.first;
                      }
                      return DropdownButtonFormField<CategoryModel>(
                        key: ValueKey(_selectedCategory?.id),
                        initialValue: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: categories.map((cat) {
                          return DropdownMenuItem<CategoryModel>(
                            value: cat,
                            child: Text(cat.name),
                          );
                        }).toList(),
                        onChanged: (cat) {
                          setState(() {
                            _selectedCategory = cat;
                            if (cat != null) {
                              _selectedPriority = cat.defaultPriority;
                            }
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Priority Selector
                  DropdownButtonFormField<String>(
                    key: ValueKey(_selectedPriority),
                    initialValue: _selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priority Level',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'LOW', child: Text('Low (Routine Maintenance)')),
                      DropdownMenuItem(value: 'MEDIUM', child: Text('Medium (Standard Notice)')),
                      DropdownMenuItem(value: 'HIGH', child: Text('High (Safety Hazard)')),
                      DropdownMenuItem(value: 'CRITICAL', child: Text('Critical (Urgent Emergency)')),
                    ],
                    onChanged: (p) => setState(() => _selectedPriority = p ?? 'MEDIUM'),
                  ),
                  const SizedBox(height: 20),

                  // Interactive GPS Geotag & Map Pin-Drop Card
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Exact Issue Location (GPS & Map)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_latitude.toStringAsFixed(5)}° N, ${_longitude.toStringAsFixed(5)}° E',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _isLocating ? null : _fetchCurrentLocation,
                                icon: _isLocating
                                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.gps_fixed, size: 16),
                                label: const Text('My GPS'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Embedded Interactive Map with Pin-Drop
                          CivicMapWidget(
                            centerLatitude: _latitude,
                            centerLongitude: _longitude,
                            height: 180,
                            customPin: LatLng(_latitude, _longitude),
                            showUserRadar: true,
                            onMapTapped: (pt) {
                              setState(() {
                                _latitude = pt.latitude;
                                _longitude = pt.longitude;
                              });
                            },
                          ),
                          const SizedBox(height: 6),
                          const Row(
                            children: [
                              Icon(Icons.touch_app, size: 13, color: AppColors.textSecondaryLight),
                              SizedBox(width: 4),
                              Text(
                                'Tap anywhere on the map to pin the exact problem location.',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address & Landmark
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address (Optional)',
                      hintText: 'e.g., Near Block B Bus Stop',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _landmarkController,
                    decoration: const InputDecoration(
                      labelText: 'Nearest Landmark (Optional)',
                      hintText: 'e.g., Opposite Central Bank',
                      prefixIcon: Icon(Icons.store_mall_directory_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Instant Camera Photo Evidence Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.camera_alt, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Evidentiary Photo (Instant Camera)',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Adding a clear photo helps municipal field officers verify and prioritize the issue immediately.',
                            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
                          ),
                          const SizedBox(height: 14),
                          if (_selectedImage != null && _selectedImageBytes != null)
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    _selectedImageBytes!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedImage!.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      const Row(
                                        children: [
                                          Icon(Icons.check_circle, size: 14, color: AppColors.statusResolved),
                                          SizedBox(width: 4),
                                          Text('Ready to upload', style: TextStyle(color: AppColors.statusResolved, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.priorityCritical),
                                  tooltip: 'Remove photo',
                                  onPressed: () => setState(() {
                                    _selectedImage = null;
                                    _selectedImageBytes = null;
                                  }),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt, size: 18),
                                    label: const Text('Instant Camera'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library, size: 18),
                                    label: const Text('Gallery'),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : const Text('Submit Complaint', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiAdvisoryCard(List<CategoryModel> categories) {
    if (_isAnalyzingAI) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.aiBadge.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.aiBadge),
            ),
            SizedBox(width: 10),
            Text('Analyzing description for smart routing...', style: TextStyle(color: AppColors.aiBadge, fontSize: 13)),
          ],
        ),
      );
    }

    final ai = _aiSuggestion!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.aiBadge.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.aiBadge.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.aiBadge, size: 18),
              const SizedBox(width: 6),
              const Text(
                'AI Triage Suggestion',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.aiBadge),
              ),
              const Spacer(),
              Text(
                '${(ai.overallConfidence * 100).toInt()}% Match',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.aiBadge),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Suggested: ${ai.suggestedCategoryName} • Priority: ${ai.suggestedPriority}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Department: ${ai.recommendedDepartment}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _applyAiSuggestion(categories),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Apply AI Category & Priority'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.aiBadge,
              side: const BorderSide(color: AppColors.aiBadge),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}
