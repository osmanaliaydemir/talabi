import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/address.dart';
import 'package:mobile/screens/shared/profile/address_picker_screen.dart';
import 'package:mobile/services/api_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.address == null ? 'Adres eklendi' : 'Adres güncellendi',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEdit = widget.address != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          _buildHeader(context, localizations, colorScheme, isEdit),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          isEdit ? 'Edit Address' : 'Add New Address',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isEdit
                              ? 'Update your address information'
                              : 'Enter your delivery address details',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Address Title Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: 'Address Title (Home, Work, etc.)',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              prefixIcon: Icon(
                                Icons.label_outline,
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
                                return 'Başlık gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Map Button
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddressPickerScreen(
                                    onAddressSelected: (
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
                                        _fullAddressController.text = fullAddress;
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
                            icon: const Icon(Icons.map),
                            label: const Text('Select Address from Map'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.grey[300]!),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Full Address Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _fullAddressController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Full Address',
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
                                return 'Adres gerekli';
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
                              hintText: 'City',
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
                                return 'Şehir gerekli';
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
                              hintText: 'District',
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
                                return 'İlçe gerekli';
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
                              hintText: 'Postal Code (Optional)',
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
                              backgroundColor: Colors.orange,
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
                                    isEdit ? 'Update Address' : 'Add Address',
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

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations localizations,
    ColorScheme colorScheme,
    bool isEdit,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade400,
            Colors.orange.shade600,
            Colors.orange.shade800,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              // Back Button
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 8),
              // Location Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isEdit ? 'Edit Address' : 'Add Address',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEdit
                          ? 'Update address details'
                          : 'Create new address',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
