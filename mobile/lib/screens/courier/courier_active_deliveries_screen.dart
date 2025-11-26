import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/courier_order.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/widgets/courier/courier_header.dart';
import 'package:mobile/widgets/courier/courier_bottom_nav.dart';

class CourierActiveDeliveriesScreen extends StatefulWidget {
  const CourierActiveDeliveriesScreen({super.key});

  @override
  State<CourierActiveDeliveriesScreen> createState() =>
      _CourierActiveDeliveriesScreenState();
}

class _CourierActiveDeliveriesScreenState
    extends State<CourierActiveDeliveriesScreen> {
  final CourierService _courierService = CourierService();
  bool _isLoading = true;
  String? _error;
  List<CourierOrder> _activeOrders = [];

  @override
  void initState() {
    super.initState();
    print('CourierActiveDeliveriesScreen: initState');
    _loadActiveOrders();
  }

  Future<void> _loadActiveOrders() async {
    print('CourierActiveDeliveriesScreen: Loading active orders...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await _courierService.getActiveOrders();
      if (!mounted) return;
      setState(() {
        _activeOrders = orders;
        _isLoading = false;
      });
      print(
        'CourierActiveDeliveriesScreen: Loaded ${orders.length} active orders',
      );
    } catch (e, stackTrace) {
      print('CourierActiveDeliveriesScreen: ERROR loading orders - $e');
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
        title: localizations?.activeDeliveries ?? 'Aktif Teslimatlar',
        leadingIcon: Icons.delivery_dining,
        showBackButton: true,
        showNotifications: true,
        onBack: () => Navigator.of(context).pop(),
        onRefresh: _loadActiveOrders,
      ),
      body: RefreshIndicator(
        onRefresh: _loadActiveOrders,
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadActiveOrders,
              child: const Text('Tekrar dene'),
            ),
          ],
        ),
      );
    }

    if (_activeOrders.isEmpty) {
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
              localizations?.noActiveDeliveries ?? 'No active deliveries',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _activeOrders.length,
      itemBuilder: (context, index) {
        final order = _activeOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(CourierOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          print(
            'CourierActiveDeliveriesScreen: Tapped order #${order.id}, navigating to detail',
          );
          final result = await Navigator.of(context).pushNamed(
            '/courier/order-detail',
            arguments: order.id,
          );
          if (result == true && mounted) {
            await _loadActiveOrders();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(order.deliveryFee, 'TRY'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Divider(),
              _buildLocationRow(
                icon: Icons.store,
                title: order.vendorName,
                subtitle: order.vendorAddress,
              ),
              const SizedBox(height: 8),
              _buildLocationRow(
                icon: Icons.location_on,
                iconColor: Colors.redAccent,
                title: order.customerName,
                subtitle: order.deliveryAddress,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Chip(
                    backgroundColor:
                        _statusColor(order.status).withOpacity(0.15),
                    label: Text(
                      order.status,
                      style: TextStyle(
                        color: _statusColor(order.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('HH:mm').format(order.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = Colors.teal,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'outfordelivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}


