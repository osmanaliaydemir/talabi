import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/widgets/courier/courier_header.dart';
import 'package:mobile/widgets/courier/courier_bottom_nav.dart';

class CourierDeliveryHistoryScreen extends StatefulWidget {
  const CourierDeliveryHistoryScreen({super.key});

  @override
  State<CourierDeliveryHistoryScreen> createState() =>
      _CourierDeliveryHistoryScreenState();
}

class _CourierDeliveryHistoryScreenState
    extends State<CourierDeliveryHistoryScreen> {
  final CourierService _courierService = CourierService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _orders = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    print('CourierDeliveryHistoryScreen: initState');
    _loadHistory(reset: true);
  }

  Future<void> _loadHistory({bool reset = false}) async {
    if (_isLoadingMore || (_hasMore == false && !reset)) return;

    setState(() {
      if (reset) {
        _isLoading = true;
        _orders = [];
        _currentPage = 1;
        _hasMore = true;
      } else {
        _isLoadingMore = true;
      }
      _error = null;
    });

    try {
      print(
        'CourierDeliveryHistoryScreen: Loading history page $_currentPage...',
      );
      final result =
          await _courierService.getOrderHistory(page: _currentPage, pageSize: 20);
      if (!mounted) return;

      final items = (result['items'] as List?) ?? [];
      setState(() {
        _orders.addAll(items);
        _isLoading = false;
        _isLoadingMore = false;
        _hasMore = items.length == 20;
        if (_hasMore) {
          _currentPage++;
        }
      });
      print(
        'CourierDeliveryHistoryScreen: Loaded ${items.length} items, total: ${_orders.length}',
      );
    } catch (e, stackTrace) {
      print('CourierDeliveryHistoryScreen: ERROR loading history - $e');
      print(stackTrace);
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: localizations?.deliveryHistory ?? 'Teslimat Geçmişi',
        leadingIcon: Icons.history,
        showBackButton: true,
        showNotifications: true,
        onBack: () => Navigator.of(context).pop(),
        onRefresh: () => _loadHistory(reset: true),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadHistory(reset: true),
        child: _buildBody(localizations),
      ),
      bottomNavigationBar: const CourierBottomNav(currentIndex: 0),
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
                  onPressed: () => _loadHistory(reset: true),
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              localizations?.noActiveDeliveries ?? 'Henüz teslimat geçmişi yok',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _orders.length) {
          // load more
          _loadHistory();
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final order = _orders[index] as Map<String, dynamic>;
        return _buildHistoryCard(order);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> order) {
    final status = (order['status'] ?? '').toString();
    final createdAt = DateTime.tryParse(order['createdAt']?.toString() ?? '');
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final deliveryFee = (order['deliveryFee'] as num?)?.toDouble() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  backgroundColor: _statusColor(status).withOpacity(0.15),
                  label: Text(
                    status,
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  createdAt != null
                      ? DateFormat('dd MMM yyyy HH:mm').format(createdAt)
                      : '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  CurrencyFormatter.format(total, 'TRY'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.delivery_dining,
                    size: 18, color: Colors.teal.shade700),
                const SizedBox(width: 4),
                Text(
                  CurrencyFormatter.format(deliveryFee, 'TRY'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'assigned':
      case 'accepted':
      case 'outfordelivery':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}


