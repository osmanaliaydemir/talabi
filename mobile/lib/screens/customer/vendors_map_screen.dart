import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
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
            const SnackBar(content: Text('Konum servisleri kapalı')),
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
              const SnackBar(content: Text('Konum izni reddedildi')),
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
            const SnackBar(
              content: Text('Konum izni kalıcı olarak reddedildi'),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Marketler yüklenemedi: $e')));
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              vendorData['name'] as String,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(vendorData['address'] as String),
            if (vendorData['rating'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    (vendorData['rating'] as num).toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            if (vendorData['distanceInKm'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${(vendorData['distanceInKm'] as num).toStringAsFixed(1)} km',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
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
                child: const Text('Ürünleri Görüntüle'),
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
      return Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
    }

    final initialCameraPosition = _userLocation != null
        ? CameraPosition(target: _userLocation!, zoom: 13)
        : const CameraPosition(
            target: LatLng(41.0082, 28.9784), // Istanbul default
            zoom: 11,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketler Haritası'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
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
            const Positioned(
              top: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Konum alınıyor...'),
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
