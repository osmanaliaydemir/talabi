import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/screens/customer/widgets/shared_header.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final Map<String, dynamic> profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _imageUrlController;
  DateTime? _dateOfBirth;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile['fullName']);
    _phoneController = TextEditingController(
      text: widget.profile['phoneNumber'] ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.profile['profileImageUrl'] ?? '',
    );
    if (widget.profile['dateOfBirth'] != null) {
      _dateOfBirth = DateTime.parse(widget.profile['dateOfBirth']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.updateProfile({
        'fullName': _nameController.text,
        'phoneNumber': _phoneController.text.isEmpty
            ? null
            : _phoneController.text,
        'profileImageUrl': _imageUrlController.text.isEmpty
            ? null
            : _imageUrlController.text,
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
      });

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: l10n.profileUpdated,
          isSuccess: true,
        );
        Navigator.pop(context, true); // Return true to indicate update
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          // Header
          SharedHeader(
            title: localizations.editProfile,
            subtitle: widget.profile['fullName'] ?? localizations.user,
            icon: Icons.person,
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
                          localizations.editProfile,
                          style: AppTheme.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXSmall),
                        Text(
                          localizations.updatePersonalInfo,
                          style: AppTheme.poppins(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLarge),
                        // Full Name Field
                        Container(
                          decoration: AppTheme.inputBoxDecoration(),
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              hintText: localizations.fullName,
                              hintStyle: AppTheme.poppins(
                                color: AppTheme.textHint,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_outline,
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
                                return localizations.fullNameRequired;
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        // Phone Field
                        Container(
                          decoration: AppTheme.inputBoxDecoration(),
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: localizations.phoneNumber,
                              hintStyle: AppTheme.poppins(
                                color: AppTheme.textHint,
                              ),
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: AppTheme.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                                vertical: AppTheme.spacingMedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMedium),
                        // Profile Image URL Field
                        Container(
                          decoration: AppTheme.inputBoxDecoration(),
                          child: TextFormField(
                            controller: _imageUrlController,
                            decoration: InputDecoration(
                              hintText: localizations.profileImageUrl,
                              hintStyle: AppTheme.poppins(
                                color: AppTheme.textHint,
                              ),
                              prefixIcon: const Icon(
                                Icons.image_outlined,
                                color: AppTheme.textSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingMedium,
                                vertical: AppTheme.spacingMedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSmall),
                        // Date of Birth Field
                        GestureDetector(
                          onTap: _selectDate,
                          child: Container(
                            decoration: AppTheme.inputBoxDecoration(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingMedium,
                              vertical: AppTheme.spacingMedium,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: AppTheme.spacingMedium),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localizations.dateOfBirth,
                                        style: AppTheme.poppins(
                                          color: AppTheme.textHint,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _dateOfBirth != null
                                            ? DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(_dateOfBirth!)
                                            : localizations.notSelected,
                                        style: AppTheme.poppins(
                                          color: _dateOfBirth != null
                                              ? AppTheme.textPrimary
                                              : AppTheme.textHint,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: AppTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLarge),
                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: AppTheme.textOnPrimary,
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.spacingMedium,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSmall,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: AppTheme.textOnPrimary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    localizations.save,
                                    style: AppTheme.poppins(
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
