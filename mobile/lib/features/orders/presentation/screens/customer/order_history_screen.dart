import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/orders/presentation/screens/customer/order_detail_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';

import 'package:mobile/widgets/empty_state_widget.dart';
import 'package:get_it/get_it.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({
    super.key,
    this.showBackButton = true,
    ApiService? apiService,
  }) : _apiService = apiService;

  final bool showBackButton;
  final ApiService? _apiService;

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final ApiService _apiService;
  List<dynamic> _orders = [];
  bool _isLoading = true;
  int? _selectedVendorType;

  @override
  void initState() {
    super.initState();
    _apiService = widget._apiService ?? GetIt.instance<ApiService>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bottomNavProvider = Provider.of<BottomNavProvider>(context);
    final newType = bottomNavProvider.selectedCategory == MainCategory.market
        ? 2
        : 1;

    if (_selectedVendorType != newType) {
      _selectedVendorType = newType;
      _loadOrders();
    }
  }

  Future<void> _loadOrders({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final orders = await _apiService.getOrders(
        vendorType: _selectedVendorType ?? 1,
      );
      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: l10n.ordersLoadFailed(e.toString()),
          isSuccess: false,
        );
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
          SharedHeader(
            title: localizations.myOrders,
            subtitle: '${_orders.length} ${localizations.orders}',
            icon: Icons.shopping_bag,
            showBackButton: widget.showBackButton,
          ),

          // Main Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadOrders(isRefresh: true),
              color: colorScheme.primary,
              child: _isLoading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _orders.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 60),
                        EmptyStateWidget(
                          message: localizations.noOrdersYet,
                          subMessage: localizations.orderEmptySubMessage,
                          iconData: Icons.shopping_bag_outlined,
                          actionLabel: localizations.startShopping,
                          onAction: () {
                            Provider.of<BottomNavProvider>(
                              context,
                              listen: false,
                            ).setIndex(0);
                          },
                          isCompact: true,
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      itemCount: _orders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppTheme.spacingMedium),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return _buildOrderCard(context, order);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, dynamic order) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateTime.parse(order['createdAt']);
    final status = order['status'] ?? l10n.unknown;
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
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              children: [
                // Header: Vendor Info & Status
                Row(
                  children: [
                    // Vendor Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        color: Theme.of(context).colorScheme.primary,
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
                            order['vendorName'] ?? l10n.unknownVendor,
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
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.2),
                        ),
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: AppTheme.borderColor),
                ),
                // Footer: Order ID & Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '#${order['customerOrderId'] ?? order['id']}',
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
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
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
        return localizations.onWay;
      case 'delivered':
        return localizations.delivered;
      case 'cancelled':
        return localizations.cancelled;
      default:
        return status;
    }
  }
}
