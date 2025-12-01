import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/models/order_detail.dart';
import 'package:mobile/screens/customer/delivery_tracking_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/widgets/common/toast_message.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_localizations.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sipariş yüklenemedi: $e')));
      }
    }
  }

  Future<void> _cancelOrder() async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Siparişi İptal Et'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('İptal nedeninizi belirtin (en az 10 karakter):'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'İptal nedeni',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('İptal nedeni en az 10 karakter olmalı'),
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('İptal Et', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      try {
        await _apiService.cancelOrder(widget.orderId, reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sipariş iptal edildi')));
          _loadOrderDetail(); // Reload to show updated status
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
        ToastMessage.show(
          context,
          message: 'Ürünler sepete eklendi, sepete yönlendiriliyorsunuz...',
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
        ToastMessage.show(
          context,
          message: 'Yeniden sipariş oluşturulamadı: $e',
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
        return 'Yolda'; // localizations.onWay;
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
        title: Text(
          'Sipariş #${widget.orderId}',
          style: AppTheme.poppins(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
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
              tooltip: 'Teslimat Takibi',
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
                'Sipariş bulunamadı',
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
                                    color: AppTheme.primaryOrange.withOpacity(
                                      0.1,
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
                                    ).withOpacity(0.1),
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
                            'Sipariş Detayı',
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
                                return Padding(
                                  padding: EdgeInsets.all(
                                    AppTheme.spacingMedium,
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSmall,
                                        ),
                                        child: item.productImageUrl != null
                                            ? Image.network(
                                                item.productImageUrl!,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 50,
                                                height: 50,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.image,
                                                  size: 30,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                      ),
                                      SizedBox(width: AppTheme.spacingMedium),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: AppTheme.poppins(
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            Text(
                                              '${item.quantity} adet',
                                              style: AppTheme.poppins(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₺${item.totalPrice.toStringAsFixed(2)}',
                                        style: AppTheme.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ],
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
                                      'Toplam Tutar',
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
                              'Sipariş Geçmişi',
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
                        color: Colors.black.withOpacity(0.05),
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
                                'Siparişi İptal Et',
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
                                'Yeniden Sipariş Ver',
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
