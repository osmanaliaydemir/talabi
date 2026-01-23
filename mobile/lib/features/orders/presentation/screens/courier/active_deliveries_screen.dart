import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/orders/data/models/courier_order.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/features/dashboard/presentation/widgets/courier_header.dart';
import 'package:mobile/features/dashboard/presentation/widgets/courier_bottom_nav.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/services/signalr_service.dart';
import 'package:mobile/config/injection.dart';
import 'dart:async';

class CourierActiveDeliveriesScreen extends StatefulWidget {
  const CourierActiveDeliveriesScreen({super.key, this.initialTabIndex});

  final int? initialTabIndex;

  @override
  State<CourierActiveDeliveriesScreen> createState() =>
      _CourierActiveDeliveriesScreenState();
}

class _CourierActiveDeliveriesScreenState
    extends State<CourierActiveDeliveriesScreen>
    with SingleTickerProviderStateMixin {
  final CourierService _courierService = CourierService();
  late TabController _tabController;

  // Active Deliveries Tab
  bool _isLoadingActive = true;
  String? _errorActive;
  // Offers and Deliveries
  List<CourierOrder> _pendingOffers = [];
  List<CourierOrder> _ongoingDeliveries = [];

  // Delivery History Tab
  bool _isLoadingHistory = true;
  String? _errorHistory;
  List<dynamic> _historyOrders = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  final NotificationService _notificationService = NotificationService();
  StreamSubscription<String>? _orderAssignedSubscription;
  StreamSubscription<Map<String, dynamic>>? _signalRSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0,
    );
    _tabController.addListener(_onTabChanged);

    // Subscribe to FCM notifications for real-time updates
    _orderAssignedSubscription = _notificationService.orderAssignedStream.listen((
      orderId,
    ) {
      // Refresh active orders tab if we are on it, or just in background to keep data fresh
      _loadActiveOrders();
    });

    // Subscribe to SignalR order assignment stream for real-time updates
    _signalRSubscription = getIt<SignalRService>().onOrderAssigned.listen((
      data,
    ) {
      if (data.containsKey('orderId')) {
        _loadActiveOrders();
      }
    });

    // İlk yükleme
    if (widget.initialTabIndex == 1) {
      _loadHistory(reset: true);
    } else {
      _loadActiveOrders();
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // Tab değiştiğinde ilgili tab'ın verilerini yeniden yükle
      if (_tabController.index == 0) {
        _loadActiveOrders();
      } else if (_tabController.index == 1) {
        _loadHistory(reset: true);
      }
    }
  }

  @override
  void dispose() {
    _orderAssignedSubscription?.cancel();
    _signalRSubscription?.cancel();
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadActiveOrders() async {
    setState(() {
      _isLoadingActive = true;
      _errorActive = null;
    });

    try {
      final orders = await _courierService.getActiveOrders();
      if (!mounted) return;

      // Split orders into pending offers (Assigned) and ongoing deliveries (Accepted+)
      final offers = <CourierOrder>[];
      final ongoing = <CourierOrder>[];

      for (final order in orders) {
        // If the order is explicitly assigned (enum or string) or hasn't been accepted yet, treat it as an offer
        if (order.courierStatus == OrderCourierStatus.assigned ||
            order.status.toLowerCase() == 'assigned' ||
            order.courierAcceptedAt == null) {
          offers.add(order);
        } else {
          ongoing.add(order);
        }
      }

      setState(() {
        _pendingOffers = offers;
        _ongoingDeliveries = ongoing;
        _isLoadingActive = false;
      });
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierActiveDeliveriesScreen: ERROR loading orders',
        e,
        stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _errorActive = e.toString();
        _isLoadingActive = false;
      });
    }
  }

  Future<void> _loadHistory({bool reset = false}) async {
    if (_isLoadingMore || (_hasMore == false && !reset)) return;

    setState(() {
      if (reset) {
        _isLoadingHistory = true;
        _historyOrders = [];
        _currentPage = 1;
        _hasMore = true;
      } else {
        _isLoadingMore = true;
      }
      _errorHistory = null;
    });

    try {
      final result = await _courierService.getOrderHistory(
        page: _currentPage,
        pageSize: 20,
      );
      if (!mounted) return;

      final items = (result['items'] as List?) ?? [];
      setState(() {
        _historyOrders.addAll(items);
        _isLoadingHistory = false;
        _isLoadingMore = false;
        _hasMore = items.length == 20;
        if (_hasMore) {
          _currentPage++;
        }
      });
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierActiveDeliveriesScreen: ERROR loading history',
        e,
        stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _errorHistory = e.toString();
        _isLoadingHistory = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _acceptOrder(CourierOrder order) async {
    final localizations = AppLocalizations.of(context);
    final orderAccepted =
        localizations?.orderAccepted ?? 'Sipariş kabul edildi';

    try {
      await _courierService.acceptOrder(order.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(orderAccepted), backgroundColor: Colors.green),
        );
        _loadActiveOrders();
      }
    } catch (e) {
      if (mounted) {
        final errorMessage =
            localizations?.errorWithMessage(e.toString()) ?? 'Hata: $e';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  Future<void> _rejectOrder(CourierOrder order) async {
    final reasonController = TextEditingController();
    final localizations = AppLocalizations.of(context);
    final rejectTitle = localizations?.rejectOrderTitle ?? 'Siparişi Reddet';
    final rejectReasonLabel =
        localizations?.rejectReasonLabel ??
        'Lütfen reddetme sebebini belirtin:';
    final rejectReasonHint = localizations?.rejectReasonHint ?? 'Sebep...';
    final cancel = localizations?.cancel ?? 'İptal';
    final reject = localizations?.reject ?? 'Reddet';
    final pleaseEnterReason =
        localizations?.pleaseEnterReason ?? 'Lütfen bir sebep girin';
    final orderRejected = localizations?.orderRejected ?? 'Sipariş reddedildi';

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rejectTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rejectReasonLabel),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: rejectReasonHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(pleaseEnterReason)));
                return;
              }
              Navigator.pop(context, reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(reject),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        await _courierService.rejectOrder(order.id, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(orderRejected),
              backgroundColor: Colors.orange,
            ),
          );
          _loadActiveOrders();
        }
      } catch (e) {
        if (mounted) {
          final errorMessage =
              localizations?.errorWithMessage(e.toString()) ?? 'Hata: $e';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: localizations?.deliveries ?? 'Teslimatlar',
        leadingIcon: Icons.local_shipping_outlined,
        showBackButton: false,
        showNotifications: true,
        onRefresh: () {
          if (_tabController.index == 0) {
            _loadActiveOrders();
          } else {
            _loadHistory(reset: true);
          }
        },
      ),
      body: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.teal,
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(
                  text: localizations?.activeDeliveries ?? 'Aktif Teslimatlar',
                ),
                Tab(text: localizations?.deliveryHistory ?? 'Teslimat Geçmişi'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveDeliveriesTab(localizations),
                _buildDeliveryHistoryTab(localizations),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CourierBottomNav(currentIndex: 1),
    );
  }

  Widget _buildActiveDeliveriesTab(AppLocalizations? localizations) {
    if (_isLoadingActive) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (_errorActive != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorActive!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadActiveOrders,
              child: Text(localizations?.tryAgain ?? 'Tekrar dene'),
            ),
          ],
        ),
      );
    }

    if (_pendingOffers.isEmpty && _ongoingDeliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              localizations?.noActiveDeliveries ?? 'Aktif teslimat yok',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // New Offers Section
          if (_pendingOffers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                localizations?.newOffers ?? 'YENİ TEKLİFLER',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            ..._pendingOffers.map(_buildOfferCard),
            const SizedBox(height: 24),
          ],

          // Active Deliveries Section
          if (_ongoingDeliveries.isNotEmpty) ...[
            if (_pendingOffers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  localizations?.activeDeliveriesSectionTitle ??
                      'AKTİF TESLİMATLAR',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ..._ongoingDeliveries.map(_buildOrderCard),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryHistoryTab(AppLocalizations? localizations) {
    return RefreshIndicator(
      onRefresh: () => _loadHistory(reset: true),
      child: _isLoadingHistory
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _errorHistory != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Text(
                        _errorHistory!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _loadHistory(reset: true),
                        child: Text(localizations?.tryAgain ?? 'Tekrar dene'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : _historyOrders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 40),
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    localizations?.noDeliveryHistoryYet ??
                        'Henüz teslimat geçmişi yok',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _historyOrders.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _historyOrders.length) {
                  // load more
                  _loadHistory();
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.teal),
                    ),
                  );
                }

                final order = _historyOrders[index] as Map<String, dynamic>;
                return _buildHistoryCard(order);
              },
            ),
    );
  }

  Widget _buildOfferCard(CourierOrder order) {
    final localizations = AppLocalizations.of(context);
    final newOrderOfferMsg =
        localizations?.newOrderOffer ?? 'Yeni Sipariş Teklifi!';
    final rejectMsg = localizations?.reject ?? 'Reddet';
    final acceptMsg = localizations?.accept ?? 'Kabul Et';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade200, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.new_releases, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newOrderOfferMsg,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  CurrencyFormatter.format(
                    (order.deliveryFee).toDouble(),
                    Currency.try_,
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.green,
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
              // Show full address if accepted, otherwise generic
              subtitle: order.deliveryAddress,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectOrder(order),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(rejectMsg),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(acceptMsg),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(CourierOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(
            context,
          ).pushNamed('/courier/order-detail', arguments: order.id);
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
                    order.customerOrderId.isNotEmpty
                        ? 'Order #${order.customerOrderId}'
                        : 'Order #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(
                          order.deliveryFee,
                          Currency.try_,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          fontSize: 16,
                        ),
                      ),
                    ],
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
                    backgroundColor: _statusColor(
                      order.status,
                    ).withValues(alpha: 0.15),
                    label: Text(
                      order.status,
                      style: TextStyle(
                        color: _statusColor(order.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (order.courierStatus != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      backgroundColor: _courierStatusColor(
                        order.courierStatus!,
                      ).withValues(alpha: 0.15),
                      label: Text(
                        _courierStatusLabel(order.courierStatus!),
                        style: TextStyle(
                          color: _courierStatusColor(order.courierStatus!),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    DateFormat('HH:mm').format(order.createdAt),
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> order) {
    final status = (order['status'] ?? '').toString();
    final createdAt = DateTime.tryParse(order['createdAt']?.toString() ?? '');
    final totalAmount = (order['totalAmount'] as num?)?.toDouble() ?? 0;
    final total = totalAmount > 0
        ? totalAmount
        : ((order['total'] as num?)?.toDouble() ?? 0);
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
                  (order['customerOrderId']?.toString() ?? '').isNotEmpty
                      ? 'Order #${order['customerOrderId']}'
                      : 'Order #${order['id']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  backgroundColor: _statusColor(status).withValues(alpha: 0.15),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(total, Currency.try_),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(deliveryFee, Currency.try_),
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.green.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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
        return AppTheme.primaryOrange;
      case 'accepted':
        return Colors.blue;
      case 'outfordelivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _courierStatusColor(OrderCourierStatus status) {
    switch (status) {
      case OrderCourierStatus.assigned:
        return Colors.blue;
      case OrderCourierStatus.accepted:
        return Colors.green;
      case OrderCourierStatus.rejected:
        return Colors.red;
      case OrderCourierStatus.pickedUp:
        return Colors.orange;
      case OrderCourierStatus.outForDelivery:
        return Colors.purple;
      case OrderCourierStatus.delivered:
        return Colors.green.shade700;
    }
  }

  String _courierStatusLabel(OrderCourierStatus status) {
    final localizations = AppLocalizations.of(context);
    // Basic localization, ideally should be in ARB
    switch (status) {
      case OrderCourierStatus.assigned:
        return localizations?.statusAssigned ?? 'Atandı';
      case OrderCourierStatus.accepted:
        return localizations?.statusAccepted ?? 'Kabul Edildi';
      case OrderCourierStatus.rejected:
        return localizations?.statusRejected ?? 'Reddedildi';
      case OrderCourierStatus.pickedUp:
        return localizations?.statusPickedUp ?? 'Teslim Alındı';
      case OrderCourierStatus.outForDelivery:
        return localizations?.statusOutForDelivery ?? 'Yolda';
      case OrderCourierStatus.delivered:
        return localizations?.statusDelivered ?? 'Teslim Edildi';
    }
  }
}
