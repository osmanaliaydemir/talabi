import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile/features/vendors/presentation/providers/vendor_provider.dart';
import 'package:mobile/providers/notification_provider.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VendorProvider>().loadVendorProfile();
      context.read<NotificationProvider>().loadVendorNotifications();
    });
  }

  Future<void> _openNotifications() async {
    LoggerService().debug('VendorHeader: Notifications icon tapped');
    await Navigator.of(context).pushNamed('/vendor/notifications');
    if (mounted) {
      context.read<NotificationProvider>().loadVendorNotifications(force: true);
    }
  }

  Future<void> _updateBusyStatus(int status) async {
    try {
      await context.read<VendorProvider>().updateBusyStatus(status);
      if (!mounted) return;

      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations?.statusUpdated ?? 'Durum güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.errorWithMessage(e.toString()) ?? 'Hata: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showStatusDialog() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return;

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(localizations.storeStatus),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _updateBusyStatus(0); // Normal
            },
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(localizations.vendorStatusNormal),
                const Spacer(),
                Text(
                  localizations.vendorStatusNormalDesc,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _updateBusyStatus(1); // Busy
            },
            child: Row(
              children: [
                const Icon(Icons.hourglass_bottom, color: Colors.amber),
                const SizedBox(width: 8),
                Text(localizations.vendorStatusBusy),
                const Spacer(),
                Text(
                  localizations.vendorStatusBusyDesc,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _updateBusyStatus(2); // Overloaded
            },
            child: Row(
              children: [
                const Icon(Icons.cancel, color: Colors.red),
                const SizedBox(width: 8),
                Text(localizations.vendorStatusOverloaded),
                const Spacer(),
                Text(
                  localizations.vendorStatusOverloadedDesc,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon() {
    if (widget.showBackButton) {
      return IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          LoggerService().debug('VendorHeader: Back button pressed');
          if (widget.onBack != null) {
            widget.onBack!();
          } else {
            Navigator.of(context).pop();
          }
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(widget.leadingIcon, color: Colors.white, size: 22),
    );
  }

  Widget _buildStatusIcon() {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return const SizedBox.shrink();

    IconData icon;
    Color color;
    String tooltip;

    final currentStatus = context.watch<VendorProvider>().currentStatus;

    switch (currentStatus) {
      case 1: // Busy
        icon = Icons.hourglass_bottom;
        color = Colors.amber;
        tooltip = localizations.vendorStatusBusy;
        break;
      case 2: // Overloaded
        icon = Icons.cancel;
        color = Colors.red;
        tooltip = localizations.vendorStatusOverloaded;
        break;
      case 0: // Normal
      default:
        icon = Icons.check_circle;
        color = Colors.green;
        tooltip = localizations.vendorStatusNormal;
        break;
    }

    return GestureDetector(
      onTap: _showStatusDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              tooltip,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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
              _buildLeadingIcon(),
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
              if (!widget.showBackButton) ...[
                _buildStatusIcon(),
                const SizedBox(width: 8),
              ],
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
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final unreadCount = provider.vendorUnreadCount;

        if (unreadCount <= 0) {
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
                  unreadCount > 9 ? '9+' : '$unreadCount',
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
      },
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
