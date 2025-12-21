import 'package:flutter/material.dart';
import 'package:mobile/features/campaigns/data/models/campaign.dart';
import 'package:mobile/features/cart/presentation/providers/cart_provider.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:provider/provider.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/features/settings/data/models/currency.dart';

class CampaignSelectionBottomSheet extends StatefulWidget {
  const CampaignSelectionBottomSheet({super.key});

  @override
  State<CampaignSelectionBottomSheet> createState() =>
      _CampaignSelectionBottomSheetState();
}

class _CampaignSelectionBottomSheetState
    extends State<CampaignSelectionBottomSheet> {
  final ApiService _apiService = ApiService();
  late Future<List<Campaign>> _campaignsFuture;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  void _loadCampaigns() {
    _campaignsFuture = _fetchCampaignsWithContext();
  }

  Future<List<Campaign>> _fetchCampaignsWithContext() async {
    int? vendorType;
    String? cityId;
    String? districtId;

    if (mounted) {
      // Try to get vendorType from Cart first
      final cart = Provider.of<CartProvider>(context, listen: false);
      if (cart.items.isNotEmpty) {
        vendorType = cart.items.values.first.product.vendorType;
      }

      // Fallback to Bottom Nav if cart is empty or vendorType missing
      if (vendorType == null) {
        final bottomNav = Provider.of<BottomNavProvider>(
          context,
          listen: false,
        );
        vendorType = bottomNav.selectedCategory == MainCategory.restaurant
            ? 1
            : 2;
      }
    }

    try {
      final addresses = await _apiService.getAddresses();
      if (addresses.isNotEmpty) {
        final defaultAddr =
            addresses.firstWhere(
                  (a) => a['isDefault'] == true,
                  orElse: () => addresses.first,
                )
                as Map<String, dynamic>;

        if (defaultAddr['cityId'] != null) {
          cityId = defaultAddr['cityId'].toString();
        }
        if (defaultAddr['districtId'] != null) {
          districtId = defaultAddr['districtId'].toString();
        }
      }
    } catch (_) {
      // Ignore address errors
    }

    return _apiService.getCampaigns(
      vendorType: vendorType,
      cityId: cityId,
      districtId: districtId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.campaigns,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (cart.selectedCampaign != null)
                  TextButton(
                    onPressed: () {
                      cart.removeCampaign();
                      Navigator.pop(context);
                    },
                    child: Text(
                      localizations.clear,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(),
          // Content
          Expanded(
            child: FutureBuilder<List<Campaign>>(
              future: _campaignsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('${localizations.error}: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(localizations.noResultsFound));
                }

                final campaigns = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: campaigns.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final campaign = campaigns[index];
                    final isSelected = cart.selectedCampaign?.id == campaign.id;
                    final isApplicable =
                        campaign.minCartAmount == null ||
                        cart.subtotalAmount >= campaign.minCartAmount!;

                    return Opacity(
                      opacity: isApplicable ? 1.0 : 0.5,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.1)
                              : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: campaign.imageUrl.isNotEmpty
                                  ? CachedNetworkImageWidget(
                                      imageUrl: campaign.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      child: Icon(
                                        Icons.local_offer,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    campaign.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    campaign.description,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (campaign.minCartAmount != null &&
                                      campaign.minCartAmount! > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Min. Sepet: ${CurrencyFormatter.format(campaign.minCartAmount!, Currency.try_)}',
                                      style: TextStyle(
                                        color: isApplicable
                                            ? Colors.green
                                            : Colors.red,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Action
                            if (isApplicable)
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await cart.selectCampaign(campaign);
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Kampanya uygulandı!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceAll(
                                              'Exception: ',
                                              '',
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? Colors.grey
                                      : colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  minimumSize: const Size(0, 36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text(isSelected ? 'Seçili' : 'Seç'),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
