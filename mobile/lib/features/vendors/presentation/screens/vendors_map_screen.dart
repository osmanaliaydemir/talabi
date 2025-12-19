import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/features/products/presentation/screens/customer/product_list_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/location_permission_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/services/logger_service.dart';

class VendorsMapScreen extends StatefulWidget {
  const VendorsMapScreen({super.key});

  @override
  State<VendorsMapScreen> createState() => _VendorsMapScreenState();
}

class _VendorsMapScreenState extends State<VendorsMapScreen> {
  final ApiService _apiService = ApiService();
  GoogleMapController? _mapController;
  String? _googleMapsApiKey;

  LatLng? _userLocation;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _vendors = [];
  bool _isLoading = true;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Get Google Maps API key
      final apiKey = await _apiService.getGoogleMapsApiKey();
      setState(() {
        _googleMapsApiKey = apiKey;
      });

      // Get user location
      await _getUserLocation();

      // Load vendors
      await _loadVendors();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: '${l10n.error}: $e',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationPermissionService.getCurrentLocation(
        context,
      );

      if (position != null && mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });

        // Move camera to user location
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_userLocation!, 13),
          );
        }
      } else {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        _isLoadingLocation = false;
      });
      LoggerService().error('Error getting user location', e, stackTrace);
    }
  }

  Future<void> _loadVendors() async {
    try {
      final vendors = await _apiService.getVendorsForMap(
        userLatitude: _userLocation?.latitude,
        userLongitude: _userLocation?.longitude,
      );

      setState(() {
        _vendors = vendors;
        _isLoading = false;
      });

      _updateMarkers();
    } catch (e, stackTrace) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: l10n.vendorsLoadFailed(e.toString()),
          isSuccess: false,
        );
      }
      LoggerService().error('Error loading vendors', e, stackTrace);
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    final l10n = AppLocalizations.of(context);

    // Add user location marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: l10n?.yourLocation ?? 'Your Location'),
        ),
      );
    }

    // Add vendor markers
    for (final vendorData in _vendors) {
      final vendorId = vendorData['id'] as int;
      final lat = (vendorData['latitude'] as num).toDouble();
      final lng = (vendorData['longitude'] as num).toDouble();
      final name = vendorData['name'] as String;
      final address = vendorData['address'] as String;
      final rating = vendorData['rating'] != null
          ? (vendorData['rating'] as num).toDouble()
          : null;
      final distance = vendorData['distanceInKm'] != null
          ? (vendorData['distanceInKm'] as num).toDouble()
          : null;

      String snippet = address;
      if (rating != null) {
        snippet += '\n⭐ ${rating.toStringAsFixed(1)}';
      }
      if (distance != null) {
        snippet += '\n📍 ${distance.toStringAsFixed(1)} km';
      }

      markers.add(
        Marker(
          markerId: MarkerId('vendor_$vendorId'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(title: name, snippet: snippet),
          onTap: () {
            _showVendorInfo(vendorData);
          },
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showVendorInfo(Map<String, dynamic> vendorData) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vendorData['name'] as String,
              style: AppTheme.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              vendorData['address'] as String,
              style: AppTheme.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            if (vendorData['rating'] != null) ...[
              const SizedBox(height: AppTheme.spacingSmall),
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: AppTheme.iconSizeSmall,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    (vendorData['rating'] as num).toStringAsFixed(1),
                    style: AppTheme.poppins(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
            if (vendorData['distanceInKm'] != null) ...[
              const SizedBox(height: AppTheme.spacingSmall),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: AppTheme.iconSizeSmall,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(vendorData['distanceInKm'] as num).toStringAsFixed(1)} km',
                    style: AppTheme.poppins(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTheme.spacingMedium),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final vendor = Vendor(
                    id: vendorData['id'] as String,
                    name: vendorData['name'] as String,
                    address: vendorData['address'] as String,
                    imageUrl: vendorData['imageUrl'] as String?,
                    city: vendorData['city'] as String?,
                    rating: vendorData['rating'] != null
                        ? (vendorData['rating'] as num?)?.toDouble()
                        : null,
                    ratingCount: vendorData['ratingCount'] as int? ?? 0,
                    latitude: (vendorData['latitude'] as num?)?.toDouble(),
                    longitude: (vendorData['longitude'] as num?)?.toDouble(),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListScreen(vendor: vendor),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryOrange,
                  foregroundColor: AppTheme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(
                  l10n.viewProducts,
                  style: AppTheme.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textOnPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _googleMapsApiKey == null) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryOrange),
        ),
      );
    }

    final initialCameraPosition = _userLocation != null
        ? CameraPosition(target: _userLocation!, zoom: 13)
        : const CameraPosition(
            target: LatLng(41.0082, 28.9784), // Istanbul default
            zoom: 11,
          );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryOrange,
        foregroundColor: AppTheme.textOnPrimary,
        title: Text(
          AppLocalizations.of(context)!.vendorsMap,
          style: AppTheme.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textOnPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: AppTheme.textOnPrimary),
            onPressed: _getUserLocation,
            tooltip: AppLocalizations.of(context)!.findMyLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCameraPosition,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_userLocation != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(_userLocation!, 13),
                );
              }
            },
          ),
          if (_isLoadingLocation)
            Positioned(
              top: AppTheme.spacingMedium,
              right: AppTheme.spacingMedium,
              child: Card(
                color: AppTheme.cardColor,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        AppLocalizations.of(context)!.gettingLocation,
                        style: AppTheme.poppins(
                          fontSize: 12,
                          color: AppTheme.textPrimary,
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
