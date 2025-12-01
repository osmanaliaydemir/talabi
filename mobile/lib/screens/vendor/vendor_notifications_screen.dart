import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/vendor/vendor_header.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/models/vendor_notification.dart';
import 'package:intl/intl.dart';

class VendorNotificationsScreen extends StatefulWidget {
  const VendorNotificationsScreen({super.key});

  @override
  State<VendorNotificationsScreen> createState() =>
      _VendorNotificationsScreenState();
}

class _VendorNotificationsScreenState extends State<VendorNotificationsScreen> {
  late Future<List<VendorNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _loadNotifications();
  }

  Future<List<VendorNotification>> _loadNotifications() async {
    try {
      final data = await ApiService().getVendorNotifications();
      return data.map((json) => VendorNotification.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _markAsRead(int id) async {
    try {
      await ApiService().markNotificationAsRead('vendor', id);
      setState(() {
        _notificationsFuture = _loadNotifications();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bildirim okundu olarak işaretlenemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: VendorHeader(
        title: localizations.vendorNotificationsTitle,
        leadingIcon: Icons.notifications,
        showBackButton: true,
      ),
      body: FutureBuilder<List<VendorNotification>>(
        future: _notificationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(localizations.vendorNotificationsErrorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _notificationsFuture = _loadNotifications();
                      });
                    },
                    child: const Text('Yeniden Dene'),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final notifications = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _notificationsFuture = _loadNotifications();
                });
              },
              child: ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                      child: Icon(
                        _getIconForType(notification.type),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification.message),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'dd MMM yyyy, HH:mm',
                          ).format(notification.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: notification.isRead
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () => _markAsRead(notification.id),
                            tooltip: 'Okundu olarak işaretle',
                          ),
                    onTap: () {
                      if (!notification.isRead) {
                        _markAsRead(notification.id);
                      }
                    },
                  );
                },
              ),
            );
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  localizations.vendorNotificationsEmptyMessage,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'neworder':
        return Icons.shopping_cart;
      case 'orderstatuschanged':
        return Icons.update;
      case 'newreview':
        return Icons.star;
      case 'info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}
