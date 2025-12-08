import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/location_permission_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/screens/customer/widgets/shared_header.dart';

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
    try {
      final position = await LocationPermissionService.getCurrentLocation(
        context,
      );

      if (position != null) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        // Move camera to user location
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
          );
        }

        // Get address for selected location
        await _getAddressFromLocation(_selectedLocation!);
      } else {
        // Use default location if permission denied
        setState(() {
          _isLoading = false;
          _selectedLocation = const LatLng(
            41.0082,
            28.9784,
          ); // Istanbul default
        });
      }
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
    final l10n = AppLocalizations.of(context)!;

    if (_selectedLocation == null || _selectedAddress == null) {
      ToastMessage.show(
        context,
        message: l10n.pleaseSelectLocation,
        isSuccess: false,
      );
      return;
    }

    // Title is optional - if empty, use a default value
    final title = _titleController.text.trim().isEmpty
        ? l10n.selectedLocation
        : _titleController.text.trim();

    if (widget.onAddressSelected != null) {
      widget.onAddressSelected!(
        title,
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
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading || _googleMapsApiKey == null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Column(
          children: [
            SharedHeader(
              title: l10n.selectAddress,
              subtitle: l10n.selectLocationFromMap,
              icon: Icons.map,
              showBackButton: true,
            ),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }

    final initialCameraPosition = _selectedLocation != null
        ? CameraPosition(target: _selectedLocation!, zoom: 16)
        : const CameraPosition(target: LatLng(41.0082, 28.9784), zoom: 11);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Header
          SharedHeader(
            title: l10n.selectAddress,
            subtitle: l10n.selectLocationFromMap,
            icon: Icons.map,
            showBackButton: true,
            action: GestureDetector(
              onTap: _getUserLocation,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          // Map and Address Form
          Expanded(
            child: Column(
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
                              CameraUpdate.newLatLngZoom(
                                _selectedLocation!,
                                16,
                              ),
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
                        child: Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ),
                // Address info card
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context)!;
                    final cardColorScheme = Theme.of(context).colorScheme;
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: l10n.addressTitleOptional,
                                border: const OutlineInputBorder(),
                                helperText: l10n.canBeLeftEmpty,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_isLoadingAddress)
                              Center(
                                child: CircularProgressIndicator(
                                  color: cardColorScheme.primary,
                                ),
                              )
                            else if (_selectedAddress != null) ...[
                              Text(
                                '${l10n.address}:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_selectedAddress!),
                              if (_selectedCity != null &&
                                  _selectedCity!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('${l10n.city}: $_selectedCity'),
                              ],
                              if (_selectedDistrict != null &&
                                  _selectedDistrict!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('${l10n.district}: $_selectedDistrict'),
                              ],
                            ] else
                              Text(
                                l10n.selectOrDragMarkerOnMap,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveAddress,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cardColorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  l10n.saveAddressButton,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
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
