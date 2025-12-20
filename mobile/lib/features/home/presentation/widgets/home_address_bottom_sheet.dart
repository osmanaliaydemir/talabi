import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/profile/presentation/screens/customer/addresses_screen.dart';

class HomeAddressBottomSheet extends StatefulWidget {
  const HomeAddressBottomSheet({
    super.key,
    required this.addresses,
    required this.selectedAddress,
    required this.colorScheme,
    required this.onAddressSelected,
    required this.onSetDefault,
  });

  final List<dynamic> addresses;
  final Map<String, dynamic>? selectedAddress;
  final ColorScheme colorScheme;
  final Function(Map<String, dynamic>) onAddressSelected;
  final Function(Map<String, dynamic>) onSetDefault;

  @override
  State<HomeAddressBottomSheet> createState() => _HomeAddressBottomSheetState();
}

class _HomeAddressBottomSheetState extends State<HomeAddressBottomSheet> {
  Map<String, dynamic>? _tempSelectedAddress;

  @override
  void initState() {
    super.initState();
    _tempSelectedAddress = widget.selectedAddress;
  }

  String _getAddressDisplayText(
    Map<String, dynamic> address,
    AppLocalizations localizations,
  ) {
    final district = address['district'] ?? '';
    final city = address['city'] ?? '';
    if (district.isNotEmpty && city.isNotEmpty) {
      return '$district, $city';
    } else if (address['fullAddress'] != null &&
        address['fullAddress'].toString().isNotEmpty) {
      return address['fullAddress'].toString();
    }
    return localizations.address;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusLarge),
          topRight: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMedium,
              vertical: AppTheme.spacingMedium,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.selectAddress,
                  style: AppTheme.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Address List
          if (widget.addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Icon(
                    Icons.location_off,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    localizations.noAddressesYet,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressesScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.colorScheme.primary,
                      foregroundColor: AppTheme.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge,
                        vertical: AppTheme.spacingMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                    ),
                    child: Text(
                      localizations.addAddress,
                      style: AppTheme.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textOnPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.addresses.length,
                itemBuilder: (context, index) {
                  final address = widget.addresses[index];
                  final isSelected =
                      _tempSelectedAddress?['id'] == address['id'];
                  final isDefault = address['isDefault'] == true;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _tempSelectedAddress = address;
                      });
                      // Update parent state but don't close bottom sheet
                      widget.onAddressSelected(address);
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMedium,
                        vertical: AppTheme.spacingSmall,
                      ),
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.colorScheme.primary.withValues(alpha: 0.1)
                            : AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        border: Border.all(
                          color: isSelected
                              ? widget.colorScheme.primary
                              : AppTheme.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Address Icon
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? widget.colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    )
                                  : AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                            ),
                            child: Icon(
                              Icons.location_on,
                              color: isSelected
                                  ? widget.colorScheme.primary
                                  : AppTheme.textSecondary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingMedium),
                          // Address Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        address['title'] ??
                                            localizations.address,
                                        style: AppTheme.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? widget.colorScheme.primary
                                              : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isDefault)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.success,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          localizations.defaultLabel,
                                          style: AppTheme.poppins(
                                            color: AppTheme.textOnPrimary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getAddressDisplayText(
                                    address,
                                    localizations,
                                  ),
                                  style: AppTheme.poppins(
                                    fontSize: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                if (address['fullAddress'] != null &&
                                    address['fullAddress']
                                        .toString()
                                        .isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      address['fullAddress'].toString(),
                                      style: AppTheme.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary
                                            .withValues(alpha: 0.8),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Check Icon
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: widget.colorScheme.primary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
