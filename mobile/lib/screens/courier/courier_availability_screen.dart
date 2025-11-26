import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/widgets/courier/courier_bottom_nav.dart';
import 'package:mobile/widgets/courier/courier_header.dart';

class CourierAvailabilityScreen extends StatefulWidget {
  const CourierAvailabilityScreen({super.key});

  @override
  State<CourierAvailabilityScreen> createState() =>
      _CourierAvailabilityScreenState();
}

class _CourierAvailabilityScreenState extends State<CourierAvailabilityScreen> {
  final CourierService _courierService = CourierService();
  bool _isLoading = true;
  String? _error;
  bool _isAvailable = false;
  String _status = '';
  int _currentActiveOrders = 0;
  int _maxActiveOrders = 0;
  List<String> _reasons = [];

  @override
  void initState() {
    super.initState();
    print('CourierAvailabilityScreen: initState');
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    print('CourierAvailabilityScreen: Loading availability...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _courierService.checkAvailability();
      if (!mounted) return;

      setState(() {
        _isAvailable =
            result['isAvailable'] == true ||
            result['IsAvailable'] == true; // API casing tolerance
        _status = (result['status'] ?? result['Status'] ?? '').toString();
        _currentActiveOrders =
            (result['currentActiveOrders'] ??
                    result['CurrentActiveOrders'] ??
                    0)
                as int;
        _maxActiveOrders =
            (result['maxActiveOrders'] ?? result['MaxActiveOrders'] ?? 0)
                as int;
        final reasons = result['reasons'] ?? result['Reasons'] ?? [];
        _reasons = (reasons as List).map((e) => e.toString()).toList();
        _isLoading = false;
      });

      print(
        'CourierAvailabilityScreen: isAvailable=$_isAvailable, status=$_status, current=$_currentActiveOrders, max=$_maxActiveOrders',
      );
    } catch (e, stackTrace) {
      print('CourierAvailabilityScreen: ERROR loading availability - $e');
      print(stackTrace);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: 'Müsaitlik Durumu',
        leadingIcon: Icons.radio_button_checked,
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
        onRefresh: _loadAvailability,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAvailability,
        child: _buildBody(localizations),
      ),
      bottomNavigationBar: const CourierBottomNav(currentIndex: 2),
    );
  }

  Widget _buildBody(AppLocalizations? localizations) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadAvailability,
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final statusText = _isAvailable ? 'Müsait' : 'Müsait Değil';
    final statusColor = _isAvailable ? Colors.green : Colors.red;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isAvailable
                            ? Icons.check_circle_outline
                            : Icons.error_outline,
                        color: statusColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sistem, yeni sipariş alabilme durumunu buradan kontrol eder.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(
                      label: 'Durum',
                      value: _status.isEmpty ? '-' : _status,
                    ),
                    _buildInfoChip(
                      label: 'Aktif Sipariş',
                      value: '$_currentActiveOrders / $_maxActiveOrders',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Müsaitlik Koşulları',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Aşağıdaki şartlar sağlandığında yeni sipariş atanabilir:',
          style: TextStyle(color: Colors.grey[700], fontSize: 13),
        ),
        const SizedBox(height: 12),
        _buildConditionRow(
          satisfied: _status == 'Available',
          text: 'Durumun "Available / Müsait" olmalı.',
        ),
        _buildConditionRow(
          satisfied: _currentActiveOrders < _maxActiveOrders,
          text:
              'Aktif sipariş sayın, maksimum limitin altında olmalı ($_currentActiveOrders / $_maxActiveOrders).',
        ),
        _buildConditionRow(
          satisfied: !_reasons.any(
            (r) =>
                r.toLowerCase().contains('not active') ||
                r.toLowerCase().contains('aktif değil'),
          ),
          text: 'Kurye hesabın aktif olmalı.',
        ),
        const SizedBox(height: 24),
        if (_reasons.isNotEmpty) ...[
          const Text(
            'Şu anda engelleyen nedenler',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._reasons.map(
            (reason) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Expanded(
                  child: Text(
                    reason,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ] else
          const Text(
            'Her şey yolunda görünüyor, yeni siparişler gelebilir.',
            style: TextStyle(color: Colors.green, fontSize: 14),
          ),
      ],
    );
  }

  Widget _buildInfoChip({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionRow({required bool satisfied, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            satisfied ? Icons.check_circle : Icons.radio_button_unchecked,
            color: satisfied ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: satisfied ? Colors.black : Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
