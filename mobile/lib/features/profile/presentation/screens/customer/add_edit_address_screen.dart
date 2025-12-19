import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/features/profile/data/models/address.dart';
import 'package:mobile/features/profile/presentation/screens/customer/address_picker_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';

class AddEditAddressScreen extends StatefulWidget {
  const AddEditAddressScreen({super.key, this.address});

  final Address? address;

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late TextEditingController _titleController;
  late TextEditingController _fullAddressController;
  late TextEditingController _postalCodeController;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  bool _isLoadingLocations = false;

  // Location Data
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _localities = [];

  String? _selectedCountryId;
  String? _selectedCityId;
  String? _selectedDistrictId;
  String? _selectedLocalityId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.address?.title ?? '');
    _fullAddressController = TextEditingController(
      text: widget.address?.fullAddress ?? '',
    );
    _postalCodeController = TextEditingController(
      text: widget.address?.postalCode ?? '',
    );
    _latitude = widget.address?.latitude;
    _longitude = widget.address?.longitude;

    if (widget.address != null) {
      _selectedCityId = widget.address?.cityId;
      _selectedDistrictId = widget.address?.districtId;
      _selectedLocalityId = widget.address?.localityId;
      // Note: We don't have countryId in Address model yet, but usually we infer or load it.
      // For now, we will fetch countries and if there is only one (e.g. TR), select it.
      // If we had countryId in address, we would set it here.
    }

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingLocations = true);
    try {
      _countries = await _apiService.getCountries();

      // Auto-select first country if only one or none selected
      if (_countries.isNotEmpty && _selectedCountryId == null) {
        _selectedCountryId = _countries.first['id'].toString();
      }

      if (_selectedCountryId != null) {
        _cities = await _apiService.getLocationCities(_selectedCountryId!);
      }

      if (_selectedCityId != null) {
        _districts = await _apiService.getLocationDistricts(_selectedCityId!);
      }

      if (_selectedDistrictId != null) {
        _localities = await _apiService.getLocationLocalities(
          _selectedDistrictId!,
        );
      }
    } catch (e) {
      debugPrint('Error loading location data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  Future<void> _onCountryChanged(String? value) async {
    if (value == _selectedCountryId) return;
    setState(() {
      _selectedCountryId = value;
      _selectedCityId = null;
      _selectedDistrictId = null;
      _selectedLocalityId = null;
      _cities = [];
      _districts = [];
      _localities = [];
    });
    if (value != null) {
      final cities = await _apiService.getLocationCities(value);
      if (mounted) setState(() => _cities = cities);
    }
  }

  Future<void> _onCityChanged(String? value) async {
    if (value == _selectedCityId) return;
    setState(() {
      _selectedCityId = value;
      _selectedDistrictId = null;
      _selectedLocalityId = null;
      _districts = [];
      _localities = [];
    });
    if (value != null) {
      final districts = await _apiService.getLocationDistricts(value);
      if (mounted) setState(() => _districts = districts);
    }
  }

  Future<void> _onDistrictChanged(String? value) async {
    if (value == _selectedDistrictId) return;
    setState(() {
      _selectedDistrictId = value;
      _selectedLocalityId = null;
      _localities = [];
    });
    if (value != null) {
      final localities = await _apiService.getLocationLocalities(value);
      if (mounted) setState(() => _localities = localities);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fullAddressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      final l10n = AppLocalizations.of(context)!;
      ToastMessage.show(
        context,
        message: l10n
            .pleaseSelectLocation, // Use a localized message like "Please select a location from the map"
        isSuccess: false,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Find names for selected IDs
      // final cityName = _cities.firstWhere((c) => c['id'].toString() == _selectedCityId)['name'];
      // final districtName = _districts.firstWhere((d) => d['id'].toString() == _selectedDistrictId)['name'];

      final data = {
        'title': _titleController.text,
        'fullAddress': _fullAddressController.text,
        'cityId': _selectedCityId,
        'districtId': _selectedDistrictId,
        'localityId': _selectedLocalityId,
        'postalCode': _postalCodeController.text.isEmpty
            ? null
            : _postalCodeController.text,
        'latitude': _latitude,
        'longitude': _longitude,
      };

      if (widget.address == null) {
        await _apiService.createAddress(data);
      } else {
        await _apiService.updateAddress(widget.address!.id, data);
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: widget.address == null
              ? l10n.addressAdded
              : l10n.addressUpdated,
          isSuccess: true,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: '${l10n.error}: $e',
          isSuccess: false,
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isEdit = widget.address != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header
          SharedHeader(
            title: isEdit
                ? localizations.editAddress
                : localizations.addAddress,
            subtitle: isEdit
                ? localizations.updateAddressDetails
                : localizations.createNewAddress,
            icon: Icons.location_on,
            showBackButton: true,
          ),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: AppTheme.cardDecoration(withShadow: true),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          isEdit
                              ? localizations.editAddress
                              : localizations.addNewAddress,
                          style: AppTheme.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXSmall),
                        Text(
                          isEdit
                              ? localizations.updateAddressInfo
                              : localizations.enterDeliveryAddressDetails,
                          style: AppTheme.poppins(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLarge),
                        // Address Title Field
                        Container(
                          decoration: AppTheme.inputBoxDecoration(),
                          child: TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: localizations.addressTitleHint,
                              hintStyle: AppTheme.poppins(
                                color: AppTheme.textHint,
                              ),
                              prefixIcon: const Icon(
                                Icons.label_outline,
                                color: AppTheme.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                                vertical: AppTheme.spacingMedium,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.titleRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        // Map Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
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
                                          setState(() {
                                            _titleController.text = title;
                                            _fullAddressController.text =
                                                fullAddress;
                                            // Note: Map picker returns string names.
                                            // Mapping these to IDs is complex, so we just set fields.
                                            // User still needs to select via dropdowns for accuracy in this version.
                                            _postalCodeController.text =
                                                postalCode ?? '';
                                            _latitude = latitude;
                                            _longitude = longitude;
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                localizations
                                                    .selectCityDistrictWarning,
                                              ),
                                            ),
                                          );
                                        },
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.map,
                              size: AppTheme.iconSizeMedium,
                            ),
                            label: Text(localizations.selectAddressFromMap),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                                vertical: AppTheme.spacingMedium,
                              ),
                              side: const BorderSide(
                                color: AppTheme.borderColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSmall,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),

                        // Country Dropdown (Hidden if single country logic handled)
                        if (_countries.length > 1)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(
                                'country_${_selectedCountryId ?? "none"}',
                              ),
                              initialValue: _selectedCountryId,
                              decoration: InputDecoration(
                                hintText: localizations.selectCountry,
                                prefixIcon: Icon(
                                  Icons.flag_outlined,
                                  color: Colors.grey[600],
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              items: _countries
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c['id'].toString(),
                                      child: Text(c['name'] ?? ''),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _onCountryChanged,
                            ),
                          ),

                        // City Dropdown
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('city_${_selectedCityId ?? "none"}'),
                            initialValue: _selectedCityId,
                            decoration: InputDecoration(
                              hintText: localizations.city,
                              prefixIcon: Icon(
                                Icons.location_city_outlined,
                                color: Colors.grey[600],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items: _cities
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c['id'].toString(),
                                    child: Text(c['name'] ?? ''),
                                  ),
                                )
                                .toList(),
                            onChanged: _onCityChanged,
                            validator: (val) =>
                                val == null ? localizations.cityRequired : null,
                          ),
                        ),

                        // District Dropdown
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                              'district_${_selectedDistrictId ?? "none"}',
                            ),
                            initialValue: _selectedDistrictId,
                            decoration: InputDecoration(
                              hintText: localizations.district,
                              prefixIcon: Icon(
                                Icons.map_outlined,
                                color: Colors.grey[600],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items: _districts
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d['id'].toString(),
                                    child: Text(d['name'] ?? ''),
                                  ),
                                )
                                .toList(),
                            onChanged: _onDistrictChanged,
                            validator: (val) => val == null
                                ? localizations.districtRequired
                                : null,
                          ),
                        ),

                        // Locality Dropdown
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                              'locality_${_selectedLocalityId ?? "none"}',
                            ),
                            initialValue: _selectedLocalityId,
                            decoration: InputDecoration(
                              hintText: localizations.localityNeighborhood,
                              prefixIcon: Icon(
                                Icons.home_work_outlined,
                                color: Colors.grey[600],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items: _localities
                                .map(
                                  (l) => DropdownMenuItem(
                                    value: l['id'].toString(),
                                    child: Text(l['name'] ?? ''),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedLocalityId = val),
                            validator: (val) => val == null
                                ? localizations.addressRequired
                                : null,
                          ),
                        ),

                        // Full Address Field
                        Container(
                          decoration: AppTheme.inputBoxDecoration(),
                          child: TextFormField(
                            controller: _fullAddressController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: localizations.fullAddress,
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(bottom: 40),
                                child: Icon(
                                  Icons.home_outlined,
                                  color: Colors.grey[600],
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.addressRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Postal Code Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _postalCodeController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: localizations.postalCodeOptional,
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(
                                Icons.markunread_mailbox_outlined,
                                color: Colors.grey[600],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isLoading || _isLoadingLocations)
                                ? null
                                : _saveAddress,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    isEdit
                                        ? localizations.updateAddressButton
                                        : localizations.addAddress,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
