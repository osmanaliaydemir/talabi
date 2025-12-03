import 'package:flutter/material.dart';
import 'package:mobile/screens/customer/search_screen.dart';
import 'package:mobile/l10n/app_localizations.dart';

class SpecialHomeHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLocationTap;
  final String? currentLocation;

  const SpecialHomeHeader({
    super.key,
    this.onNotificationTap,
    this.onLocationTap,
    this.currentLocation,
  });

  @override
  Size get preferredSize => const Size.fromHeight(310);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textDirection = Directionality.of(context);

    return SizedBox(
      height: 310,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Red Background & Ellipse (Clipped)
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
              child: Stack(
                children: [Container(color: const Color(0xFFCE181B))],
              ),
            ),
          ),

          // 3. Banner Image (Food)
          Positioned.directional(
            textDirection: textDirection,
            top: 50,
            start: 110,
            width: 310,
            height: 243,
            child: Image.asset(
              'assets/images/banner_image.png',
              fit: BoxFit.contain,
            ),
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
                                      const Icon(
                                        Icons.location_on,
                                        color: Color(0xFFCE181B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      currentLocation != null
                                          ? Text(
                                              currentLocation!,
                                              style: const TextStyle(
                                                color: Color(0xFF121212),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Plus Jakarta Sans',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Color(0xFFCE181B)),
                                              ),
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
                          GestureDetector(
                            onTap: onNotificationTap,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),

                              child: const Icon(
                                Icons.notifications,
                                color: Color(0xFFCE181B),
                                size: 22,
                              ),
                            ),
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
                          SizedBox(
                            width: 224,
                            child: Text(
                              l10n.promotionalBannerTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                                fontFamily: 'Plus Jakarta Sans',
                                letterSpacing: -0.02,
                              ),
                            ),
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
          Positioned.directional(
            textDirection: textDirection,
            top: 255,
            start: 43,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
              },
              child: Container(
                width: 320,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1000),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0x1A1A1A1A),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
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
