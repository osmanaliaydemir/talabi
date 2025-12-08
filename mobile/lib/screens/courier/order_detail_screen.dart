import 'package:flutter/material.dart';

import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/courier_order.dart';
import 'package:mobile/models/currency.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/utils/currency_formatter.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

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

  Future<void> _showAcceptOrderConfirmation() async {
    final localizations = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations?.acceptOrderTitle ?? 'Accept Order'),
        content: Text(
          localizations?.acceptOrderConfirmation ??
              'Are you sure you want to accept this order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text(
              localizations?.acceptOrder ?? localizations?.accept ?? 'Accept',
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _acceptOrder();
    }
  }

  Future<void> _acceptOrder() async {
    print('OrderDetailScreen: Attempting to accept order ${widget.orderId}');
    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _courierService.acceptOrder(widget.orderId);
      if (success && mounted) {
        print('OrderDetailScreen: Order accepted successfully');
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations?.orderAccepted ?? 'Order accepted'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadOrderDetail();
      }
    } catch (e, stackTrace) {
      print('OrderDetailScreen: ERROR accepting order - $e');
      print(stackTrace);
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Failed to')
                  ? e.toString()
                  : (localizations?.failedToAcceptOrder ?? 'Error: $e'),
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

  Future<void> _showRejectOrderDialog() async {
    final localizations = AppLocalizations.of(context);
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          localizations?.rejectOrderTitle ??
              localizations?.rejectOrder ??
              'Reject Order',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations?.rejectReasonDescription ??
                    'Please enter the reason for rejecting this order (minimum 1 character):',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: localizations?.rejectReasonHint ?? 'Reason...',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return localizations?.rejectReasonDescription ??
                        'Reason is required (minimum 1 character)';
                  }
                  return null;
                },
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(localizations?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              localizations?.rejectOrder ?? localizations?.reject ?? 'Reject',
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim();
      await _rejectOrder(reason);
    }
  }

  Future<void> _rejectOrder(String reason) async {
    print('OrderDetailScreen: Attempting to reject order ${widget.orderId}');
    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _courierService.rejectOrder(widget.orderId, reason);
      if (success && mounted) {
        print('OrderDetailScreen: Order rejected successfully');
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations?.orderRejected ?? 'Order rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop(true); // Return to dashboard
      }
    } catch (e, stackTrace) {
      print('OrderDetailScreen: ERROR rejecting order - $e');
      print(stackTrace);
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Failed to')
                  ? e.toString()
                  : (localizations?.failedToRejectOrder ?? 'Error: $e'),
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

  Future<void> _pickupOrder() async {
    print('OrderDetailScreen: Attempting to pick up order ${widget.orderId}');
    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await _courierService.pickupOrder(widget.orderId);
      if (success && mounted) {
        print('OrderDetailScreen: Order picked up successfully');
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.orderPickedUpSuccessfully ??
                  'Order picked up successfully',
            ),
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
    final localizations = AppLocalizations.of(context);
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    if (_order == null) {
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
        title: Text(
          '${localizations?.orderDetail ?? 'Order'} #${_order!.customerOrderId.isNotEmpty ? _order!.customerOrderId : _order!.id}',
        ),
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
                        Text(
                          (localizations?.statusUpdated ?? 'Status')
                              .split(' ')
                              .first,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
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
                        Text(
                          localizations?.deliveryFee ?? 'Delivery Fee',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(
                            _order!.deliveryFee,
                            Currency.try_,
                          ),
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

            // OrderCourier Timeline
            if (_order!.courierStatus != null ||
                _order!.courierAssignedAt != null ||
                _order!.courierAcceptedAt != null ||
                _order!.pickedUpAt != null ||
                _order!.deliveredAt != null) ...[
              Text(
                'Timeline',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_order!.courierAssignedAt != null)
                        _buildTimelineItem(
                          icon: Icons.assignment,
                          iconColor: Colors.blue,
                          title: 'Assigned',
                          time: _order!.courierAssignedAt!,
                          isActive: _order!.courierStatus != null &&
                              (_order!.courierStatus ==
                                      OrderCourierStatus.assigned ||
                                  _order!.courierStatus ==
                                      OrderCourierStatus.accepted ||
                                  _order!.courierStatus ==
                                      OrderCourierStatus.pickedUp ||
                                  _order!.courierStatus ==
                                      OrderCourierStatus.outForDelivery ||
                                  _order!.courierStatus ==
                                      OrderCourierStatus.delivered),
                        ),
                      if (_order!.courierAcceptedAt != null)
                        _buildTimelineItem(
                          icon: Icons.check_circle,
                          iconColor: Colors.green,
                          title: 'Accepted',
                          time: _order!.courierAcceptedAt!,
                          isActive: _order!.courierStatus != null &&
                              (_order!.courierStatus ==
                                      OrderCourierStatus.accepted ||
                                  _order!.courierStatus ==
                                      OrderCourierStatus.pickedUp ||
                                  _order!.courierStatus ==
                                      OrderCourierStatus.outForDelivery ||
                                  _order!.courierStatus ==
                                      OrderCourierStatus.delivered),
                        ),
                      if (_order!.courierRejectedAt != null)
                        _buildTimelineItem(
                          icon: Icons.cancel,
                          iconColor: Colors.red,
                          title: 'Rejected',
                          subtitle: _order!.rejectReason,
                          time: _order!.courierRejectedAt!,
                          isActive: true,
                        ),
                      if (_order!.pickedUpAt != null)
                        _buildTimelineItem(
                          icon: Icons.shopping_bag,
                          iconColor: Colors.orange,
                          title: 'Picked Up',
                          time: _order!.pickedUpAt!,
                          isActive: _order!.courierStatus != null &&
                              (_order!.courierStatus ==
                                      OrderCourierStatus.pickedUp ||
                                  _order!.courierStatus ==
                                      OrderCourierStatus.outForDelivery ||
                                  _order!.courierStatus ==
                                      OrderCourierStatus.delivered),
                        ),
                      if (_order!.outForDeliveryAt != null)
                        _buildTimelineItem(
                          icon: Icons.local_shipping,
                          iconColor: Colors.purple,
                          title: 'Out for Delivery',
                          time: _order!.outForDeliveryAt!,
                          isActive: _order!.courierStatus != null &&
                              (_order!.courierStatus ==
                                      OrderCourierStatus.outForDelivery ||
                                  _order!.courierStatus ==
                                      OrderCourierStatus.delivered),
                        ),
                      if (_order!.deliveredAt != null)
                        _buildTimelineItem(
                          icon: Icons.done_all,
                          iconColor: Colors.green,
                          title: 'Delivered',
                          time: _order!.deliveredAt!,
                          isActive: true,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Courier Tip
            if (_order!.courierTip != null && _order!.courierTip! > 0) ...[
              Card(
                elevation: 2,
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.monetization_on,
                          color: Colors.green, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tip Received',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.format(
                                _order!.courierTip!,
                                Currency.try_,
                              ),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Vendor Information
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations?.pickupLocation ?? 'Pickup Location',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    print('OrderDetailScreen: View map tapped');
                    Navigator.of(
                      context,
                    ).pushNamed('/courier/order-map', arguments: _order!);
                  },
                  icon: const Icon(Icons.map, size: 18),
                  label: Text(localizations?.viewMap ?? 'View Map'),
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
            Text(
              localizations?.deliveryLocation ?? 'Delivery Location',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            Text(
              localizations?.orderItems ?? 'Order Items',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            if (_order!.status.toLowerCase() == 'assigned')
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing
                              ? null
                              : _showRejectOrderDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : Text(localizations?.reject ?? 'Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : _showAcceptOrderConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(localizations?.accept ?? 'Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            if (_order!.status.toLowerCase() == 'accepted') ...[
              const SizedBox(height: 12),
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
                  label: Text(
                    localizations?.markAsPickedUp ?? 'Mark as Picked Up',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
            if (_order!.status.toLowerCase() == 'outfordelivery') ...[
              const SizedBox(height: 12),
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
                  label: Text(
                    localizations?.markAsDelivered ?? 'Mark as Delivered',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required DateTime time,
    String? subtitle,
    required bool isActive,
  }) {
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} - ${time.day}/${time.month}/${time.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isActive ? iconColor : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? Colors.black87 : Colors.grey.shade600,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
