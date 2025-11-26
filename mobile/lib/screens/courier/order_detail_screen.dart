import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/courier_order.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/utils/currency_formatter.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final CourierService _courierService = CourierService();
  CourierOrder? _order;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    print('OrderDetailScreen: initState - OrderId: ${widget.orderId}');
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    print(
      'OrderDetailScreen: Loading order detail - OrderId: ${widget.orderId}',
    );
    setState(() {
      _isLoading = true;
    });

    try {
      final order = await _courierService.getOrderDetail(widget.orderId);
      print(
        'OrderDetailScreen: Order loaded - Status: ${order.status}, Vendor: ${order.vendorName}',
      );
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('OrderDetailScreen: ERROR loading order - $e');
      print(stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.failedToLoadOrderDetail ??
                  'Error loading order: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _pickupOrder() async {
    print('OrderDetailScreen: Attempting to pick up order ${widget.orderId}');
    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _courierService.pickupOrder(widget.orderId);
      if (success && mounted) {
        print('OrderDetailScreen: Order picked up successfully');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order picked up successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadOrderDetail();
      }
    } catch (e, stackTrace) {
      print('OrderDetailScreen: ERROR picking up order - $e');
      print(stackTrace);
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Failed to')
                  ? e.toString()
                  : (localizations?.failedToPickUpOrder ?? 'Error: $e'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _deliverOrder() async {
    print('OrderDetailScreen: Attempting to deliver order ${widget.orderId}');
    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _courierService.deliverOrder(widget.orderId);
      if (success && mounted) {
        print('OrderDetailScreen: Order delivered, navigating to proof screen');
        // Navigate to delivery proof screen
        final proofSubmitted = await Navigator.of(
          context,
        ).pushNamed('/courier/delivery-proof', arguments: widget.orderId);

        if (proofSubmitted == true && mounted) {
          print('OrderDetailScreen: Delivery proof submitted');
          final localizations = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                localizations?.orderDeliveredSuccessfully ??
                    'Order delivered successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return to dashboard
        } else if (mounted) {
          print('OrderDetailScreen: Order delivered without proof submission');
          // Proof not submitted, but order is delivered
          Navigator.of(context).pop(true);
        }
      }
    } catch (e, stackTrace) {
      print('OrderDetailScreen: ERROR delivering order - $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_order == null) {
      final localizations = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(
          title: Text(localizations?.orderDetail ?? 'Order Detail'),
        ),
        body: Center(
          child: Text(
            localizations?.failedToLoadOrderDetail ?? 'Order not found',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${_order!.id}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _order!.status,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Delivery Fee',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(_order!.deliveryFee, 'TRY'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Vendor Information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pickup Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    print('OrderDetailScreen: View map tapped');
                    Navigator.of(
                      context,
                    ).pushNamed('/courier/order-map', arguments: _order!);
                  },
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text('View Map'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.store, color: Colors.teal, size: 32),
                title: Text(_order!.vendorName),
                subtitle: Text(_order!.vendorAddress),
              ),
            ),
            const SizedBox(height: 24),

            // Customer Information
            const Text(
              'Delivery Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 32,
                ),
                title: Text(_order!.customerName),
                subtitle: Text(_order!.deliveryAddress),
              ),
            ),
            const SizedBox(height: 24),

            // Order Items
            const Text(
              'Order Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _order!.items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = _order!.items[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: Text(
                        '${item.quantity}x',
                        style: TextStyle(
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(item.productName),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            if (_order!.status == 'Accepted')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _pickupOrder,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: const Text('Mark as Picked Up'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            if (_order!.status == 'OutForDelivery') const SizedBox(height: 12),
            if (_order!.status == 'OutForDelivery')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _deliverOrder,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.done_all),
                  label: const Text('Mark as Delivered'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
