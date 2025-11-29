import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/models/vendor.dart';
import 'package:mobile/screens/customer/product_list_screen.dart';
import 'package:mobile/services/api_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Konum servisleri kapalı',
                style: AppTheme.poppins(color: AppTheme.textOnPrimary),
              ),
              backgroundColor: AppTheme.warning,
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Konum izni reddedildi',
                  style: AppTheme.poppins(color: AppTheme.textOnPrimary),
                ),
                backgroundColor: AppTheme.error,
              ),
            );
          }
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Konum izni kalıcı olarak reddedildi',
                style: AppTheme.poppins(color: AppTheme.textOnPrimary),
              ),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
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
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      print('Error getting user location: $e');
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
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marketler yüklenemedi: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Add user location marker
    if (_userLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Konumunuz'),
        ),
      );
    }

    // Add vendor markers
    for (var vendorData in _vendors) {
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(AppTheme.spacingMedium),
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
            SizedBox(height: AppTheme.spacingSmall),
            Text(
              vendorData['address'] as String,
              style: AppTheme.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            if (vendorData['rating'] != null) ...[
              SizedBox(height: AppTheme.spacingSmall),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: AppTheme.iconSizeSmall,
                  ),
                  SizedBox(width: 4),
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
              SizedBox(height: AppTheme.spacingSmall),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: AppTheme.iconSizeSmall,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '${(vendorData['distanceInKm'] as num).toStringAsFixed(1)} km',
                    style: AppTheme.poppins(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
            SizedBox(height: AppTheme.spacingMedium),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  final vendor = Vendor(
                    id: vendorData['id'],
                    name: vendorData['name'],
                    address: vendorData['address'],
                    imageUrl: vendorData['imageUrl'],
                    city: vendorData['city'],
                    rating: vendorData['rating'] != null
                        ? (vendorData['rating'] as num).toDouble()
                        : null,
                    ratingCount: vendorData['ratingCount'] ?? 0,
                    latitude: (vendorData['latitude'] as num).toDouble(),
                    longitude: (vendorData['longitude'] as num).toDouble(),
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
                  padding: EdgeInsets.symmetric(
                    vertical: AppTheme.spacingMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(
                  'Ürünleri Görüntüle',
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
      return Scaffold(
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
          'Marketler Haritası',
          style: AppTheme.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textOnPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.my_location, color: AppTheme.textOnPrimary),
            onPressed: _getUserLocation,
            tooltip: 'Konumumu Bul',
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
                  padding: EdgeInsets.all(AppTheme.spacingSmall),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryOrange,
                        ),
                      ),
                      SizedBox(width: AppTheme.spacingSmall),
                      Text(
                        'Konum alınıyor...',
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
