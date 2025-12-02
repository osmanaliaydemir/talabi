import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/providers/cart_provider.dart';
import 'package:mobile/screens/customer/cart_screen.dart';
import 'package:provider/provider.dart';

class CustomerHeader extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final IconData leadingIcon;
  final bool showBackButton;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;
  final bool showCart;
  final bool showRefresh;
  // Address related
  final bool showAddress;
  final Map<String, dynamic>? selectedAddress;
  final bool isLoadingAddress;
  final VoidCallback? onAddressTap;

  const CustomerHeader({
    super.key,
    this.title,
    this.subtitle,
    this.leadingIcon = Icons.explore,
    this.showBackButton = false,
    this.onBack,
    this.onRefresh,
    this.showCart = true,
    this.showRefresh = false,
    this.showAddress = false,
    this.selectedAddress,
    this.isLoadingAddress = false,
    this.onAddressTap,
  });

  @override
  Size get preferredSize => Size.fromHeight(showAddress ? 120 : 90);

  @override
  State<CustomerHeader> createState() => _CustomerHeaderState();
}

class _CustomerHeaderState extends State<CustomerHeader> {
  String _getAddressDisplayText(Map<String, dynamic> address) {
    final district = address['district'] ?? '';
    final city = address['city'] ?? '';
    if (district.isNotEmpty && city.isNotEmpty) {
      return '$district, $city';
    } else if (address['fullAddress'] != null &&
        address['fullAddress'].toString().isNotEmpty) {
      return address['fullAddress'].toString();
    }
    return 'Adres';
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cart = Provider.of<CartProvider>(context);

    final title = widget.title ?? localizations?.discover ?? 'Keşfet';
    final subtitle =
        widget.subtitle ?? auth.fullName ?? auth.email ?? 'Müşteri';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade700,
            Colors.orange.shade500,
            Colors.orange.shade300,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (widget.showBackButton)
                    GestureDetector(
                      onTap: () {
                        if (widget.onBack != null) {
                          widget.onBack!();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(AppTheme.spacingSmall),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSmall,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
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
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.showRefresh && widget.onRefresh != null)
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: widget.onRefresh,
                    ),
                  if (widget.showCart) _buildCartIcon(cart),
                ],
              ),
              if (widget.showAddress) ...[
                const SizedBox(height: 12),
                _buildAddressButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartIcon(CartProvider cart) {
    return Semantics(
      label: 'Shopping cart, ${cart.itemCount} items',
      button: true,
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
          if (cart.itemCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  '${cart.itemCount}',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressButton() {
    final localizations = AppLocalizations.of(context);

    return Semantics(
      label:
          'Delivery location: ${widget.selectedAddress != null ? _getAddressDisplayText(widget.selectedAddress!) : 'No address selected'}',
      button: true,
      hint: 'Tap to change delivery address',
      child: InkWell(
        onTap: widget.onAddressTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.selectedAddress != null
                      ? _getAddressDisplayText(widget.selectedAddress!)
                      : localizations?.selectAddress ?? 'Adres seçin',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
