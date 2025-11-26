import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class VendorHeader extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final IconData leadingIcon;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;
  final bool showNotifications;
  final bool showRefresh;

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
  });

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
      // TODO: Implement vendor notification count API call when available
      // For now, we'll use a static count or fetch from local state
      if (!mounted) return;
      setState(() {
        _unreadNotifications = 0; // Placeholder until API is implemented
      });
    } catch (e, stackTrace) {
      print('VendorHeader: ERROR refreshing notification count - $e');
      print(stackTrace);
    }
  }

  Future<void> _openNotifications() async {
    print('VendorHeader: Notifications icon tapped');
    await Navigator.of(context).pushNamed('/vendor/notifications');
    if (mounted) {
      await _refreshNotificationCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final title =
        widget.title ?? localizations?.roleVendor ?? 'Vendor Dashboard';
    final subtitle = widget.subtitle ?? auth.fullName ?? auth.email ?? 'Satıcı';

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
            color: Colors.black.withOpacity(0.1),
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
                    print('VendorHeader: Back button pressed');
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
                    color: Colors.white.withOpacity(0.2),
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
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                    print('VendorHeader: Refresh icon pressed');
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
}
