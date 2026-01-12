import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/features/dashboard/presentation/widgets/vendor_bottom_nav.dart';
import 'package:mobile/features/dashboard/presentation/widgets/vendor_header.dart';
import 'package:mobile/features/vendors/data/models/working_hour.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/widgets/working_days_selection_widget.dart';

class WorkingHoursScreen extends StatefulWidget {
  const WorkingHoursScreen({super.key});

  @override
  State<WorkingHoursScreen> createState() => _WorkingHoursScreenState();
}

class _WorkingHoursScreenState extends State<WorkingHoursScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;
  List<WorkingHour> _workingHours = [];
  Map<String, dynamic>? _fullProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getVendorProfile();
      setState(() {
        _fullProfile = profile;
        if (profile['workingHours'] != null &&
            (profile['workingHours'] as List).isNotEmpty) {
          _workingHours = (profile['workingHours'] as List)
              .map((e) => WorkingHour.fromJson(e))
              .toList();
        } else {
          _workingHours = _createDefaultWeek();
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  List<WorkingHour> _createDefaultWeek() {
    final List<String> dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    return List.generate(7, (index) {
      return WorkingHour(
        dayOfWeek: index,
        dayName: dayNames[index],
        startTime: '09:00',
        endTime: '18:00',
        isClosed: false,
      );
    });
  }

  Future<void> _saveWorkingHours() async {
    if (_fullProfile == null) return;

    setState(() => _isSaving = true);

    try {
      // Create a mutable copy of the profile map
      final updateData = Map<String, dynamic>.from(_fullProfile!);

      // Update working hours
      updateData['workingHours'] = _workingHours
          .map((e) => e.toJson())
          .toList();

      // Ensure numeric fields are correctly typed (API might return them as needed)
      // The API Service expects a Map, and we are sending back what we received
      // plus the updated working hours.
      // NOTE: Ideally, we should use a proper DTO, but adhering to current pattern.

      await _apiService.updateVendorProfile(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.workingHoursUpdatedSuccessfully ??
                  'Çalışma saatleri başarıyla güncellendi',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      LoggerService().error('Error saving working hours', e);
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                    context,
                  )?.workingHoursSaveError(e.toString()) ??
                  'Çalışma saatleri kaydedilirken hata oluştu: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: VendorHeader(
        title: localizations?.workingHours ?? 'Çalışma Saatleri',
        leadingIcon: Icons.access_time,
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
        onRefresh: _loadProfile,
        showNotifications: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.vendorPrimary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations?.workingHoursDescription ??
                        'İşletmenizin açık olduğu günleri ve saatleri buradan düzenleyebilirsiniz.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: WorkingDaysSelectionWidget(
                        initialWorkingHours: _workingHours,
                        onWorkingHoursChanged: (updatedHours) {
                          _workingHours = updatedHours;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveWorkingHours,
                      style: AppTheme.primaryButtonVendor,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(localizations?.save ?? 'Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 4),
    );
  }
}
