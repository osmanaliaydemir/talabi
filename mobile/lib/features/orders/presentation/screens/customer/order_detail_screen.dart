import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/features/orders/data/models/order_detail.dart';
import 'package:mobile/features/orders/presentation/screens/customer/delivery_tracking_screen.dart';

import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';
import 'package:mobile/features/reviews/presentation/screens/order_feedback_screen.dart';
import 'package:provider/provider.dart';

import 'package:mobile/features/orders/presentation/providers/order_detail_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderDetailProvider>().loadOrderDetail(widget.orderId);
    });
  }

  Future<void> _cancelOrder() async {
    final reasonController = TextEditingController();

    final localizations = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CustomConfirmationDialog(
            title: localizations.cancelOrder,
            message: '',
            confirmText: localizations.cancelOrder,
            cancelText: localizations.cancel,
            icon: Icons.cancel_outlined,
            iconColor: Colors.red,
            confirmButtonColor: Colors.red,
            isConfirmEnabled: reasonController.text.length >= 10,
            onConfirm: () => Navigator.pop(context, true),
            onCancel: () => Navigator.pop(context, false),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizations.cancelReasonDescription),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: localizations.cancelReason,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                  onChanged: (value) => setState(() {}),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty && mounted) {
      try {
        await context.read<OrderDetailProvider>().cancelOrder(
          widget.orderId,
          reasonController.text,
        );
        if (mounted) {
          final localizations = AppLocalizations.of(context)!;
          ToastMessage.show(
            context,
            message: localizations.orderCancelled,
            isSuccess: true,
          );
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
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CustomConfirmationDialog(
            title: localizations.cancelItem,
            message: '',
            confirmText: localizations.cancelItem,
            cancelText: localizations.cancel,
            icon: Icons.remove_shopping_cart_outlined,
            iconColor: Colors.red,
            confirmButtonColor: Colors.red,
            isConfirmEnabled: reasonController.text.length >= 10,
            onConfirm: () => Navigator.pop(context, true),
            onCancel: () => Navigator.pop(context, false),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${localizations.cancelReasonDescription}\n\n${item.productName}',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: localizations.cancelReason,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                  onChanged: (value) => setState(() {}),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty && mounted) {
      try {
        await context.read<OrderDetailProvider>().cancelOrderItem(
          widget.orderId,
          item,
          reasonController.text,
        );
        if (mounted) {
          ToastMessage.show(
            context,
            message: localizations.itemCancelSuccess,
            isSuccess: true,
          );
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

  Color _getStatusColor(String status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'Pending':
        return colorScheme.primary;
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
    final provider = context.read<OrderDetailProvider>();
    final order = provider.orderDetail;
    if (order == null) return;

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      // We pass the cart provider to the order provider to handle logic, or do it here.
      // Since reorder logic involves CartProvider, and OrderDetailProvider is for OrderDetail,
      // it's cleaner to keep simple logic here or move all to provider.
      // The implementation plan said "reorder(OrderDetail order, CartProvider cartProvider)".
      // Let's use the provider method.

      await provider.reorder(order, cart, context);

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.productsAddedToCart,
          isSuccess: true,
        );

        // Navigate to Cart
        Provider.of<BottomNavProvider>(
          context,
          listen: false,
        ).setIndex(2); // Index 2 is CartScreen

        // Pop back to MainNavigationScreen to show the updated tab
        Navigator.of(context).popUntil((route) => route.isFirst);
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

  String _getStatusText(String status) {
    final localizations = AppLocalizations.of(context)!;
    switch (status) {
      case 'Pending':
        return localizations.pending;
      case 'Allowed':
      case 'Accepted':
        return localizations.accepted;
      case 'Preparing':
        return localizations.preparing;
      case 'Ready':
        return localizations.ready;
      case 'OutForDelivery':
      case 'OnTheWay':
      case 'OnWay':
        return localizations
            .onWay; // Or localizations.outForDelivery if you prefer specific
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
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Consume Provider
    final provider = context.watch<OrderDetailProvider>();
    final orderDetail = provider.orderDetail;
    final reviewStatus = provider.reviewStatus;
    final isLoading = provider.isLoading;

    final customerOrderId = orderDetail?.customerOrderId;
    final title = (customerOrderId != null && customerOrderId.isNotEmpty)
        ? '${localizations.orderDetail} #$customerOrderId'
        : localizations.orderDetail;

    Widget? action;
    if (orderDetail != null &&
        (orderDetail.status == 'Preparing' ||
            orderDetail.status == 'OnTheWay' ||
            orderDetail.status == 'Delivered')) {
      action = GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DeliveryTrackingScreen(orderId: widget.orderId),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.map, color: Colors.white, size: 20),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          SharedHeader(
            title: title,
            subtitle: orderDetail?.vendorName,
            icon: Icons.receipt_long,
            showBackButton: true,
            action: action,
          ),
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  )
                : orderDetail == null
                ? Center(
                    child: Text(
                      localizations.orderNotFound,
                      style: AppTheme.poppins(color: AppTheme.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => provider.loadOrderDetail(widget.orderId),
                    color: colorScheme.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Vendor Card
                          Container(
                            padding: const EdgeInsets.all(
                              AppTheme.spacingMedium,
                            ),
                            decoration: AppTheme.cardDecoration(),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.store,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingMedium),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        orderDetail.vendorName,
                                        style: AppTheme.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy, HH:mm',
                                        ).format(orderDetail.createdAt),
                                        style: AppTheme.poppins(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      orderDetail.status,
                                      context,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getStatusColor(
                                        orderDetail.status,
                                        context,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _getStatusText(orderDetail.status),
                                    style: AppTheme.poppins(
                                      color: _getStatusColor(
                                        orderDetail.status,
                                        context,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMedium),

                          // Products List
                          Text(
                            AppLocalizations.of(context)!.orderDetail,
                            style: AppTheme.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingSmall),
                          Container(
                            decoration: AppTheme.cardDecoration(),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: orderDetail.items.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(
                                    height: 1,
                                    color: AppTheme.borderColor,
                                  ),
                              itemBuilder: (context, index) {
                                final item = orderDetail.items[index];
                                final localizations = AppLocalizations.of(
                                  context,
                                )!;
                                final canCancelItem =
                                    !item.isCancelled &&
                                    (orderDetail.status == 'Pending' ||
                                        orderDetail.status == 'Preparing') &&
                                    orderDetail.items.length > 1;

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
                                    padding: const EdgeInsets.all(
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
                                                  ? item.isCancelled
                                                        ? ColorFiltered(
                                                            colorFilter:
                                                                const ColorFilter.mode(
                                                                  Colors.grey,
                                                                  BlendMode
                                                                      .saturation,
                                                                ),
                                                            child: OptimizedCachedImage.productThumbnail(
                                                              imageUrl: item
                                                                  .productImageUrl!,
                                                              width: 50,
                                                              height: 50,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .zero,
                                                            ),
                                                          )
                                                        : OptimizedCachedImage.productThumbnail(
                                                            imageUrl: item
                                                                .productImageUrl!,
                                                            width: 50,
                                                            height: 50,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .zero,
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
                                            const SizedBox(
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
                                                      if (item.selectedOptions !=
                                                              null &&
                                                          item
                                                              .selectedOptions!
                                                              .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          item.selectedOptions!
                                                              .map(
                                                                (o) =>
                                                                    "${o['groupName']}: ${o['valueName']}",
                                                              )
                                                              .join(', '),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ],
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
                          const SizedBox(height: AppTheme.spacingMedium),

                          // Payment Summary
                          Container(
                            padding: const EdgeInsets.all(
                              AppTheme.spacingMedium,
                            ),
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
                                      '₺${orderDetail.totalAmount.toStringAsFixed(2)}',
                                      style: AppTheme.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingMedium),

                          // Status History Timeline
                          if (orderDetail.statusHistory.isNotEmpty) ...[
                            Text(
                              AppLocalizations.of(context)!.orderHistory,
                              style: AppTheme.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingSmall),
                            Container(
                              padding: const EdgeInsets.all(
                                AppTheme.spacingMedium,
                              ),
                              decoration: AppTheme.cardDecoration(),
                              child: Column(
                                children: orderDetail.statusHistory
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final index = entry.key;
                                      final history = entry.value;
                                      final isLast =
                                          index ==
                                          orderDetail.statusHistory.length - 1;
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
                                                    context,
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
                                          const SizedBox(
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
                                                  const SizedBox(
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
                          const SizedBox(
                            height: 100,
                          ), // Bottom padding for button
                        ],
                      ),
                    ),
                  ),
          ),
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: 4,
            ),
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
                  if (orderDetail != null &&
                      (orderDetail.status == 'Pending' ||
                          orderDetail.status == 'Preparing'))
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _cancelOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                  if (orderDetail != null && orderDetail.status == 'Delivered')
                    Column(
                      children: [
                        Builder(
                          builder: (context) {
                            bool isFullyReviewed = false;
                            if (reviewStatus != null) {
                              final isVR =
                                  reviewStatus['isVendorReviewed'] as bool? ??
                                  false;
                              final hasC =
                                  reviewStatus['hasCourier'] as bool? ?? false;
                              final isCR =
                                  reviewStatus['isCourierRated'] as bool? ??
                                  false;
                              isFullyReviewed = isVR && (!hasC || isCR);
                            }

                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderFeedbackScreen(
                                        orderDetail: orderDetail,
                                        reviewStatus: reviewStatus,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    // Refresh order detail
                                    provider.loadOrderDetail(widget.orderId);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isFullyReviewed
                                      ? Colors.grey
                                      : Colors.amber,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isFullyReviewed
                                          ? Icons.rate_review
                                          : Icons.star,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isFullyReviewed
                                          ? 'Değerlendirmemi Gör'
                                          : 'Siparişi Değerlendir',
                                      style: AppTheme.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8), // Gap between buttons
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _reorder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
