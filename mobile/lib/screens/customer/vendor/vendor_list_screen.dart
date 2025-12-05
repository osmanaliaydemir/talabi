import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/vendor.dart';
import 'package:mobile/screens/customer/vendor/vendor_detail_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/customer/widgets/shared_header.dart';
import 'package:mobile/widgets/common/cached_network_image_widget.dart';

class VendorListScreen extends StatefulWidget {
  const VendorListScreen({super.key});

  @override
  State<VendorListScreen> createState() => _VendorListScreenState();
}

class _VendorListScreenState extends State<VendorListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Vendor>> _vendorsFuture;

  int? _vendorCount;

  @override
  void initState() {
    super.initState();
    _vendorsFuture = _apiService.getVendors().then((vendors) {
      if (mounted) {
        setState(() {
          _vendorCount = vendors.length;
        });
      }
      return vendors;
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          SharedHeader(
            title: localizations.popularVendors,
            subtitle: _vendorCount != null
                ? localizations.vendorsCount(_vendorCount!)
                : null,
            showBackButton: true,
            onBack: () => Navigator.of(context).pop(),
            icon: Icons.store,
          ),
          Expanded(
            child: FutureBuilder<List<Vendor>>(
              future: _vendorsFuture,
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

                final vendors = snapshot.data!;
                return ListView.separated(
                  padding: EdgeInsets.all(AppTheme.spacingMedium),
                  itemCount: vendors.length,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: AppTheme.spacingMedium),
                  itemBuilder: (context, index) {
                    return _buildVendorCard(vendors[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VendorDetailScreen(vendor: vendor),
          ),
        );
      },
      child: Container(
        decoration: AppTheme.cardDecoration(
          color: Theme.of(context).cardColor,
          context: context,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                children: [
                  vendor.imageUrl != null
                      ? OptimizedCachedImage.vendorLogo(
                          imageUrl: vendor.imageUrl!,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: BorderRadius.zero,
                        )
                      : Container(
                          color: AppTheme.textSecondary.withOpacity(0.1),
                          child: Icon(
                            Icons.store,
                            size: 50,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                  if (vendor.rating != null && vendor.rating! > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber[600],
                            ),
                            SizedBox(width: 4),
                            Text(
                              vendor.rating!.toStringAsFixed(1),
                              style: AppTheme.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.name,
                    style: AppTheme.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  if (vendor.address.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vendor.address,
                            style: AppTheme.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (vendor.distanceInKm != null) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.navigation,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${vendor.distanceInKm!.toStringAsFixed(1)} km',
                          style: AppTheme.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
