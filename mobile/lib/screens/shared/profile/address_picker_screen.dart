import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mobile/services/api_service.dart';

class AddressPickerScreen extends StatefulWidget {
  final Function(
    String title,
    String fullAddress,
    String city,
    String district,
    String? postalCode,
    double latitude,
    double longitude,
  )?
  onAddressSelected;

  const AddressPickerScreen({super.key, this.onAddressSelected});

  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _titleController = TextEditingController();
  GoogleMapController? _mapController;
  String? _googleMapsApiKey;

  LatLng? _selectedLocation;
  String? _selectedAddress;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _postalCode;
  bool _isLoading = true;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      final apiKey = await _apiService.getGoogleMapsApiKey();
      setState(() {
        _googleMapsApiKey = apiKey;
      });

      await _getUserLocation();
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
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Konum servisleri kapalı')),
          );
        }
        setState(() {
          _isLoading = false;
          _selectedLocation = const LatLng(
            41.0082,
            28.9784,
          ); // Istanbul default
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoading = false;
          _selectedLocation = const LatLng(
            41.0082,
            28.9784,
          ); // Istanbul default
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      await _getAddressFromLocation(_selectedLocation!);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _selectedLocation = const LatLng(41.0082, 28.9784); // Istanbul default
      });
    }
  }

  Future<void> _getAddressFromLocation(LatLng location) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        setState(() {
          _selectedAddress = _buildAddressString(place);
          _selectedCity = place.locality ?? place.subAdministrativeArea ?? '';
          _selectedDistrict =
              place.subLocality ?? place.administrativeArea ?? '';
          _postalCode = place.postalCode;
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingAddress = false;
      });
      print('Error getting address: $e');
    }
  }

  String _buildAddressString(Placemark place) {
    final parts = <String>[];
    if (place.street != null) parts.add(place.street!);
    if (place.subThoroughfare != null) parts.add(place.subThoroughfare!);
    if (place.thoroughfare != null) parts.add(place.thoroughfare!);
    if (place.subLocality != null) parts.add(place.subLocality!);
    if (place.locality != null) parts.add(place.locality!);
    return parts.join(', ');
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _getAddressFromLocation(location);
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _selectedLocation = position.target;
    });
  }

  void _onCameraIdle() {
    if (_selectedLocation != null) {
      _getAddressFromLocation(_selectedLocation!);
    }
  }

  void _saveAddress() {
    if (_selectedLocation == null || _selectedAddress == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir konum seçin')));
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lütfen bir başlık girin')));
      return;
    }

    if (widget.onAddressSelected != null) {
      widget.onAddressSelected!(
        _titleController.text.trim(),
        _selectedAddress!,
        _selectedCity ?? '',
        _selectedDistrict ?? '',
        _postalCode,
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _googleMapsApiKey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Adres Seç')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final initialCameraPosition = _selectedLocation != null
        ? CameraPosition(target: _selectedLocation!, zoom: 16)
        : const CameraPosition(target: LatLng(41.0082, 28.9784), zoom: 11);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adres Seç'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getUserLocation,
            tooltip: 'Konumumu Bul',
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: initialCameraPosition,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (_selectedLocation != null) {
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(_selectedLocation!, 16),
                      );
                    }
                  },
                  onTap: _onMapTap,
                  onCameraMove: _onCameraMove,
                  onCameraIdle: _onCameraIdle,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: _selectedLocation!,
                            draggable: true,
                            onDragEnd: (LatLng newPosition) {
                              setState(() {
                                _selectedLocation = newPosition;
                              });
                              _getAddressFromLocation(newPosition);
                            },
                          ),
                        }
                      : {},
                ),
                // Center indicator
                Center(
                  child: Icon(Icons.location_on, color: Colors.red, size: 40),
                ),
              ],
            ),
          ),
          // Address info card
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Adres Başlığı (örn: Ev, İş)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoadingAddress)
                    const Center(child: CircularProgressIndicator())
                  else if (_selectedAddress != null) ...[
                    Text(
                      'Adres:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_selectedAddress!),
                    if (_selectedCity != null && _selectedCity!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Şehir: $_selectedCity'),
                    ],
                    if (_selectedDistrict != null &&
                        _selectedDistrict!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('İlçe: $_selectedDistrict'),
                    ],
                  ] else
                    const Text(
                      'Haritada bir konum seçin veya işaretçiyi sürükleyin',
                      style: TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveAddress,
                      child: const Text('Adresi Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
