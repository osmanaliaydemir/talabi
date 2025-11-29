import 'package:flutter/material.dart';

import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/providers/localization_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class VendorReportsScreen extends StatefulWidget {
  const VendorReportsScreen({super.key});

  @override
  State<VendorReportsScreen> createState() => _VendorReportsScreenState();
}

class _VendorReportsScreenState extends State<VendorReportsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _report;
  bool _isLoading = true;
  String _selectedPeriod = 'week';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final report = await _apiService.getSalesReport(
        startDate: _startDate,
        endDate: _endDate,
        period: _selectedPeriod,
      );
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Rapor yüklenemedi: $e')));
      }
    }
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final firstDate = now.subtract(const Duration(days: 365));
    final lastDate = now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'custom';
      });
      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Satış Raporları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
            tooltip: 'Tarih Aralığı Seç',
          ),
        ],
      ),
      body: Column(
        children: [
          // Period selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'day', label: Text('Günlük')),
                      ButtonSegment(value: 'week', label: Text('Haftalık')),
                      ButtonSegment(value: 'month', label: Text('Aylık')),
                    ],
                    selected: {_selectedPeriod},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedPeriod = newSelection.first;
                        _startDate = null;
                        _endDate = null;
                      });
                      _loadReport();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Report content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  )
                : _report == null
                ? const Center(child: Text('Rapor bulunamadı'))
                : RefreshIndicator(
                    onRefresh: _loadReport,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary cards
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  context,
                                  'Toplam Sipariş',
                                  '${_report!['totalOrders'] ?? 0}',
                                  Icons.receipt_long,
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  context,
                                  'Toplam Gelir',
                                  CurrencyFormatter.format(
                                    (_report!['totalRevenue'] ?? 0).toDouble(),
                                    localizationProvider.currency,
                                  ),
                                  Icons.attach_money,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  context,
                                  'Tamamlanan',
                                  '${_report!['completedOrders'] ?? 0}',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  context,
                                  'İptal Edilen',
                                  '${_report!['cancelledOrders'] ?? 0}',
                                  Icons.cancel,
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Date range
                          if (_startDate != null && _endDate != null)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(Icons.date_range),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Daily sales chart
                          if (_report!['dailySales'] != null &&
                              (_report!['dailySales'] as List).isNotEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Günlük Satışlar',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...(_report!['dailySales'] as List).map((
                                      daily,
                                    ) {
                                      final date = DateTime.parse(
                                        daily['date'],
                                      );
                                      final revenue = daily['revenue'] ?? 0;
                                      final orderCount =
                                          daily['orderCount'] ?? 0;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 100,
                                              child: Text(
                                                dateFormat.format(date),
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    CurrencyFormatter.format(
                                                      revenue.toDouble(),
                                                      localizationProvider
                                                          .currency,
                                                    ),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$orderCount sipariş',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Top products
                          if (_report!['topProducts'] != null &&
                              (_report!['topProducts'] as List).isNotEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'En Çok Satan Ürünler',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...(_report!['topProducts'] as List)
                                        .take(10)
                                        .map((product) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        product['productName'],
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${product['quantitySold']} adet satıldı',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  CurrencyFormatter.format(
                                                    (product['totalRevenue'] ??
                                                            0)
                                                        .toDouble(),
                                                    localizationProvider
                                                        .currency,
                                                  ),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
