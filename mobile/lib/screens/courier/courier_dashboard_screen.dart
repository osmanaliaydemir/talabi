import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/courier.dart';
import 'package:mobile/models/courier_order.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/services/location_service.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/widgets/courier/courier_header.dart';
import 'package:mobile/widgets/courier/courier_bottom_nav.dart';
import 'package:provider/provider.dart';

class CourierDashboardScreen extends StatefulWidget {
  const CourierDashboardScreen({super.key});

  @override
  State<CourierDashboardScreen> createState() => _CourierDashboardScreenState();
}

class _CourierDashboardScreenState extends State<CourierDashboardScreen> {
  final CourierService _courierService = CourierService();
  final NotificationService _notificationService = NotificationService();
  late final LocationService _locationService;
  Courier? _courier;
  CourierStatistics? _statistics;
  List<CourierOrder> _activeOrders = [];
  bool _isLoading = true;
  bool _isStatusUpdating = false;
  final Set<int> _processingOrders = {};

  @override
  void initState() {
    super.initState();
    print('CourierDashboardScreen: initState called');
    _locationService = LocationService(_courierService);
    _loadData();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    await _notificationService.init();
    _notificationService.onOrderAssigned = (orderId) {
      // Reload data when new order is assigned
      _loadData();
      // Show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New order #$orderId assigned!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    _notificationService.stop();
    _locationService.stopLocationTracking();
    super.dispose();
  }

  Future<void> _loadData() async {
    print('CourierDashboardScreen: Loading data...');
    setState(() {
      _isLoading = true;
    });

    try {
      print('CourierDashboardScreen: Fetching profile...');
      final courier = await _courierService.getProfile();
      print(
        'CourierDashboardScreen: Profile loaded - ${courier.name}, Status: ${courier.status}',
      );

      // Start location tracking if courier is available
      if (courier.status == 'Available') {
        print(
          'CourierDashboardScreen: Courier is available, starting location tracking...',
        );
        await _locationService.startLocationTracking();
      } else {
        print(
          'CourierDashboardScreen: Courier is ${courier.status}, stopping location tracking...',
        );
        _locationService.stopLocationTracking();
      }

      print('CourierDashboardScreen: Fetching statistics...');
      final statistics = await _courierService.getStatistics();
      print(
        'CourierDashboardScreen: Statistics loaded - Total: ${statistics.totalDeliveries}, Earnings: ${statistics.totalEarnings}',
      );

      print('CourierDashboardScreen: Fetching active orders...');
      final orders = await _courierService.getActiveOrders();
      print(
        'CourierDashboardScreen: Active orders loaded - Count: ${orders.length}',
      );

      if (mounted) {
        setState(() {
          _courier = courier;
          _statistics = statistics;
          _activeOrders = orders;
          _isLoading = false;
        });
        print('CourierDashboardScreen: Data loaded successfully');
      }
    } catch (e, stackTrace) {
      print('CourierDashboardScreen: ERROR loading data - $e');
      print(stackTrace);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Failed to')
                  ? e.toString()
                  : (localizations?.failedToLoadActiveOrders ??
                        'Error loading data: $e'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleStatus(bool value) async {
    if (_courier == null) {
      print('CourierDashboardScreen: Cannot toggle status - courier is null');
      return;
    }

    final newStatus = value ? 'Available' : 'Offline';
    print('CourierDashboardScreen: Toggling status to $newStatus');
    setState(() {
      _isStatusUpdating = true;
    });

    try {
      await _courierService.updateStatus(newStatus);
      print(
        'CourierDashboardScreen: Status updated successfully to $newStatus',
      );

      // Handle location tracking based on new status
      if (value) {
        print('CourierDashboardScreen: Starting location tracking...');
        await _locationService.startLocationTracking();
      } else {
        print('CourierDashboardScreen: Stopping location tracking...');
        _locationService.stopLocationTracking();
      }

      await _loadData(); // Reload to get updated profile
    } catch (e, stackTrace) {
      print('CourierDashboardScreen: ERROR updating status - $e');
      print(stackTrace);
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Failed to')
                  ? e.toString()
                  : (localizations?.failedToUpdateStatus ??
                        'Error updating status: $e'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStatusUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CourierHeader(
          title: localizations?.roleCourier ?? 'Kurye Paneli',
          subtitle: authProvider.email ?? '',
        ),
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
        bottomNavigationBar: const CourierBottomNav(currentIndex: 0),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: localizations?.roleCourier ?? 'Kurye Paneli',
        subtitle: authProvider.email ?? '',
        onRefresh: _loadData,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card (like vendor)
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        size: 48,
                        color: Colors.teal.shade700,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations?.courierWelcome ??
                                  'Welcome Back, Courier!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _courier?.name ??
                                  authProvider.fullName ??
                                  authProvider.email ??
                                  '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
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
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(localizations?.statusUpdated ?? "Status").split(' ').first}:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getLocalizedStatus(_courier?.status ?? "Offline"),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(
                                _courier?.status ?? "Offline",
                              ),
                            ),
                          ),
                        ],
                      ),
                      _isStatusUpdating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.teal,
                              ),
                            )
                          : Switch(
                              value:
                                  _courier?.status == 'Available' ||
                                  _courier?.status == 'Busy' ||
                                  _courier?.status == 'Assigned',
                              activeColor: Colors.teal,
                              onChanged: (value) {
                                if (_courier?.status == 'Busy' ||
                                    _courier?.status == 'Assigned') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Cannot change status while busy',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                _toggleStatus(value);
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Stats cards (like vendor)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.history,
                      title:
                          localizations?.deliveryHistory ?? 'Delivery History',
                      value: _statistics?.todayDeliveries.toString() ?? '0',
                      subtitle: 'Today',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.attach_money,
                      title: localizations?.earnings ?? 'Earnings',
                      value: CurrencyFormatter.format(
                        _statistics?.todayEarnings ?? 0,
                        'TRY',
                      ),
                      subtitle: 'Today',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.star,
                      title: 'Rating',
                      value:
                          _statistics?.averageRating.toStringAsFixed(1) ??
                          '0.0',
                      subtitle: '(${_statistics?.totalRatings ?? 0} reviews)',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.local_shipping,
                      title: 'Total',
                      value: _statistics?.totalDeliveries.toString() ?? '0',
                      subtitle: 'All time',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Quick Actions (like vendor)
              Text(
                'Hızlı İşlemler',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildActionCard(
                    context,
                    localizations?.activeDeliveries ?? 'Active Deliveries',
                    Icons.delivery_dining,
                    Colors.teal,
                    () {
                      print(
                        'CourierDashboardScreen: Quick Action -> Active Deliveries',
                      );
                      Navigator.of(
                        context,
                      ).pushNamed('/courier/active-deliveries');
                    },
                  ),
                  _buildActionCard(
                    context,
                    localizations?.earnings ?? 'Earnings',
                    Icons.attach_money,
                    Colors.green,
                    () {
                      Navigator.of(context).pushNamed('/courier/earnings');
                    },
                  ),
                  _buildActionCard(
                    context,
                    localizations?.profile ?? 'Profile',
                    Icons.person,
                    Colors.blue,
                    () {
                      Navigator.of(context).pushNamed('/courier/profile');
                    },
                  ),
                  _buildActionCard(
                    context,
                    localizations?.deliveryHistory ?? 'Delivery History',
                    Icons.history,
                    Colors.purple,
                    () {
                      print(
                        'CourierDashboardScreen: Quick Action -> Delivery History',
                      );
                      Navigator.of(
                        context,
                      ).pushNamed('/courier/active-deliveries', arguments: 1);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Active Deliveries Section
              Text(
                localizations?.activeDeliveries ?? 'Active Deliveries',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // TODO: Fetch real active orders
              _activeOrders.isEmpty
                  ? Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localizations?.noActiveDeliveries ??
                                    'No active deliveries',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _activeOrders.length,
                      itemBuilder: (context, index) {
                        final order = _activeOrders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.of(context)
                                  .pushNamed(
                                    '/courier/order-detail',
                                    arguments: order.id,
                                  );
                              if (result == true) {
                                _loadData(); // Reload if order was completed
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Order #${order.id}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(
                                          order.deliveryFee,
                                          'TRY',
                                        ),
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
                                        backgroundColor: _statusColor(
                                          order.status,
                                        ).withOpacity(0.15),
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
                                        DateFormat(
                                          'HH:mm',
                                        ).format(order.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildOrderActions(order),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CourierBottomNav(currentIndex: 0),
    );
  }

  String _getLocalizedStatus(String status) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'tr') {
      switch (status) {
        case 'Available':
          return 'Müsait';
        case 'Offline':
          return 'Çevrimdışı';
        case 'Busy':
          return 'Meşgul';
        case 'Break':
          return 'Mola';
        case 'Assigned':
          return 'Atandı';
        default:
          return status;
      }
    } else if (locale.languageCode == 'ar') {
      switch (status) {
        case 'Available':
          return 'متاح';
        case 'Offline':
          return 'غير متصل';
        case 'Busy':
          return 'مشغول';
        case 'Break':
          return 'استراحة';
        case 'Assigned':
          return 'معين';
        default:
          return status;
      }
    } else {
      // English
      return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Busy':
      case 'Assigned':
        return Colors.orange;
      case 'Break':
        return Colors.blue;
      case 'Offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
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

  Widget _buildOrderActions(CourierOrder order) {
    final status = order.status.toLowerCase();
    final isProcessing = _processingOrders.contains(order.id);

    switch (status) {
      case 'assigned':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isProcessing
                    ? null
                    : () => _performOrderAction(
                        orderId: order.id,
                        action: () => _courierService.rejectOrder(order.id),
                        successMessage: 'Order rejected',
                      ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.teal,
                        ),
                      )
                    : const Text('Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () => _performOrderAction(
                        orderId: order.id,
                        action: () => _courierService.acceptOrder(order.id),
                        successMessage: 'Order accepted',
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Accept'),
              ),
            ),
          ],
        );
      case 'accepted':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isProcessing
                ? null
                : () => _performOrderAction(
                    orderId: order.id,
                    action: () => _courierService.pickupOrder(order.id),
                    successMessage: 'Order marked as picked up',
                  ),
            icon: isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.inventory_2_outlined),
            label: const Text('Mark as Picked Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        );
      case 'outfordelivery':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isProcessing
                ? null
                : () => _performOrderAction(
                    orderId: order.id,
                    action: () => _courierService.deliverOrder(order.id),
                    successMessage: 'Order delivered',
                  ),
            icon: isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
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
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _performOrderAction({
    required int orderId,
    required Future<bool> Function() action,
    required String successMessage,
  }) async {
    if (_processingOrders.contains(orderId)) return;

    setState(() {
      _processingOrders.add(orderId);
    });

    try {
      final success = await action();
      if (!mounted) {
        return;
      }

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Action could not be completed'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print(
        'CourierDashboardScreen: Order action successful - $successMessage',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: Colors.teal),
      );
      await _loadData();
    } catch (e, stackTrace) {
      print('CourierDashboardScreen: ERROR performing order action - $e');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingOrders.remove(orderId);
        });
      } else {
        _processingOrders.remove(orderId);
      }
    }
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

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations? localizations,
    AuthProvider authProvider,
  ) {
    // Legacy header, replaced by CourierHeader.
    return const SizedBox.shrink();
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    // Legacy method, no longer used (CourierHeader now owns notification icon).
    return const SizedBox.shrink();
  }
}
