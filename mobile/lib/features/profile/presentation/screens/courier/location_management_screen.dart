import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/profile/data/models/courier.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/services/location_permission_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/features/dashboard/presentation/widgets/courier_header.dart';
import 'package:geolocator/geolocator.dart';

class CourierLocationManagementScreen extends StatefulWidget {
  const CourierLocationManagementScreen({super.key});

  @override
  State<CourierLocationManagementScreen> createState() =>
      _CourierLocationManagementScreenState();
}

class _CourierLocationManagementScreenState
    extends State<CourierLocationManagementScreen> {
  final CourierService _courierService = CourierService();
  Courier? _courier;
  bool _isLoading = true;
  bool _isUpdating = false;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  LatLng? _selectedLocation;

  @override
  void initState() {
    super.initState();
    LoggerService().debug('CourierLocationManagementScreen: initState called');
    _loadProfile();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    LoggerService().debug(
      'CourierLocationManagementScreen: Loading profile...',
    );
    setState(() => _isLoading = true);
    try {
      final courier = await _courierService.getProfile();
      if (!mounted) return;
      setState(() {
        _courier = courier;
        if (courier.currentLatitude != null &&
            courier.currentLongitude != null) {
          _selectedLocation = LatLng(
            courier.currentLatitude!,
            courier.currentLongitude!,
          );
        }
      });
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierLocationManagementScreen: ERROR loading profile',
        e,
        stackTrace,
      );
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations != null
                ? localizations.failedToLoadProfile(e.toString())
                : 'Error loading profile: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationPermissionService.getCurrentLocation(
        context,
      );
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          if (_selectedLocation == null) {
            _selectedLocation = LatLng(position.latitude, position.longitude);
            _moveToLocation(_selectedLocation!);
          }
        });
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierLocationManagementScreen: Error getting current location',
        e,
        stackTrace,
      );
    }
  }

  Future<void> _updateLocationToServer(LatLng location) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      await _courierService.updateLocation(
        location.latitude,
        location.longitude,
      );
      if (!mounted) return;

      // Reload profile to get updated timestamp
      await _loadProfile();
      if (!mounted) return;

      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.locationUpdatedSuccessfully ??
                'Location updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierLocationManagementScreen: Error updating location',
        e,
        stackTrace,
      );
      if (!mounted) return;
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.failedToUpdateLocation ??
                'Failed to update location: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _moveToLocation(LatLng location) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 15));
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _moveToLocation(location);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_selectedLocation != null) {
      _moveToLocation(_selectedLocation!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    // Fallback strings
    const defaultTitle = 'Konum Yönetimi';
    const defaultCurrentLocationInfo = 'Mevcut Konum Bilgisi';
    const defaultLatitude = 'Enlem';
    const defaultLongitude = 'Boylam';
    const defaultLastLocationUpdate = 'Son Güncelleme';
    const defaultNoLocationData = 'Henüz konum bilgisi yok';
    const defaultSelectLocationOnMap = 'Haritada Konum Seç';
    const defaultSelectedLocation = 'Seçilen Konum';
    const defaultUseCurrentLocation = 'Mevcut Konumu Kullan';
    const defaultUpdateLocation = 'Konumu Güncelle';
    const defaultLocationSharingInfo =
        'Konum paylaşımı, yakınındaki restoranlardan sipariş alabilmen için gereklidir. Durumun "Available" olduğunda konumun otomatik olarak paylaşılır.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: localizations?.locationManagement ?? defaultTitle,
        leadingIcon: Icons.location_on,
        showBackButton: true,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : RefreshIndicator(
              onRefresh: () async {
                await _loadProfile();
                await _getCurrentLocation();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Location Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: Colors.teal,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  localizations?.currentLocationInfo ??
                                      defaultCurrentLocationInfo,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_courier?.currentLatitude != null &&
                                _courier?.currentLongitude != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    localizations?.latitude ?? defaultLatitude,
                                    _courier!.currentLatitude!.toStringAsFixed(
                                      6,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    localizations?.longitude ??
                                        defaultLongitude,
                                    _courier!.currentLongitude!.toStringAsFixed(
                                      6,
                                    ),
                                  ),
                                  if (_courier!.lastLocationUpdate != null) ...[
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      localizations?.lastLocationUpdate ??
                                          defaultLastLocationUpdate,
                                      DateFormat('dd MMM yyyy HH:mm').format(
                                        _courier!.lastLocationUpdate!.toLocal(),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            else
                              Text(
                                localizations?.noLocationData ??
                                    defaultNoLocationData,
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Map Section
                    Text(
                      localizations?.selectLocationOnMap ??
                          defaultSelectLocationOnMap,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        height: 300,
                        child: GoogleMap(
                          onMapCreated: _onMapCreated,
                          onTap: _onMapTap,
                          initialCameraPosition: CameraPosition(
                            target:
                                _selectedLocation ??
                                const LatLng(
                                  41.0082, // Istanbul default
                                  28.9784,
                                ),
                            zoom: 13,
                          ),
                          markers: _selectedLocation != null
                              ? {
                                  Marker(
                                    markerId: const MarkerId(
                                      'selected_location',
                                    ),
                                    position: _selectedLocation!,
                                    infoWindow: InfoWindow(
                                      title:
                                          localizations?.selectedLocation ??
                                          defaultSelectedLocation,
                                    ),
                                  ),
                                }
                              : {},
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapType: MapType.normal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUpdating
                                ? null
                                : () async {
                                    await _getCurrentLocation();
                                    if (_currentPosition != null) {
                                      final location = LatLng(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                      );
                                      setState(() {
                                        _selectedLocation = location;
                                      });
                                      _moveToLocation(location);
                                    }
                                  },
                            icon: const Icon(Icons.my_location),
                            label: Text(
                              localizations?.useCurrentLocation ??
                                  defaultUseCurrentLocation,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isUpdating || _selectedLocation == null
                                ? null
                                : () => _updateLocationToServer(
                                    _selectedLocation!,
                                  ),
                            icon: _isUpdating
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(
                              localizations?.updateLocation ??
                                  defaultUpdateLocation,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Location Sharing Info
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blue),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                localizations?.locationSharingInfo ??
                                    defaultLocationSharingInfo,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
