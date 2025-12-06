import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/models/customer_notification.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/providers/theme_provider.dart';
import 'package:mobile/screens/customer/widgets/shared_header.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).loadNotifications();
    });
  }

  Future<void> _refreshNotifications() async {
    await Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              SharedHeader(
                title: localizations.notifications,
                subtitle: localizations.unreadNotificationsCount(
                  provider.unreadCount,
                ),
                showBackButton: true,
                icon: Icons.notifications_active_outlined,
                onBack: () => Navigator.of(context).pop(),
                action: Theme(
                  data: Theme.of(context).copyWith(
                    popupMenuTheme: PopupMenuThemeData(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      color: Colors.white,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 40),
                    padding: EdgeInsets.zero,
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'mark_all_read') {
                        provider.markAllAsRead();
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      return [
                        PopupMenuItem<String>(
                          value: 'mark_all_read',
                          child: Row(
                            children: [
                              Icon(
                                Icons.done_all,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Tümünü okundu işaretle',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  child: _buildContent(provider, localizations),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    NotificationProvider provider,
    AppLocalizations localizations,
  ) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    } else if (provider.error != null && provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('${localizations.error}: ${provider.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshNotifications,
              child: Text(localizations.retry),
            ),
          ],
        ),
      );
    } else if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              localizations.vendorNotificationsEmptyMessage,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notification = provider.notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(CustomerNotification notification) {
    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          Provider.of<NotificationProvider>(
            context,
            listen: false,
          ).markAsRead(notification.id);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: notification.isRead
              ? Theme.of(context).cardColor
              : Theme.of(context).primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: notification.isRead
              ? Border.all(color: Colors.grey.withOpacity(0.2))
              : Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getIconColor(notification.type).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(notification.type),
                  color: _getIconColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.createdAt),
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'promo':
        return Icons.local_offer_outlined;
      case 'system':
        return Icons.info_outline;
      case 'delivery':
        return Icons.local_shipping_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getIconColor(String type) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final category = themeProvider.currentCategory ?? MainCategory.restaurant;

    switch (type.toLowerCase()) {
      case 'order':
        return Theme.of(context).primaryColor;
      case 'promo':
        return AppTheme.getLightColorForVendorType(category);
      case 'system':
        return AppTheme.textSecondary;
      case 'delivery':
        return AppTheme.courierPrimary;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}
