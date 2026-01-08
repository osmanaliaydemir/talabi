import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/profile/data/models/courier.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/features/dashboard/presentation/widgets/courier_bottom_nav.dart';
import 'package:mobile/features/dashboard/presentation/widgets/courier_header.dart';
import 'package:mobile/features/vendors/data/models/working_hour.dart';
import 'package:mobile/widgets/working_days_selection_widget.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:provider/provider.dart';
import 'package:mobile/services/api_service.dart';

class CourierEditProfileScreen extends StatefulWidget {
  const CourierEditProfileScreen({super.key});

  @override
  State<CourierEditProfileScreen> createState() =>
      _CourierEditProfileScreenState();
}

class _CourierEditProfileScreenState extends State<CourierEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final CourierService _courierService = CourierService();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _vehicleController;
  late TextEditingController _maxOrdersController;
  late TextEditingController _shamCashController;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _useWorkingHours = false;
  List<WorkingHour> _workingHours = [];

  List<VehicleTypeOption> _vehicleTypes = [];
  bool _isVehicleTypesLoading = true;
  String? _selectedVehicleKey;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _vehicleController = TextEditingController();
    _maxOrdersController = TextEditingController(text: '3');
    _shamCashController = TextEditingController();
    _loadProfile();
    _loadVehicleTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _maxOrdersController.dispose();
    _shamCashController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final courier = await _courierService.getProfile();
      _fillFromCourier(courier);
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierEditProfileScreen: ERROR loading profile',
        e,
        stackTrace,
      );
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations != null
                  ? localizations.failedToLoadProfile(e)
                  : 'Profil yüklenemedi: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _fillFromCourier(Courier courier) {
    _nameController.text = courier.name;
    _phoneController.text = courier.phoneNumber ?? '';
    _vehicleController.text = courier.vehicleType ?? '';
    _maxOrdersController.text = courier.maxActiveOrders.toString();
    _shamCashController.text = courier.shamCashAccountNumber ?? '';
    _selectedVehicleKey = courier.vehicleType;

    if (courier.workingHours != null && courier.workingHours!.isNotEmpty) {
      _workingHours = List.from(courier.workingHours!);
    } else {
      // Fallback or Legacy check
      if (courier.workingHoursStart != null &&
          courier.workingHoursEnd != null) {
        _workingHours = _createDefaultWeek(
          courier.workingHoursStart,
          courier.workingHoursEnd,
        );
      } else {
        // Default initialized
        _workingHours = _createDefaultWeek(null, null);
      }
    }
  }

  List<WorkingHour> _createDefaultWeek(String? start, String? end) {
    final List<String> dayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    // Assuming backend uses 0=Sunday

    return List.generate(7, (index) {
      return WorkingHour(
        dayOfWeek: index,
        dayName: dayNames[index],
        startTime: start ?? '09:00',
        endTime: end ?? '18:00',
        isClosed: start == null,
      );
    });
  }

  Future<void> _loadVehicleTypes() async {
    try {
      final types = await _courierService.getVehicleTypes();
      if (!mounted) return;
      setState(() {
        _vehicleTypes = types;
        _isVehicleTypesLoading = false;
      });
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierEditProfileScreen: ERROR loading vehicle types',
        e,
        stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _vehicleTypes = [];
        _isVehicleTypesLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_useWorkingHours && _workingHours.isEmpty) {
      // Should not happen if initialized correctly
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final data = <String, dynamic>{
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'vehicleType': _selectedVehicleKey,
        'maxActiveOrders': int.tryParse(_maxOrdersController.text.trim()) ?? 3,
        'shamCashAccountNumber': _shamCashController.text.trim().isEmpty
            ? null
            : _shamCashController.text.trim(),
      };

      if (_useWorkingHours) {
        data['isWithinWorkingHours'] = true;
        data['workingHours'] = _workingHours.map((e) => e.toJson()).toList();

        // Backward compatibility: set start/end from first open day
        final openDay = _workingHours.firstWhere(
          (w) => !w.isClosed,
          orElse: () => _workingHours.first,
        );
        data['workingHoursStart'] =
            openDay.startTime != null && openDay.startTime!.length == 5
            ? '${openDay.startTime}:00'
            : (openDay.startTime ?? '09:00:00');
        data['workingHoursEnd'] =
            openDay.endTime != null && openDay.endTime!.length == 5
            ? '${openDay.endTime}:00'
            : (openDay.endTime ?? '18:00:00');
      } else {
        data['isWithinWorkingHours'] = false;
        data['workingHours'] = [];
        data['workingHoursStart'] = null;
        data['workingHoursEnd'] = null;
      }

      LoggerService().debug('CourierEditProfileScreen: Saving profile $data');
      await _courierService.updateProfile(data);

      if (!mounted) return;

      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.profileUpdatedSuccessfully ??
                'Profil başarıyla güncellendi',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierEditProfileScreen: ERROR saving profile',
        e,
        stackTrace,
      );
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.profileUpdateFailed(e.toString()) ??
                  'Profil güncellenemedi: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showDeleteAccountConfirmation() async {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CustomConfirmationDialog(
        title: localizations.deleteMyAccountConfirmationTitle,
        message: localizations.deleteMyAccountConfirmationMessage,
        confirmText: localizations.delete,
        cancelText: localizations.vazgec,
        onConfirm: () => Navigator.pop(context, true),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final apiService = ApiService();
        await apiService.deleteAccount();
        if (mounted) {
          final auth = context.read<AuthProvider>();
          await auth.logout();
          if (!mounted) return;

          context.read<BottomNavProvider>().reset();
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/courier/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.errorWithMessage(e.toString())),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: localizations?.editProfile ?? 'Profil Düzenle',
        leadingIcon: Icons.person_outline,
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
        onRefresh: _loadProfile,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations?.personalInfo ?? 'Kişisel Bilgiler',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText:
                                      localizations?.fullName ?? 'Ad Soyad',
                                  prefixIcon: const Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return localizations?.fullNameRequired ??
                                        'Ad soyad zorunludur';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText:
                                      localizations?.phoneNumber ?? 'Telefon',
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _shamCashController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.of(
                                    context,
                                  )!.shamCashAccountNumber,
                                  prefixIcon: const Icon(
                                    Icons.account_balance_wallet_outlined,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        localizations?.courierSettings ?? 'Kurye Ayarları',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (_isVehicleTypesLoading)
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: LinearProgressIndicator(),
                                  ),
                                )
                              else
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      _selectedVehicleKey != null &&
                                          _selectedVehicleKey!.isNotEmpty
                                      ? _selectedVehicleKey
                                      : null,
                                  decoration: InputDecoration(
                                    labelText:
                                        localizations?.vehicleType ??
                                        'Araç Türü',
                                    prefixIcon: const Icon(
                                      Icons.delivery_dining,
                                    ),
                                  ),
                                  items: _vehicleTypes
                                      .map(
                                        (type) => DropdownMenuItem<String>(
                                          value: type.key,
                                          child: Text(type.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedVehicleKey = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return localizations
                                              ?.mustSelectVehicleType ??
                                          'Araç türü seçmelisin';
                                    }
                                    return null;
                                  },
                                ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _maxOrdersController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText:
                                      localizations?.maxActiveOrders ??
                                      'Maksimum Aktif Sipariş',
                                  prefixIcon: const Icon(
                                    Icons.countertops_outlined,
                                  ),
                                ),
                                validator: (value) {
                                  final parsed = int.tryParse(value ?? '');
                                  if (parsed == null || parsed <= 0) {
                                    return localizations?.enterValidNumber ??
                                        'Geçerli bir sayı gir';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  localizations?.useWorkingHours ??
                                      'Çalışma saatlerini kullan',
                                ),
                                subtitle: Text(
                                  localizations?.onlyAvailableDuringSetHours ??
                                      'Sadece belirlediğin saatlerde "Müsait" olabilirsin',
                                ),
                                value: _useWorkingHours,
                                onChanged: (value) {
                                  setState(() {
                                    _useWorkingHours = value;
                                  });
                                },
                              ),
                              if (_useWorkingHours) ...[
                                const SizedBox(height: 16),
                                WorkingDaysSelectionWidget(
                                  initialWorkingHours: _workingHours,
                                  onWorkingHoursChanged: (updatedHours) {
                                    _workingHours = updatedHours;
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
      bottomNavigationBar: const CourierBottomNav(currentIndex: 3),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(
              _isSaving
                  ? (localizations?.saving ?? 'Kaydediliyor...')
                  : (localizations?.save ?? 'Kaydet'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ),
      persistentFooterButtons: [
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _isSaving ? null : _showDeleteAccountConfirmation,
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: Text(
              localizations?.deleteMyAccount ?? 'Hesabımı Sil',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
