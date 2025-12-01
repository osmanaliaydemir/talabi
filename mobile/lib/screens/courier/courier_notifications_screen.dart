import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:mobile/models/courier_notification.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/widgets/courier/courier_header.dart';

class CourierNotificationsScreen extends StatefulWidget {
  const CourierNotificationsScreen({super.key});

  @override
  State<CourierNotificationsScreen> createState() =>
      _CourierNotificationsScreenState();
}

class _CourierNotificationsScreenState
    extends State<CourierNotificationsScreen> {
  final CourierService _courierService = CourierService();
  final List<CourierNotification> _notifications = [];
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    print('CourierNotificationsScreen: initState called');
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    print('CourierNotificationsScreen: Loading notifications...');
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
      print(
        'CourierNotificationsScreen: Loaded ${response.items.length} notifications. Unread: ${response.unreadCount}',
      );
    } catch (e, stackTrace) {
      print('CourierNotificationsScreen: ERROR loading notifications - $e');
      print(stackTrace);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handleRefresh() async {
    print('CourierNotificationsScreen: Refresh triggered');
    await _loadNotifications();
  }

  Future<void> _markAsRead(int id) async {
    try {
      print('CourierNotificationsScreen: Marking notification $id as read');
      await _courierService.markNotificationRead(id);
      await _loadNotifications();
    } catch (e, stackTrace) {
      print('CourierNotificationsScreen: ERROR mark as read - $e');
      print(stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bildirim işlenemedi: $e')));
    }
  }

  void _handleNotificationTap(CourierNotification notification) async {
    print(
      'CourierNotificationsScreen: Notification tapped - ${notification.id}',
    );
    if (!notification.isRead) {
      await _markAsRead(notification.id);
    }

    if (!mounted) return;

    if (notification.orderId != null) {
      Navigator.of(
        context,
      ).pushNamed('/courier/order-detail', arguments: notification.orderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: _unreadCount > 0
            ? 'Bildirimler ($_unreadCount okunmamış)'
            : 'Bildirimler',
        leadingIcon: Icons.notifications_active_outlined,
        showBackButton: true,
        showNotifications: false,
        onBack: () {
          Navigator.of(context).pop();
        },
        onRefresh: _handleRefresh,
      ),
      body: RefreshIndicator(onRefresh: _handleRefresh, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (_isError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage ?? 'Bildirimler yüklenemedi'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Text(
          'Henüz bir bildirimin yok.\nSipariş hareketlerin burada görünecek.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
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
                      label: Text('Sipariş #${notification.orderId}'),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
