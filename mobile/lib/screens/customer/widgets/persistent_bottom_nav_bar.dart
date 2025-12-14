import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:provider/provider.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';

class PersistentBottomNavBar extends StatefulWidget {
  const PersistentBottomNavBar({super.key});

  @override
  State<PersistentBottomNavBar> createState() => _PersistentBottomNavBarState();
}

class _PersistentBottomNavBarState extends State<PersistentBottomNavBar>
    with SingleTickerProviderStateMixin {
  bool _hasPlayedAnimation = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Scale animation: 1.0 -> 1.5 -> 1.0 -> 1.2 -> 1.0
    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.5),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.5, end: 1.0),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 1.2),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.2, end: 1.0),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    // Rotation animation: 0 -> 360 degrees
    _rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: 1.0, // 1.0 = 360 degrees in radians (2 * pi)
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    _checkAndPlayAnimation();
  }

  Future<void> _checkAndPlayAnimation() async {
    if (_hasPlayedAnimation) return;

    // Delay to ensure UI is ready
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (mounted) {
        await _animationController.forward();
        if (mounted) {
          setState(() {
            _hasPlayedAnimation = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final bottomNav = Provider.of<BottomNavProvider>(context);
    final cart = Provider.of<CartProvider>(context);

    final List<String> screenNames = [
      localizations.discover,
      localizations.category,
      localizations.myCart,
      localizations.myOrders,
      localizations.myAccount,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A1A1A1A).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                context,
                index: 0,
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                label: localizations.discover,
                isSelected: bottomNav.currentIndex == 0,
                onTap: () => _onItemTapped(context, 0, bottomNav, screenNames),
              ),
              _buildAnimatedCategoryNavItem(
                context,
                bottomNav: bottomNav,
                localizations: localizations,
              ),
              _buildNavItem(
                context,
                index: 2,
                icon: Icons.shopping_cart_outlined,
                selectedIcon: Icons.shopping_cart,
                label: localizations.myCart,
                isSelected: bottomNav.currentIndex == 2,
                onTap: () => _onItemTapped(context, 2, bottomNav, screenNames),
                badge: cart.itemCount > 0 ? cart.itemCount : null,
              ),
              _buildNavItem(
                context,
                index: 3,
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long,
                label: localizations.myOrders,
                isSelected: bottomNav.currentIndex == 3,
                onTap: () => _onItemTapped(context, 3, bottomNav, screenNames),
              ),
              _buildNavItem(
                context,
                index: 4,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: localizations.myAccount,
                isSelected: bottomNav.currentIndex == 4,
                onTap: () => _onItemTapped(context, 4, bottomNav, screenNames),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCategoryToggle(
    BuildContext context,
    BottomNavProvider bottomNav,
  ) {
    final currentCategory = bottomNav.selectedCategory;
    final targetCategory = currentCategory == MainCategory.restaurant
        ? MainCategory.market
        : MainCategory.restaurant;

    final cart = Provider.of<CartProvider>(context, listen: false);

    if (cart.itemCount > 0) {
      final localizations = AppLocalizations.of(context)!;
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (context) => CustomConfirmationDialog(
          title: localizations.categoryChangeConfirmTitle,
          message: localizations.categoryChangeConfirmMessage,
          confirmText: localizations.categoryChangeConfirmOk,
          cancelText: localizations.categoryChangeConfirmCancel,
          icon: Icons.delete_outline,
          iconColor: Colors.red,
          confirmButtonColor: Colors.red,
          onConfirm: () {
            Navigator.pop(context); // Close dialog
            cart.clear(); // Clear cart
            bottomNav
              ..setCategory(targetCategory)
              ..setIndex(0); // Go to home screen
          },
        ),
      );
    } else {
      bottomNav
        ..setCategory(targetCategory)
        ..setIndex(0); // Go to home screen
    }
  }

  void _onItemTapped(
    BuildContext context,
    int index,
    BottomNavProvider bottomNav,
    List<String> screenNames,
  ) {
    final fromIndex = bottomNav.currentIndex;
    final toLabel = screenNames[index];
    TapLogger.logBottomNavChange(fromIndex, index, toLabel);
    bottomNav.setIndex(index);

    // Navigate back to MainNavigationScreen if we're on a sub-page
    final navigator = Navigator.of(context);
    // Pop all routes until we reach the main navigation screen
    while (navigator.canPop()) {
      navigator.pop();
    }
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 24,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
                if (badge != null)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$badge',
                        style: AppTheme.poppins(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                style: AppTheme.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCategoryNavItem(
    BuildContext context, {
    required BottomNavProvider bottomNav,
    required AppLocalizations localizations,
  }) {
    // Helper to determine target category logic (opposite of current)
    final isCurrentRestaurant =
        bottomNav.selectedCategory == MainCategory.restaurant;

    // We show the icon/label of the TARGET category (what we will switch TO)
    // If current is Restaurant, we show Market icon/label
    // If current is Market, we show Restaurant icon/label
    final icon = isCurrentRestaurant
        ? Icons.storefront_outlined
        : Icons.restaurant_outlined;
    final selectedIcon = isCurrentRestaurant
        ? Icons.storefront
        : Icons.restaurant;

    // Using hardcoded strings as per current codebase patterns in CategorySelectionBottomSheet
    // In a full implementation, these should be localized keys
    final label = isCurrentRestaurant ? 'Market' : 'Restoran';

    final isSelected = bottomNav.currentIndex == 1;

    return GestureDetector(
      onTap: () => _handleCategoryToggle(context, bottomNav),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          // Only apply animation if it hasn't been played or is currently playing
          final shouldAnimate =
              !_hasPlayedAnimation || _animationController.isAnimating;

          return Transform.scale(
            scale: shouldAnimate ? _scaleAnimation.value : 1.0,
            child: Transform.rotate(
              angle: shouldAnimate
                  ? _rotationAnimation.value * 2 * 3.14159
                  : 0.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          isSelected ? selectedIcon : icon,
                          size: 24,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        label,
                        style: AppTheme.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
