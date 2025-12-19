import 'package:flutter/material.dart';
import 'package:mobile/features/search/presentation/screens/search_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/notification_provider.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'dart:math' as math;

class SpecialHomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const SpecialHomeHeader({
    super.key,
    this.onNotificationTap,
    this.onLocationTap,
    this.currentLocation,
    this.isAddressesLoading = true,
  });

  final VoidCallback? onNotificationTap;
  final VoidCallback? onLocationTap;
  final String? currentLocation;
  final bool isAddressesLoading;

  @override
  Size get preferredSize => const Size.fromHeight(310);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection = Directionality.of(context);
    final primaryColor = Theme.of(context).primaryColor;

    return SizedBox(
      height: 310,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Primary Color Background & Ellipse (Clipped)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 283,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Stack(children: [Container(color: primaryColor)]),
            ),
          ),

          // 3. Banner Image (Food)
          // 3. Banner Image (Food)
          Consumer<BottomNavProvider>(
            builder: (context, bottomNav, child) {
              final isMarket =
                  bottomNav.selectedCategory == MainCategory.market;
              return Positioned.directional(
                textDirection: textDirection,
                top: isMarket ? 30 : 50,
                start: isMarket ? 90 : 110,
                width: isMarket ? 360 : 310,
                height: isMarket ? 280 : 243,
                child: Image.asset(
                  isMarket
                      ? 'assets/images/market_banner.png'
                      : 'assets/images/banner_image.png',
                  fit: BoxFit.contain,
                ),
              );
            },
          ),

          // 4. Content (Location, Text, Button)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 283,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Location & Notification
                    SizedBox(
                      height: 55,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: onLocationTap,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(1000),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      currentLocation != null
                                          ? ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 200,
                                              ),
                                              child: Text(
                                                currentLocation!,
                                                style: const TextStyle(
                                                  color: Color(0xFF121212),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily:
                                                      'Plus Jakarta Sans',
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            )
                                          : isAddressesLoading
                                          ? SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(primaryColor),
                                              ),
                                            )
                                          : Text(
                                              l10n.addAddressToOrder,
                                              style: TextStyle(
                                                color: primaryColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Plus Jakarta Sans',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 18,
                                        color: Color(0xFF121212),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Consumer<NotificationProvider>(
                            builder: (context, notificationProvider, child) {
                              return _AnimatedNotificationIcon(
                                onTap: onNotificationTap,
                                unreadCount: notificationProvider.unreadCount,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // Main Content Text & Button
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Consumer<BottomNavProvider>(
                            builder: (context, bottomNav, child) {
                              final isMarket =
                                  bottomNav.selectedCategory ==
                                  MainCategory.market;
                              return SizedBox(
                                width: 224,
                                child: Text(
                                  isMarket
                                      ? l10n.marketBannerTitle
                                      : l10n.promotionalBannerTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                    fontFamily: 'Plus Jakarta Sans',
                                    letterSpacing: -0.02,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () {
                              // Handle order now
                            },
                            child: Container(
                              width: 87,
                              height: 27,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(1000),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.orderNow,
                                style: const TextStyle(
                                  color: Color(0xFF121212),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Plus Jakarta Sans',
                                  letterSpacing: -0.02,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Search Bar (Overlapping)
          Positioned(
            top: 265,
            left: 50, // Add padding from left
            right: 50, // Add padding from right to ensure centering
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: Container(
                height: 50,
                // Removed fixed width: 320 to allow it to be responsive
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1000),
                  boxShadow: [
                    const BoxShadow(
                      color: Color(0x1A1A1A1A),
                      blurRadius: 20,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Color(0xFF8A8A8A),
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      l10n.searchProductsOrVendors,
                      style: const TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Plus Jakarta Sans',
                        letterSpacing: -0.02,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedNotificationIcon extends StatefulWidget {
  const _AnimatedNotificationIcon({this.onTap, required this.unreadCount});

  final VoidCallback? onTap;
  final int unreadCount;

  @override
  State<_AnimatedNotificationIcon> createState() =>
      _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState extends State<_AnimatedNotificationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    if (widget.unreadCount > 0) {
      _startShake();
    }
  }

  @override
  void didUpdateWidget(_AnimatedNotificationIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Animate if unread count changes and is greater than 0
    // OR if unread count is > 0 and we just rebuilt (potentially from a refresh)
    if (widget.unreadCount > 0) {
      if (widget.unreadCount != oldWidget.unreadCount) {
        _startShake();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startShake() {
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Create a sine wave shake effect
        // 5 full shakes in 2 seconds
        // sin(value * 2 * pi * 5)
        // Amplitude: 0.05 turns (approx 18 degrees)
        final double shake =
            math.sin(_controller.value * 2 * math.pi * 5) * 0.05;

        return Transform.rotate(
          angle: shake * 2 * math.pi, // Convert turns to radians
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications,
                color: Theme.of(context).primaryColor,
                size: 22,
              ),
            ),
            if (widget.unreadCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 1.5),
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '${widget.unreadCount}',
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
        ),
      ),
    );
  }
}
