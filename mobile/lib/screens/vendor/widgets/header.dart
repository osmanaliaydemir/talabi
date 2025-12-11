import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/models/vendor_notification.dart';

class VendorHeader extends StatefulWidget implements PreferredSizeWidget {
  const VendorHeader({
    super.key,
    this.title,
    this.subtitle,
    this.leadingIcon = Icons.store,
    this.showBackButton = false,
    this.onBack,
    this.onRefresh,
    this.showNotifications = true,
    this.showRefresh = true,
    this.orderCounts,
    this.selectedStatus,
  });

  final String? title;
  final String? subtitle;
  final IconData leadingIcon;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;
  final bool showNotifications;
  final bool showRefresh;
  final Map<String, int>? orderCounts;
  final String? selectedStatus;

  @override
  Size get preferredSize => const Size.fromHeight(90);

  @override
  State<VendorHeader> createState() => _VendorHeaderState();
}

class _VendorHeaderState extends State<VendorHeader> {
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _refreshNotificationCount();
  }

  Future<void> _refreshNotificationCount() async {
    try {
      final notificationsData = await ApiService().getVendorNotifications();
      final notifications = notificationsData
          .map((json) => VendorNotification.fromJson(json))
          .toList();

      if (!mounted) return;

      setState(() {
        _unreadNotifications = notifications.where((n) => !n.isRead).length;
      });
    } catch (e, stackTrace) {
      LoggerService().error(
        'VendorHeader: ERROR refreshing notification count',
        e,
        stackTrace,
      );
      // Keep 0 as default on error
    }
  }

  Future<void> _openNotifications() async {
    LoggerService().debug('VendorHeader: Notifications icon tapped');
    await Navigator.of(context).pushNamed('/vendor/notifications');
    if (mounted) {
      await _refreshNotificationCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final title =
        widget.title ?? localizations?.roleVendor ?? 'Vendor Dashboard';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade700,
            Colors.deepPurple.shade500,
            Colors.deepPurple.shade300,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              if (widget.showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    LoggerService().debug('VendorHeader: Back button pressed');
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.leadingIcon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.orderCounts != null) ...[
                      const SizedBox(height: 4),
                      _buildOrderCountText(localizations),
                    ],
                  ],
                ),
              ),
              if (widget.showNotifications)
                IconButton(
                  icon: _buildNotificationIcon(),
                  onPressed: _openNotifications,
                ),
              if (widget.showRefresh && widget.onRefresh != null)
                IconButton(
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    LoggerService().debug('VendorHeader: Refresh icon pressed');
                    widget.onRefresh?.call();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon() {
    if (_unreadNotifications <= 0) {
      return const Icon(
        Icons.notifications_none,
        color: Colors.white,
        size: 24,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.notifications, color: Colors.white, size: 24),
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minHeight: 18, minWidth: 18),
            child: Text(
              _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCountText(AppLocalizations? localizations) {
    if (widget.orderCounts == null || localizations == null) {
      return const SizedBox.shrink();
    }

    final counts = widget.orderCounts!;
    String? countText;
    int count = 0;
    String statusText = '';

    if (widget.selectedStatus != null) {
      count = counts[widget.selectedStatus!] ?? 0;
      switch (widget.selectedStatus!.toLowerCase()) {
        case 'pending':
          statusText = localizations.pending.toLowerCase();
          countText = '$count adet $statusText sipariş';
          break;
        case 'preparing':
          statusText = localizations.preparing.toLowerCase();
          countText = '$count adet $statusText sipariş';
          break;
        case 'ready':
          statusText = localizations.ready.toLowerCase();
          countText = '$count adet $statusText sipariş';
          break;
        case 'delivered':
          statusText = localizations.delivered.toLowerCase();
          countText = '$count adet sipariş $statusText';
          break;
        case 'cancelled':
          statusText = localizations.cancelled.toLowerCase();
          countText = '$count adet $statusText sipariş';
          break;
      }
    } else {
      final pendingCount = counts['Pending'] ?? 0;
      final preparingCount = counts['Preparing'] ?? 0;
      final readyCount = counts['Ready'] ?? 0;
      final deliveredCount = counts['Delivered'] ?? 0;
      final cancelledCount = counts['Cancelled'] ?? 0;

      if (pendingCount > 0) {
        countText =
            '$pendingCount adet ${localizations.pending.toLowerCase()} sipariş';
      } else if (preparingCount > 0) {
        countText =
            '$preparingCount adet ${localizations.preparing.toLowerCase()} sipariş';
      } else if (readyCount > 0) {
        countText =
            '$readyCount adet ${localizations.ready.toLowerCase()} sipariş';
      } else if (deliveredCount > 0) {
        countText =
            '$deliveredCount adet sipariş ${localizations.delivered.toLowerCase()}';
      } else if (cancelledCount > 0) {
        countText =
            '$cancelledCount adet ${localizations.cancelled.toLowerCase()} sipariş';
      }
    }

    if (countText == null || (widget.selectedStatus != null && count == 0)) {
      return const SizedBox.shrink();
    }

    return Text(
      countText,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.85),
        fontSize: 12,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
