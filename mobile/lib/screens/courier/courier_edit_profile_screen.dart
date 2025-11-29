import 'package:flutter/material.dart';

import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/courier.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/widgets/courier/courier_bottom_nav.dart';
import 'package:mobile/widgets/courier/courier_header.dart';

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

  bool _isLoading = true;
  bool _isSaving = false;
  bool _useWorkingHours = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
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
    _loadProfile();
    _loadVehicleTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _maxOrdersController.dispose();
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
      print('CourierEditProfileScreen: ERROR loading profile - $e');
      print(stackTrace);
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.failedToLoadProfile ?? 'Profil yüklenemedi: $e',
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
    _selectedVehicleKey = courier.vehicleType;

    if (courier.workingHoursStart != null &&
        courier.workingHoursEnd != null &&
        courier.isWithinWorkingHours == true) {
      _useWorkingHours = true;
      _startTime = _parseTimeOfDay(courier.workingHoursStart!);
      _endTime = _parseTimeOfDay(courier.workingHoursEnd!);
    }
  }

  TimeOfDay _parseTimeOfDay(String value) {
    // Expecting "HH:mm" or "HH:mm:ss"
    final parts = value.split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 9, minute: 0);
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
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
      print('CourierEditProfileScreen: ERROR loading vehicle types - $e');
      print(stackTrace);
      if (!mounted) return;
      setState(() {
        _vehicleTypes = [];
        _isVehicleTypesLoading = false;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart
        ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 18, minute: 0));
    final result = await showTimePicker(context: context, initialTime: initial);
    if (result != null) {
      setState(() {
        if (isStart) {
          _startTime = result;
        } else {
          _endTime = result;
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_useWorkingHours && (_startTime == null || _endTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çalışma saatleri için başlangıç ve bitiş seçmelisin.'),
        ),
      );
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
      };

      if (_useWorkingHours && _startTime != null && _endTime != null) {
        data['workingHoursStart'] = _formatTimeOfDay(_startTime!);
        data['workingHoursEnd'] = _formatTimeOfDay(_endTime!);
        data['isWithinWorkingHours'] = true;
      } else {
        data['workingHoursStart'] = null;
        data['workingHoursEnd'] = null;
        data['isWithinWorkingHours'] = false;
      }

      print('CourierEditProfileScreen: Saving profile $data');
      await _courierService.updateProfile(data);

      if (!mounted) return;

      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.profile ?? 'Profil başarıyla güncellendi',
          ),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e, stackTrace) {
      print('CourierEditProfileScreen: ERROR saving profile - $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profil güncellenemedi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: localizations?.profile ?? 'Profil Düzenle',
        leadingIcon: Icons.person_outline,
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
        onRefresh: _loadProfile,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kişisel Bilgiler',
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
                                decoration: const InputDecoration(
                                  labelText: 'Ad Soyad',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ad soyad zorunludur';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Telefon',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Kurye Ayarları',
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
                                  value:
                                      _selectedVehicleKey != null &&
                                          _selectedVehicleKey!.isNotEmpty
                                      ? _selectedVehicleKey
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: 'Araç Türü',
                                    prefixIcon: Icon(Icons.delivery_dining),
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
                                      return 'Araç türü seçmelisin';
                                    }
                                    return null;
                                  },
                                ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _maxOrdersController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Maksimum Aktif Sipariş',
                                  prefixIcon: Icon(Icons.countertops_outlined),
                                ),
                                validator: (value) {
                                  final parsed = int.tryParse(value ?? '');
                                  if (parsed == null || parsed <= 0) {
                                    return 'Geçerli bir sayı gir';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Çalışma saatlerini kullan'),
                                subtitle: const Text(
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
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _pickTime(isStart: true),
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Başlangıç Saati',
                                            prefixIcon: Icon(
                                              Icons.schedule_outlined,
                                            ),
                                          ),
                                          child: Text(
                                            _startTime == null
                                                ? '--:--'
                                                : '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _pickTime(isStart: false),
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            labelText: 'Bitiş Saati',
                                            prefixIcon: Icon(
                                              Icons.schedule_outlined,
                                            ),
                                          ),
                                          child: Text(
                                            _endTime == null
                                                ? '--:--'
                                                : '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
            label: Text(_isSaving ? 'Kaydediliyor...' : 'Kaydet'),
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
    );
  }
}
