import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/features/campaigns/data/models/campaign.dart';
import 'package:mobile/widgets/bouncing_circle.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/products/presentation/widgets/product_card.dart';
import 'package:mobile/l10n/app_localizations.dart';

class CampaignDetailScreen extends StatefulWidget {
  const CampaignDetailScreen({super.key, required this.campaign});
  final Campaign campaign;

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  final ApiService _apiService = ApiService();
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await _apiService.getCampaignProducts(
        widget.campaign.id,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.campaign.title,
                style: AppTheme.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -40,
                    bottom: -60,
                    child: BouncingCircle(
                      color: Colors.white.withValues(alpha: 0.2),
                      size: 200,
                    ),
                  ),
                  if (widget.campaign.imageUrl.isNotEmpty)
                    Center(
                      child: ClipOval(
                        child: CachedNetworkImageWidget(
                          imageUrl: widget.campaign.imageUrl,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          maxWidth: 300,
                          maxHeight: 300,
                          errorWidget: const Icon(
                            Icons.local_offer,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.local_offer,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.campaign.title,
                    style: AppTheme.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Text(
                    widget.campaign.description,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLarge),
                  if (widget.campaign.actionUrl != null &&
                      widget.campaign.actionUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final uri = Uri.tryParse(
                              widget.campaign.actionUrl!,
                            );
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: AppTheme.textOnPrimary,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppTheme.spacingMedium,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                            ),
                          ),
                          child: Text(
                            localizations
                                .viewAll, // "Görüntüle" or "Detaylar"? "Tümünü Gör" might fit but maybe "Detaylar" is better
                            style: AppTheme.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Product List Header
                  Text(
                    localizations.products,
                    style: AppTheme.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_products.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    localizations
                        .noCampaignsFound, // Or create new string: "Kampanya ürünü bulunamadı"
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.60,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  return ProductCard(product: _products[index]);
                }, childCount: _products.length),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
