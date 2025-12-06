import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/models/address.dart';
import 'package:mobile/screens/customer/profile/address_picker_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/common/toast_message.dart';
import 'package:mobile/screens/customer/widgets/shared_header.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late TextEditingController _titleController;
  late TextEditingController _fullAddressController;
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _postalCodeController;
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.address?.title ?? '');
    _fullAddressController = TextEditingController(
      text: widget.address?.fullAddress ?? '',
    );
    _cityController = TextEditingController(text: widget.address?.city ?? '');
    _districtController = TextEditingController(
      text: widget.address?.district ?? '',
    );
    _postalCodeController = TextEditingController(
      text: widget.address?.postalCode ?? '',
    );
    _latitude = widget.address?.latitude;
    _longitude = widget.address?.longitude;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _fullAddressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'title': _titleController.text,
        'fullAddress': _fullAddressController.text,
        'city': _cityController.text,
        'district': _districtController.text,
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
                margin: EdgeInsets.all(AppTheme.spacingMedium),
                decoration: AppTheme.cardDecoration(withShadow: true),
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingLarge),
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
                        SizedBox(height: AppTheme.spacingXSmall),
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
                        SizedBox(height: AppTheme.spacingLarge),
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
                              prefixIcon: Icon(
                                Icons.label_outline,
                                color: AppTheme.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
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
                        SizedBox(height: AppTheme.spacingSmall),
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
                                            _cityController.text = city;
                                            _districtController.text = district;
                                            _postalCodeController.text =
                                                postalCode ?? '';
                                            _latitude = latitude;
                                            _longitude = longitude;
                                          });
                                        },
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.map,
                              size: AppTheme.iconSizeMedium,
                            ),
                            label: Text(localizations.selectAddressFromMap),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              padding: EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                                vertical: AppTheme.spacingMedium,
                              ),
                              side: BorderSide(color: AppTheme.borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSmall,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: AppTheme.spacingSmall),
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
                        // City Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _cityController,
                            decoration: InputDecoration(
                              hintText: localizations.city,
                              hintStyle: TextStyle(color: Colors.grey[500]),
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.cityRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // District Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _districtController,
                            decoration: InputDecoration(
                              hintText: localizations.district,
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(
                                Icons.place_outlined,
                                color: Colors.grey[600],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return localizations.districtRequired;
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
                            onPressed: _isLoading ? null : _saveAddress,
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
