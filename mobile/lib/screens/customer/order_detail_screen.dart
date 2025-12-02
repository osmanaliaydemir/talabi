import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/models/order_detail.dart';
import 'package:mobile/screens/customer/delivery_tracking_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/common/toast_message.dart';
import 'package:provider/provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final ApiService _apiService = ApiService();
  OrderDetail? _orderDetail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    try {
      final data = await _apiService.getOrderDetailFull(widget.orderId);
      setState(() {
        _orderDetail = OrderDetail.fromJson(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.failedToLoadOrderDetail,
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _cancelOrder() async {
    final reasonController = TextEditingController();

    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.cancelOrder),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(localizations.cancelReasonDescription),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: localizations.cancelReason,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.length < 10) {
                ToastMessage.show(
                  context,
                  message: localizations.cancelReasonDescription,
                  isSuccess: false,
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text(
              localizations.cancelOrder,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
        await _apiService.cancelOrder(widget.orderId, reasonController.text);
        if (mounted) {
          final localizations = AppLocalizations.of(context)!;
          ToastMessage.show(
            context,
            message: localizations.orderCancelled,
            isSuccess: true,
          );
          _loadOrderDetail(); // Reload to show updated status
        }
      } catch (e) {
        if (mounted) {
          final localizations = AppLocalizations.of(context)!;
          ToastMessage.show(
            context,
            message: localizations.errorWithMessage(e.toString()),
            isSuccess: false,
          );
        }
      }
    }
  }

  Future<void> _cancelOrderItem(OrderItemDetail item) async {
    if (item.isCancelled) {
      return; // Already cancelled
    }

    final reasonController = TextEditingController();
    final localizations = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.cancelItem),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${localizations.cancelReasonDescription}\n\n${item.productName}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: localizations.cancelReason,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.length < 10) {
                ToastMessage.show(
                  context,
                  message: localizations.cancelReasonDescription,
                  isSuccess: false,
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: Text(
              localizations.cancelItem,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
        await _apiService.cancelOrderItem(
          item.customerOrderItemId,
          reasonController.text,
        );
        if (mounted) {
          ToastMessage.show(
            context,
            message: localizations.itemCancelSuccess,
            isSuccess: true,
          );
          _loadOrderDetail(); // Reload to show updated status
        }
      } catch (e) {
        if (mounted) {
          ToastMessage.show(
            context,
            message: localizations.itemCancelFailed(e.toString()),
            isSuccess: false,
          );
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppTheme.primaryOrange;
      case 'Preparing':
        return Colors.blue;
      case 'Ready':
        return Colors.green;
      case 'Delivered':
        return Colors.green.shade800;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _reorder() async {
    setState(() => _isLoading = true);
    try {
      final cart = Provider.of<CartProvider>(context, listen: false);

      for (var item in _orderDetail!.items) {
        final product = Product(
          id: item.productId,
          vendorId: _orderDetail!.vendorId,
          vendorName: _orderDetail!.vendorName,
          name: item.productName,
          price: item.unitPrice,
          imageUrl: item.productImageUrl,
          description: '',
          isAvailable: true,
        );

        // Add item quantity times (since addItem adds 1)
        for (int i = 0; i < item.quantity; i++) {
          await cart.addItem(product, context);
        }
      }

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.productsAddedToCart,
          isSuccess: true,
        );

        // Navigate to Cart
        final bottomNav = Provider.of<BottomNavProvider>(
          context,
          listen: false,
        );
        bottomNav.setIndex(2); // Index 2 is CartScreen

        // Pop back to MainNavigationScreen to show the updated tab
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.reorderFailed(e.toString()),
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getStatusText(String status) {
    final localizations = AppLocalizations.of(context)!;
    switch (status) {
      case 'Pending':
        return localizations.pending;
      case 'Preparing':
        return localizations.preparing;
      case 'Ready':
        return localizations.ready;
      case 'OnTheWay':
      case 'OnWay':
        return localizations.onWay;
      case 'Delivered':
        return localizations.delivered;
      case 'Cancelled':
        return localizations.cancelled;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Builder(
          builder: (context) {
            final localizations = AppLocalizations.of(context)!;
            // Only show CustomerOrderId, not GUID
            final orderId = _orderDetail?.customerOrderId.isNotEmpty == true
                ? _orderDetail!.customerOrderId
                : null;
            return Text(
              orderId != null
                  ? '${localizations.orderDetail} #$orderId'
                  : localizations.orderDetail,
              style: AppTheme.poppins(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        actions: [
          if (_orderDetail != null &&
              (_orderDetail!.status == 'Preparing' ||
                  _orderDetail!.status == 'OnTheWay' ||
                  _orderDetail!.status == 'Delivered'))
            IconButton(
              icon: Icon(Icons.map, color: AppTheme.primaryOrange),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DeliveryTrackingScreen(orderId: widget.orderId),
                  ),
                );
              },
              tooltip: AppLocalizations.of(context)!.deliveryTracking,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryOrange),
            )
          : _orderDetail == null
          ? Center(
              child: Text(
                AppLocalizations.of(context)!.orderNotFound,
                style: AppTheme.poppins(color: AppTheme.textSecondary),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadOrderDetail,
                    color: AppTheme.primaryOrange,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(AppTheme.spacingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vendor Card
                          Container(
                            padding: EdgeInsets.all(AppTheme.spacingMedium),
                            decoration: AppTheme.cardDecoration(),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.store,
                                    color: AppTheme.primaryOrange,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: AppTheme.spacingMedium),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _orderDetail!.vendorName,
                                        style: AppTheme.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy, HH:mm',
                                        ).format(_orderDetail!.createdAt),
                                        style: AppTheme.poppins(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      _orderDetail!.status,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getStatusColor(
                                        _orderDetail!.status,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _getStatusText(_orderDetail!.status),
                                    style: AppTheme.poppins(
                                      color: _getStatusColor(
                                        _orderDetail!.status,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingMedium),

                          // Products List
                          Text(
                            AppLocalizations.of(context)!.orderDetail,
                            style: AppTheme.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingSmall),
                          Container(
                            decoration: AppTheme.cardDecoration(),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _orderDetail!.items.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 1,
                                color: AppTheme.borderColor,
                              ),
                              itemBuilder: (context, index) {
                                final item = _orderDetail!.items[index];
                                final localizations = AppLocalizations.of(
                                  context,
                                )!;
                                final canCancelItem =
                                    !item.isCancelled &&
                                    (_orderDetail!.status == 'Pending' ||
                                        _orderDetail!.status == 'Preparing') &&
                                    _orderDetail!.items.length > 1;

                                return Container(
                                  decoration: item.isCancelled
                                      ? BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusSmall,
                                          ),
                                          border: Border.all(
                                            color: Colors.red.shade200,
                                            width: 1,
                                          ),
                                        )
                                      : null,
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      AppTheme.spacingMedium,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusSmall,
                                                  ),
                                              child:
                                                  item.productImageUrl != null
                                                  ? Image.network(
                                                      item.productImageUrl!,
                                                      width: 50,
                                                      height: 50,
                                                      fit: BoxFit.cover,
                                                      color: item.isCancelled
                                                          ? Colors.grey
                                                          : null,
                                                      colorBlendMode:
                                                          item.isCancelled
                                                          ? BlendMode.saturation
                                                          : null,
                                                    )
                                                  : Container(
                                                      width: 50,
                                                      height: 50,
                                                      color: Colors.grey[200],
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 30,
                                                        color: item.isCancelled
                                                            ? Colors.grey[400]
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                            ),
                                            SizedBox(
                                              width: AppTheme.spacingMedium,
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          item.productName,
                                                          style: AppTheme.poppins(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                item.isCancelled
                                                                ? Colors
                                                                      .grey[600]
                                                                : AppTheme
                                                                      .textPrimary,
                                                            decoration:
                                                                item.isCancelled
                                                                ? TextDecoration
                                                                      .lineThrough
                                                                : null,
                                                          ),
                                                        ),
                                                      ),
                                                      if (item.isCancelled)
                                                        Container(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 4,
                                                              ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.red,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          child: Text(
                                                            localizations
                                                                .itemCancelled,
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        '${item.quantity} ${localizations.pieces}',
                                                        style: AppTheme.poppins(
                                                          fontSize: 12,
                                                          color:
                                                              item.isCancelled
                                                              ? Colors.grey[500]
                                                              : AppTheme
                                                                    .textSecondary,
                                                        ),
                                                      ),
                                                      if (item
                                                          .customerOrderItemId
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          '• #${item.customerOrderItemId}',
                                                          style: AppTheme.poppins(
                                                            fontSize: 12,
                                                            color:
                                                                item.isCancelled
                                                                ? Colors
                                                                      .grey[500]
                                                                : AppTheme
                                                                      .textSecondary,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  if (item.isCancelled &&
                                                      item.cancelReason !=
                                                          null) ...[
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${localizations.cancelReason}: ${item.cancelReason}',
                                                      style: AppTheme.poppins(
                                                        fontSize: 11,
                                                        color: Colors.red[700],
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '₺${item.totalPrice.toStringAsFixed(2)}',
                                              style: AppTheme.poppins(
                                                fontWeight: FontWeight.bold,
                                                color: item.isCancelled
                                                    ? Colors.grey[500]
                                                    : AppTheme.textPrimary,
                                                decoration: item.isCancelled
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (canCancelItem) ...[
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _cancelOrderItem(item),
                                              icon: const Icon(
                                                Icons.cancel,
                                                size: 16,
                                              ),
                                              label: Text(
                                                localizations.cancelItem,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(
                                                  color: Colors.red,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingMedium),

                          // Payment Summary
                          Container(
                            padding: EdgeInsets.all(AppTheme.spacingMedium),
                            decoration: AppTheme.cardDecoration(),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.cartTotalAmountLabel,
                                      style: AppTheme.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '₺${_orderDetail!.totalAmount.toStringAsFixed(2)}',
                                      style: AppTheme.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryOrange,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: AppTheme.spacingMedium),

                          // Status History Timeline
                          if (_orderDetail!.statusHistory.isNotEmpty) ...[
                            Text(
                              AppLocalizations.of(context)!.orderHistory,
                              style: AppTheme.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: AppTheme.spacingSmall),
                            Container(
                              padding: EdgeInsets.all(AppTheme.spacingMedium),
                              decoration: AppTheme.cardDecoration(),
                              child: Column(
                                children: _orderDetail!.statusHistory
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final index = entry.key;
                                      final history = entry.value;
                                      final isLast =
                                          index ==
                                          _orderDetail!.statusHistory.length -
                                              1;
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            children: [
                                              Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(
                                                    history.status,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              if (!isLast)
                                                Container(
                                                  width: 2,
                                                  height: 40,
                                                  color: Colors.grey[300],
                                                ),
                                            ],
                                          ),
                                          SizedBox(
                                            width: AppTheme.spacingMedium,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _getStatusText(
                                                    history.status,
                                                  ),
                                                  style: AppTheme.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  DateFormat(
                                                    'dd.MM.yyyy HH:mm',
                                                  ).format(history.createdAt),
                                                  style: AppTheme.poppins(
                                                    fontSize: 12,
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                ),
                                                if (history.note != null)
                                                  Text(
                                                    history.note!,
                                                    style: AppTheme.poppins(
                                                      fontSize: 12,
                                                      color: AppTheme
                                                          .textSecondary,
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                if (!isLast)
                                                  SizedBox(
                                                    height:
                                                        AppTheme.spacingMedium,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    })
                                    .toList(),
                              ),
                            ),
                          ],
                          SizedBox(height: 100), // Bottom padding for button
                        ],
                      ),
                    ),
                  ),
                ),
                // Bottom Action Bar
                Container(
                  padding: EdgeInsets.all(AppTheme.spacingMedium),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_orderDetail!.status == 'Pending' ||
                            _orderDetail!.status == 'Preparing')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _cancelOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.error,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.cancelOrder,
                                style: AppTheme.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        if (_orderDetail!.status == 'Delivered')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _reorder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(context)!.reorder,
                                style: AppTheme.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
