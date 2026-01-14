import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/profile/data/models/address.dart';
import 'package:mobile/features/profile/presentation/screens/customer/add_edit_address_screen.dart';
import 'package:mobile/features/profile/presentation/providers/address_provider.dart';
import 'package:provider/provider.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/features/home/presentation/widgets/shared_header.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';
import 'package:mobile/widgets/empty_state_widget.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().loadAddresses();
    });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _deleteAddress(String id) async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => CustomConfirmationDialog(
        title: l10n.deleteAddressTitle,
        message: l10n.deleteAddressConfirm,
        confirmText: l10n.delete,
        cancelText: l10n.cancel,
        icon: Icons.delete_outline,
        iconColor: Colors.red,
        confirmButtonColor: Colors.red,
        onConfirm: () => Navigator.pop(dialogContext, true),
        onCancel: () => Navigator.pop(dialogContext, false),
      ),
    );

    if (confirm == true && mounted) {
      try {
        await context.read<AddressProvider>().deleteAddress(id);
        if (mounted) {
          ToastMessage.show(
            context,
            message: l10n.addressDeleted,
            isSuccess: true,
          );
        }
      } catch (e) {
        if (mounted) {
          ToastMessage.show(
            context,
            message: '${l10n.error}: $e',
            isSuccess: false,
          );
        }
      }
    }
  }

  Future<void> _setDefaultAddress(String id) async {
    final l10n = AppLocalizations.of(context)!;

    try {
      await context.read<AddressProvider>().setDefaultAddress(id);
      if (mounted) {
        ToastMessage.show(
          context,
          message: l10n.defaultAddressUpdated,
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastMessage.show(
          context,
          message: '${l10n.error}: $e',
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<AddressProvider>(
        builder: (context, provider, child) {
          final addresses = provider.addresses;
          final isLoading = provider.isLoading;

          return Column(
            children: [
              // Header
              SharedHeader(
                title: localizations.myAddresses,
                subtitle: addresses.length == 1
                    ? localizations.addressCountSingular
                    : localizations.addressCountPlural(addresses.length),
                icon: Icons.location_on,
                showBackButton: true,
              ),
              // Main Content
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: colorScheme.primary,
                          ),
                        )
                      : addresses.isEmpty
                      ? _buildEmptyState()
                      : SingleChildScrollView(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 20),
                                      // Animated Logo/Icon
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: const Duration(
                                          milliseconds: 1200,
                                        ),
                                        curve: Curves.elasticOut,
                                        builder: (context, value, child) {
                                          final colorScheme = Theme.of(
                                            context,
                                          ).colorScheme;
                                          return Transform.scale(
                                            scale: value,
                                            child: Transform.rotate(
                                              angle: (1 - value) * 2 * math.pi,
                                              child: Container(
                                                width: 90,
                                                height: 90,
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary
                                                      .withValues(alpha: 0.1),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      blurRadius: 15,
                                                      spreadRadius: 3,
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  Icons.location_on,
                                                  size: 40,
                                                  color: colorScheme.primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 32),
                                      // Title
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: const Duration(
                                          milliseconds: 800,
                                        ),
                                        curve: Curves.easeOut,
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                20 * (1 - value),
                                              ),
                                              child: Text(
                                                localizations.myAddresses,
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                  letterSpacing: 1.0,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: const Duration(
                                          milliseconds: 1000,
                                        ),
                                        curve: Curves.easeOut,
                                        builder: (context, value, child) {
                                          return Opacity(
                                            opacity: value,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                20 * (1 - value),
                                              ),
                                              child: Text(
                                                localizations
                                                    .manageDeliveryAddresses,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  letterSpacing: 0.5,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 40),
                                      // Address Cards
                                      ...List.generate(
                                        addresses.length,
                                        (
                                          index,
                                        ) => TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          duration: Duration(
                                            milliseconds: 600 + (index * 150),
                                          ),
                                          curve: Curves.easeOutCubic,
                                          builder: (context, value, child) {
                                            return Opacity(
                                              opacity: value,
                                              child: Transform.translate(
                                                offset: Offset(
                                                  50 * (1 - value),
                                                  0,
                                                ),
                                                child: Transform.scale(
                                                  scale: 0.8 + (0.2 * value),
                                                  child: _buildAddressCard(
                                                    addresses[index],
                                                    index,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditAddressScreen(),
            ),
          );
          if (result == true) {
            // context.read<AddressProvider>().loadAddresses();
            // Provider handles reload automatically if logic is there, but for safety in nav back
          }
        },
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    return EmptyStateWidget(
      message: localizations.noAddressesYet,
      subMessage: localizations.addressEmptySubMessage,
      iconData: Icons.location_off_outlined,
      actionLabel: localizations.addAddress,
      onAction: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
        );
        if (result == true) {
          // context.read<AddressProvider>().loadAddresses();
        }
      },
      isCompact: true,
    );
  }

  Widget _buildAddressCard(Address address, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditAddressScreen(address: address),
              ),
            );
            if (result == true) {
              // context.read<AddressProvider>().loadAddresses();
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: address.isDefault
                    ? colorScheme.primary
                    : Colors.grey[300]!,
                width: address.isDefault ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: address.isDefault
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: address.isDefault ? 15 : 10,
                  spreadRadius: address.isDefault ? 1 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: address.isDefault
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.grey[100],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: address.isDefault
                          ? colorScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    address.isDefault ? Icons.home : Icons.location_on,
                    color: address.isDefault
                        ? colorScheme.primary
                        : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Address Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              address.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: address.isDefault
                                    ? colorScheme.primary
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (address.isDefault)
                            Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context)!;
                                final cardColorScheme = Theme.of(
                                  context,
                                ).colorScheme;
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardColorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    l10n.defaultLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        address.fullAddress,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${address.districtName ?? ''}, ${address.cityName ?? ''}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Menu Button
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    return PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.edit),
                            ],
                          ),
                        ),
                        if (!address.isDefault)
                          PopupMenuItem(
                            value: 'default',
                            child: Row(
                              children: [
                                const Icon(Icons.check, size: 20),
                                const SizedBox(width: 8),
                                Text(l10n.setAsDefault),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.delete,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'edit') {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddEditAddressScreen(address: address),
                            ),
                          );
                          if (result == true) {
                            // context.read<AddressProvider>().loadAddresses();
                          }
                        } else if (value == 'default') {
                          _setDefaultAddress(address.id);
                        } else if (value == 'delete') {
                          _deleteAddress(address.id);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
