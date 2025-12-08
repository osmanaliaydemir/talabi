import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/vendor/widgets/header.dart';
import 'package:mobile/screens/vendor/widgets/bottom_nav.dart';

class VendorSettingsScreen extends StatefulWidget {
  const VendorSettingsScreen({super.key});

  @override
  State<VendorSettingsScreen> createState() => _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends State<VendorSettingsScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _minimumOrderController;
  late TextEditingController _deliveryFeeController;
  late TextEditingController _deliveryTimeController;

  bool _isActive = true;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    print('VendorSettingsScreen: initState');
    _minimumOrderController = TextEditingController();
    _deliveryFeeController = TextEditingController();
    _deliveryTimeController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _minimumOrderController.dispose();
    _deliveryFeeController.dispose();
    _deliveryTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    print('VendorSettingsScreen: Loading settings...');
    setState(() {
      _isLoading = true;
    });
    try {
      final settings = await _apiService.getVendorSettings();
      print('VendorSettingsScreen: Settings loaded successfully');
      setState(() {
        _minimumOrderController.text =
            settings['minimumOrderAmount']?.toString() ?? '';
        _deliveryFeeController.text = settings['deliveryFee']?.toString() ?? '';
        _deliveryTimeController.text =
            settings['estimatedDeliveryTime']?.toString() ?? '';
        _isActive = settings['isActive'] ?? true;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('VendorSettingsScreen: ERROR loading settings - $e');
      print(stackTrace);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.settingsLoadError(e.toString()) ??
                  'Ayarlar yüklenemedi: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      print('VendorSettingsScreen: Form validation failed');
      return;
    }

    print('VendorSettingsScreen: Saving settings...');
    setState(() {
      _isSaving = true;
    });

    try {
      final data = {
        'minimumOrderAmount': _minimumOrderController.text.isEmpty
            ? null
            : double.parse(_minimumOrderController.text),
        'deliveryFee': _deliveryFeeController.text.isEmpty
            ? null
            : double.parse(_deliveryFeeController.text),
        'estimatedDeliveryTime': _deliveryTimeController.text.isEmpty
            ? null
            : int.parse(_deliveryTimeController.text),
        'isActive': _isActive,
      };

      await _apiService.updateVendorSettings(data);
      print('VendorSettingsScreen: Settings saved successfully');

      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.settingsUpdated ?? 'Ayarlar güncellendi',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      print('VendorSettingsScreen: ERROR saving settings - $e');
      print(stackTrace);
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: VendorHeader(
        title: localizations?.businessSettings ?? 'İşletme Ayarları',
        leadingIcon: Icons.settings,
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
        onRefresh: _loadSettings,
        showNotifications: false,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.vendorPrimary),
            )
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: Form(
                key: _formKey,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  children: [
                    // Active status card
                    Container(
                      decoration: AppTheme.cardDecoration(),
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(
                              AppTheme.spacingSmall,
                            ),
                            decoration: BoxDecoration(
                              color: _isActive
                                  ? AppTheme.success.withOpacity(0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                            ),
                            child: Icon(
                              _isActive ? Icons.check_circle : Icons.cancel,
                              color: _isActive ? AppTheme.success : Colors.grey,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  localizations?.businessActive ??
                                      'İşletme Aktif',
                                  style: AppTheme.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isActive
                                      ? localizations
                                                ?.customersCanPlaceOrders ??
                                            'Müşteriler sipariş verebilir'
                                      : localizations?.orderTakingClosed ??
                                            'Sipariş alımı kapalı',
                                  style: AppTheme.poppins(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isActive,
                            onChanged: (value) {
                              print(
                                'VendorSettingsScreen: Active status changed to $value',
                              );
                              setState(() {
                                _isActive = value;
                              });
                            },
                            activeColor: AppTheme.success,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),

                    // Settings section title
                    Text(
                      localizations?.businessOperations ?? 'İşletme İşlemleri',
                      style: AppTheme.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),

                    // Minimum order amount
                    TextFormField(
                      controller: _minimumOrderController,
                      decoration: AppTheme.inputDecoration(
                        label:
                            localizations?.minimumOrderAmount ??
                            'Minimum Sipariş Tutarı',
                        hint: localizations?.optional ?? 'Opsiyonel',
                        prefixIcon: const Icon(Icons.attach_money),
                        fillColor: AppTheme.surfaceColor,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            double.tryParse(value) == null) {
                          return localizations?.enterValidAmount ??
                              'Geçerli bir tutar girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),

                    // Delivery fee
                    TextFormField(
                      controller: _deliveryFeeController,
                      decoration: AppTheme.inputDecoration(
                        label: localizations?.deliveryFee ?? 'Teslimat Ücreti',
                        hint: localizations?.optional ?? 'Opsiyonel',
                        prefixIcon: const Icon(Icons.delivery_dining),
                        fillColor: AppTheme.surfaceColor,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            double.tryParse(value) == null) {
                          return localizations?.enterValidAmount ??
                              'Geçerli bir tutar girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),

                    // Delivery time
                    TextFormField(
                      controller: _deliveryTimeController,
                      decoration: AppTheme.inputDecoration(
                        label:
                            localizations?.estimatedDeliveryTime ??
                            'Tahmini Teslimat Süresi (dakika)',
                        hint: localizations?.optional ?? 'Opsiyonel',
                        prefixIcon: const Icon(Icons.timer),
                        fillColor: AppTheme.surfaceColor,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null &&
                            value.isNotEmpty &&
                            int.tryParse(value) == null) {
                          return localizations?.enterValidTime ??
                              'Geçerli bir süre girin';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppTheme.spacingXLarge),

                    // Save button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
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
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 3),
    );
  }
}
