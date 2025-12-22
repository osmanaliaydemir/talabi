import 'package:mobile/utils/custom_routes.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:mobile/services/api_service.dart';
//Todo: remove this import OAA
import 'package:mobile/features/profile/presentation/screens/customer/address_picker_screen.dart';
import 'package:mobile/features/dashboard/presentation/widgets/vendor_header.dart';

import 'package:mobile/features/dashboard/presentation/widgets/vendor_bottom_nav.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/l10n/app_localizations.dart';
// Added imports

class VendorEditProfileScreen extends StatefulWidget {
  const VendorEditProfileScreen({super.key, this.isOnboarding = false});
  final bool isOnboarding;

  @override
  State<VendorEditProfileScreen> createState() =>
      _VendorEditProfileScreenState();
}

class _VendorEditProfileScreenState extends State<VendorEditProfileScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;

  String? _imageUrl;
  File? _imageFile;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  // Location fields
  double? _latitude;
  double? _longitude;
  bool _isLocationSelected = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _phoneController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getVendorProfile();
      setState(() {
        _nameController.text = profile['name'] ?? '';
        _addressController.text = profile['address'] ?? '';
        _cityController.text = profile['city'] ?? '';
        _phoneController.text = profile['phoneNumber'] ?? '';
        _descriptionController.text = profile['description'] ?? '';
        _imageUrl = profile['imageUrl'];
        _latitude = profile['latitude'] != null
            ? (profile['latitude'] as num).toDouble()
            : null;
        _longitude = profile['longitude'] != null
            ? (profile['longitude'] as num).toDouble()
            : null;
        _isLocationSelected = _latitude != null && _longitude != null;

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (e is DioException && e.response?.statusCode == 404) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil bulunamadı, lütfen tekrar giriş yapın.'),
            ),
          );
          return;
        }

        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.profileLoadFailed(e.toString()) ??
                  'Profil yüklenemedi: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _isUploading = true;
        });

        final imageUrl = await _apiService.uploadProductImage(
          await MultipartFile.fromFile(pickedFile.path),
        );

        await _apiService.updateVendorImage(imageUrl);

        setState(() {
          _imageUrl = imageUrl;
          _isUploading = false;
        });

        if (mounted) {
          final localizations = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations?.logoUpdated ?? 'Logo güncellendi'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.logoUploadFailed(e.toString()) ??
                  'Logo yüklenemedi: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final data = {
        'name': _nameController.text,
        'address': _addressController.text,
        'city': _cityController.text.isEmpty ? null : _cityController.text,
        'phoneNumber': _phoneController.text.isEmpty
            ? null
            : _phoneController.text,
        'description': _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        'latitude': _latitude,
        'longitude': _longitude,
      };

      await _apiService.updateVendorProfile(data);

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.profileUpdated ?? 'Profil güncellendi',
            ),
          ),
        );

        if (widget.isOnboarding) {
          // Profile completed, skip Delivery Zones and go to dashboard/home
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/', // Or vendor dashboard route if different
            (route) => false,
          );
        } else {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      LoggerService().error('VendorEditProfileScreen: Error saving profile', e);
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.errorWithMessage(e.toString()) ?? 'Hata: $e',
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
      backgroundColor: Colors.white,
      appBar: VendorHeader(
        title: widget.isOnboarding
            ? 'Profili Tamamla'
            : (localizations?.editProfile ?? 'Profili Düzenle'),
        leadingIcon: Icons.edit_outlined,
        showBackButton: !widget.isOnboarding,
        onBack: () => Navigator.of(context).pop(),
        onRefresh: _loadProfile,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (widget.isOnboarding)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade800,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Satış yapmaya başlamadan önce lütfen işletme profilinizi ve adresinizi tamamlayın.',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Logo
                  Center(
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : _imageUrl != null
                                ? NetworkImage(_imageUrl!) as ImageProvider
                                : null,
                            child: _imageFile == null && _imageUrl == null
                                ? const Icon(Icons.store, size: 60)
                                : null,
                          ),
                          if (_isUploading)
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.deepPurple,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText:
                          '${localizations?.businessName ?? 'İşletme Adı'} *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.store),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations?.businessNameRequired ??
                            'İşletme adı gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Map Selection Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _isLocationSelected
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isLocationSelected ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        LoggerService().debug(
                          'VendorEditProfileScreen: Map selection tapped',
                        );
                        await Navigator.of(context).push(
                          NoSlidePageRoute(
                            builder: (context) => AddressPickerScreen(
                              onAddressSelected:
                                  (
                                    title,
                                    fullAddress,
                                    city,
                                    district,
                                    postalCode,
                                    latitude,
                                    longitude,
                                  ) {
                                    LoggerService().debug(
                                      'VendorEditProfileScreen: Address selected from map',
                                    );
                                    setState(() {
                                      _latitude = latitude;
                                      _longitude = longitude;
                                      _isLocationSelected = true;
                                      // Otomatik doldur ama manuel düzenlenebilir
                                      if (_addressController.text.isEmpty) {
                                        _addressController.text = fullAddress;
                                      }
                                      if (_cityController.text.isEmpty &&
                                          city.isNotEmpty) {
                                        _cityController.text = city;
                                      }
                                    });
                                  },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isLocationSelected
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        foregroundColor: _isLocationSelected
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: Icon(
                        _isLocationSelected
                            ? Icons.check_circle
                            : Icons.location_off,
                        color: _isLocationSelected
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      label: Text(
                        _isLocationSelected
                            ? (localizations?.locationSelectedChange ??
                                  'Konum Seçildi (Değiştir)')
                            : (localizations?.selectLocationFromMapRequired ??
                                  'Haritadan Konum Seç *'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  if (!_isLocationSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                      child: Text(
                        localizations?.locationSelectionRequired ??
                            'Haritadan konum seçimi zorunludur',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Address (Manual input - can be edited)
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText:
                          '${localizations?.fullAddress ?? 'Açık Adres'} *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                      helperText:
                          localizations?.addressAutoFillHint ??
                          'Haritadan seçilen adres otomatik doldurulur, manuel düzenleyebilirsiniz',
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations?.addressRequired ??
                            'Açık adres gerekli';
                      }
                      if (!_isLocationSelected) {
                        return localizations?.selectLocationFirst ??
                            'Önce haritadan konum seçmelisiniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // City
                  TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: localizations?.city ?? 'Şehir',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_city),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: '${localizations?.phoneNumber ?? 'Telefon'} *',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations?.phoneNumberRequired ??
                            'Telefon numarası gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: localizations?.description ?? 'Açıklama',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 24),

                  // Save button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
                        : Text(
                            localizations?.save ?? 'Kaydet',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: widget.isOnboarding
          ? null
          : const VendorBottomNav(currentIndex: 3),
    );
  }
}
