import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/notifications/data/models/courier_notification.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/features/dashboard/presentation/widgets/courier_header.dart';
import 'package:mobile/features/orders/presentation/screens/courier/order_detail_screen.dart'; // Import verified

class CourierNotificationsScreen extends StatefulWidget {
  const CourierNotificationsScreen({super.key});

  @override
  State<CourierNotificationsScreen> createState() =>
      _CourierNotificationsScreenState();
}

class _CourierNotificationsScreenState extends State<CourierNotificationsScreen>
    with SingleTickerProviderStateMixin {
  final CourierService _courierService = CourierService();
  final List<CourierNotification> _notifications = [];
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  int _unreadCount = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    LoggerService().debug('CourierNotificationsScreen: initState called');
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    LoggerService().debug(
      'CourierNotificationsScreen: Loading notifications...',
    );
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final response = await _courierService.getNotifications(pageSize: 50);
      if (!mounted) return;
      setState(() {
        _notifications
          ..clear()
          ..addAll(response.items);
        _unreadCount = response.unreadCount;
        _isLoading = false;
      });
      LoggerService().debug(
        'CourierNotificationsScreen: Loaded ${response.items.length} notifications. Unread: ${response.unreadCount}',
      );
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierNotificationsScreen: ERROR loading notifications',
        e,
        stackTrace,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handleRefresh() async {
    LoggerService().debug('CourierNotificationsScreen: Refresh triggered');
    await _loadNotifications();
  }

  Future<void> _markAsRead(String id) async {
    try {
      LoggerService().debug(
        'CourierNotificationsScreen: Marking notification $id as read',
      );
      await _courierService.markNotificationRead(id);
      await _loadNotifications();
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierNotificationsScreen: ERROR mark as read',
        e,
        stackTrace,
      );
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.notificationProcessingFailed(e.toString()) ??
                'Bildirim işlenemedi: $e',
          ),
        ),
      );
    }
  }

  String? _extractOrderNumber(String message) {
    // Extract order number from message like "#123456 numaralı sipariş..."
    // or "#123456 numaralı siparişiniz..."
    final regex = RegExp(r'#(\d{6})');
    final match = regex.firstMatch(message);
    return match != null ? 'Sipariş #${match.group(1)}' : null;
  }

  void _handleNotificationTap(CourierNotification notification) async {
    LoggerService().debug(
      'CourierNotificationsScreen: Notification tapped - ${notification.id}',
    );
    if (!notification.isRead) {
      await _markAsRead(notification.id);
    }

    if (!mounted) return;

    if (notification.orderId != null && notification.orderId!.isNotEmpty) {
      final orderId = notification.orderId.toString();
      LoggerService().debug(
        'CourierNotificationsScreen: Navigating to order detail with orderId: $orderId',
      );
      // Use direct navigation to ensure correct screen is opened
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OrderDetailScreen(orderId: orderId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // Fallback strings if localization is missing some keys
    final tabAll = localizations?.notificationAll ?? 'Tümü';
    final tabOrders = 'Siparişler'; // TODO: Add to Arb if needed
    final tabSystem = localizations?.notificationSystem ?? 'Sistem';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: _unreadCount > 0
            ? '${localizations?.notificationsTitle ?? 'Bildirimler'} (${localizations?.unreadNotificationsCount(_unreadCount) ?? '$_unreadCount okunmamış'})'
            : (localizations?.notificationsTitle ?? 'Bildirimler'),
        leadingIcon: Icons.notifications_active_outlined,
        showBackButton: true,
        showNotifications: false,
        onBack: () {
          Navigator.of(context).pop();
        },
        onRefresh: _handleRefresh,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.teal,
              tabs: [
                Tab(text: tabAll),
                Tab(text: tabOrders),
                Tab(text: tabSystem),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(_notifications),
                _buildNotificationList(
                  _notifications.where((n) => n.isOrderRelated).toList(),
                  emptyMessage: 'Sipariş bildirimi bulunmuyor.',
                ),
                _buildNotificationList(
                  _notifications.where((n) => n.isSystemRelated).toList(),
                  emptyMessage: 'Sistem bildirimi bulunmuyor.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    List<CourierNotification> notifications, {
    String? emptyMessage,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (_isError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage ??
                  (AppLocalizations.of(context)?.notificationsLoadFailed ??
                      'Bildirimler yüklenemedi'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: Text(
                AppLocalizations.of(context)?.tryAgain ?? 'Tekrar Dene',
              ),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      final localizations = AppLocalizations.of(context);
      return Center(
        child: Text(
          emptyMessage ??
              localizations?.noNotificationsYet ??
              'Henüz bir bildirimin yok.\nSipariş hareketlerin burada görünecek.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return GestureDetector(
            onTap: () => _handleNotificationTap(notification),
            child: Container(
              decoration: BoxDecoration(
                color: notification.isRead
                    ? Colors.grey.shade100
                    : Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: notification.isRead
                      ? Colors.grey.shade300
                      : Colors.teal.shade200,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        notification.isRead
                            ? Icons.notifications_none
                            : Icons.notifications_active,
                        color: notification.isRead ? Colors.grey : Colors.teal,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.message,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat(
                                'dd MMM yyyy HH:mm',
                              ).format(notification.createdAt.toLocal()),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!notification.isRead)
                        const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.fiber_manual_record,
                            color: Colors.teal,
                            size: 12,
                          ),
                        ),
                    ],
                  ),
                  if (notification.orderId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: TextButton.icon(
                        onPressed: () => _handleNotificationTap(notification),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(
                          _extractOrderNumber(notification.message) ??
                              'Sipariş #${notification.orderId}',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
