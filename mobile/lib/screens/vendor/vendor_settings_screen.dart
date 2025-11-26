import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';

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
    try {
      final settings = await _apiService.getVendorSettings();
      setState(() {
        _minimumOrderController.text =
            settings['minimumOrderAmount']?.toString() ?? '';
        _deliveryFeeController.text = settings['deliveryFee']?.toString() ?? '';
        _deliveryTimeController.text =
            settings['estimatedDeliveryTime']?.toString() ?? '';
        _isActive = settings['isActive'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ayarlar yüklenemedi: $e')));
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

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

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ayarlar güncellendi')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Active status
                  Card(
                    child: SwitchListTile(
                      title: const Text('İşletme Aktif'),
                      subtitle: Text(
                        _isActive
                            ? 'Müşteriler sipariş verebilir'
                            : 'Sipariş alımı kapalı',
                      ),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Minimum order
                  TextFormField(
                    controller: _minimumOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Minimum Sipariş Tutarı',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                      hintText: 'Opsiyonel',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          double.tryParse(value) == null) {
                        return 'Geçerli bir tutar girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Delivery fee
                  TextFormField(
                    controller: _deliveryFeeController,
                    decoration: const InputDecoration(
                      labelText: 'Teslimat Ücreti',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.delivery_dining),
                      hintText: 'Opsiyonel',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          double.tryParse(value) == null) {
                        return 'Geçerli bir tutar girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Delivery time
                  TextFormField(
                    controller: _deliveryTimeController,
                    decoration: const InputDecoration(
                      labelText: 'Tahmini Teslimat Süresi (dakika)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                      hintText: 'Opsiyonel',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          int.tryParse(value) == null) {
                        return 'Geçerli bir süre girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
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
                        : const Text(
                            'Kaydet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
