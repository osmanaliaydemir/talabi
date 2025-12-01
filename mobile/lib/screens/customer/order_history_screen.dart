import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/screens/customer/order_detail_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _apiService.getOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Siparişler yüklenemedi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          _buildHeader(context, localizations, colorScheme),
          // Main Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryOrange,
                    ),
                  )
                : _orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz siparişiniz yok',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.all(AppTheme.spacingMedium),
                    itemCount: _orders.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: AppTheme.spacingMedium),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _buildOrderCard(context, order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    final date = DateTime.parse(order['createdAt']);
    final status = order['status'] ?? 'Unknown';
    final statusColor = _getStatusColor(status);

    return Container(
      decoration: AppTheme.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailScreen(orderId: order['id']),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              children: [
                // Header: Vendor Info & Status
                Row(
                  children: [
                    // Vendor Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        color: AppTheme.primaryOrange,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Vendor Name & Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['vendorName'] ?? 'Unknown Vendor',
                            style: AppTheme.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(date),
                            style: AppTheme.poppins(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusSmall,
                        ),
                        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _getStatusText(context, status),
                        style: AppTheme.poppins(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppTheme.borderColor),
                ),
                // Footer: Order ID & Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '#${order['id']}',
                          style: AppTheme.poppins(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '₺${(order['totalAmount'] as num).toStringAsFixed(2)}',
                          style: AppTheme.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryOrange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'onway':
      case 'on_way':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BuildContext context, String status) {
    final localizations = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'pending':
        return localizations.pending;
      case 'preparing':
        return localizations.preparing;
      case 'ready':
        return localizations.ready;
      case 'onway':
      case 'on_way':
      case 'ontheway':
        return 'Yolda'; // localizations.onWay; // Key added but not generated yet
      case 'delivered':
        return localizations.delivered;
      case 'cancelled':
        return localizations.cancelled;
      default:
        return status;
    }
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations localizations,
    ColorScheme colorScheme,
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
              // Order Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Title and Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      localizations.myOrders,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_orders.length} ${localizations.orders}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
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
