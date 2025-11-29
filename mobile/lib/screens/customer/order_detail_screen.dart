import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/models/order_detail.dart';
import 'package:mobile/screens/customer/delivery_tracking_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:intl/intl.dart';

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

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending':
        return 'Beklemede';
      case 'Preparing':
        return 'Hazırlanıyor';
      case 'Ready':
        return 'Hazır';
      case 'Delivered':
        return 'Teslim Edildi';
      case 'Cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sipariş #${widget.orderId}'),
        actions: [
          if (_orderDetail != null &&
              (_orderDetail!.status == 'Preparing' ||
                  _orderDetail!.status == 'OnTheWay' ||
                  _orderDetail!.status == 'Delivered'))
            IconButton(
              icon: const Icon(Icons.location_on),
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
          ? const Center(child: Text('Sipariş bulunamadı'))
          : RefreshIndicator(
              onRefresh: _loadOrderDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Center(
                      child: Chip(
                        label: Text(
                          _getStatusText(_orderDetail!.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: _getStatusColor(_orderDetail!.status),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Order Info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _orderDetail!.vendorName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(_orderDetail!.createdAt)}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toplam: ₺${_orderDetail!.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Items
                    const Text(
                      'Ürünler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._orderDetail!.items.map(
                      (item) => Card(
                        child: ListTile(
                          leading: item.productImageUrl != null
                              ? Image.network(
                                  item.productImageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image, size: 50),
                          title: Text(item.productName),
                          subtitle: Text(
                            '${item.quantity} x ₺${item.unitPrice.toStringAsFixed(2)}',
                          ),
                          trailing: Text(
                            '₺${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status History
                    const Text(
                      'Durum Geçmişi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._orderDetail!.statusHistory.map(
                      (history) => Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.circle,
                            color: _getStatusColor(history.status),
                            size: 12,
                          ),
                          title: Text(_getStatusText(history.status)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat(
                                  'dd.MM.yyyy HH:mm',
                                ).format(history.createdAt),
                              ),
                              if (history.note != null) Text(history.note!),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cancel Button
                    if (_orderDetail!.status == 'Pending' ||
                        _orderDetail!.status == 'Preparing')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _cancelOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text('Siparişi İptal Et'),
                        ),
                      ),

                    // Cancelled Info
                    if (_orderDetail!.status == 'Cancelled' &&
                        _orderDetail!.cancelReason != null)
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'İptal Nedeni:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(_orderDetail!.cancelReason!),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
