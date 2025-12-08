import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/courier_order.dart';
import 'package:mobile/services/location_permission_service.dart';
import 'package:mobile/services/navigation_service.dart';
import 'package:geolocator/geolocator.dart';

class OrderMapScreen extends StatefulWidget {
  final CourierOrder order;

  const OrderMapScreen({super.key, required this.order});

  @override
  State<OrderMapScreen> createState() => _OrderMapScreenState();
}

class _OrderMapScreenState extends State<OrderMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final NavigationService _navigationService = NavigationService();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    print('OrderMapScreen: Initializing map - OrderId: ${widget.order.id}');
    // Get current location
    try {
      _currentPosition = await LocationPermissionService.getCurrentLocation(
        context,
      );
      print(
        'OrderMapScreen: Current location obtained - Lat: ${_currentPosition?.latitude}, Lng: ${_currentPosition?.longitude}',
      );
    } catch (e, stackTrace) {
      print('OrderMapScreen: ERROR getting current location - $e');
      print(stackTrace);
    }

    if (mounted) {
      setState(() {
        _setupMarkers();
      });
      print('OrderMapScreen: Map initialized with markers');
    }
  }

  void _setupMarkers() {
    _markers.clear();

    // Vendor marker (pickup)
    _markers.add(
      Marker(
        markerId: const MarkerId('vendor'),
        position: LatLng(
          widget.order.vendorLatitude,
          widget.order.vendorLongitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: AppLocalizations.of(context)?.pickup ?? 'Pickup',
          snippet: widget.order.vendorName,
        ),
      ),
    );

    // Customer marker (delivery)
    _markers.add(
      Marker(
        markerId: const MarkerId('customer'),
        position: LatLng(
          widget.order.deliveryLatitude,
          widget.order.deliveryLongitude,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: AppLocalizations.of(context)?.delivery ?? 'Delivery',
          snippet: widget.order.customerName,
        ),
      ),
    );

    // Current position marker
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title:
                AppLocalizations.of(context)?.yourLocation ?? 'Your Location',
          ),
        ),
      );
    }

    // Draw route line
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(widget.order.vendorLatitude, widget.order.vendorLongitude),
          LatLng(widget.order.deliveryLatitude, widget.order.deliveryLongitude),
        ],
        color: Colors.blue,
        width: 4,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _fitBounds();
  }

  void _fitBounds() {
    if (_mapController == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        widget.order.vendorLatitude < widget.order.deliveryLatitude
            ? widget.order.vendorLatitude
            : widget.order.deliveryLatitude,
        widget.order.vendorLongitude < widget.order.deliveryLongitude
            ? widget.order.vendorLongitude
            : widget.order.deliveryLongitude,
      ),
      northeast: LatLng(
        widget.order.vendorLatitude > widget.order.deliveryLatitude
            ? widget.order.vendorLatitude
            : widget.order.deliveryLatitude,
        widget.order.vendorLongitude > widget.order.deliveryLongitude
            ? widget.order.vendorLongitude
            : widget.order.deliveryLongitude,
      ),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  Future<void> _launchNavigation() async {
    try {
      // Determine destination based on order status
      // If status is 'Accepted', navigate to Vendor (Pickup)
      // If status is 'OutForDelivery', navigate to Customer (Delivery)
      // Default to Delivery if unsure
      double targetLat = widget.order.deliveryLatitude;
      double targetLng = widget.order.deliveryLongitude;

      if (widget.order.status == 'Accepted' ||
          widget.order.status == 'Assigned') {
        targetLat = widget.order.vendorLatitude;
        targetLng = widget.order.vendorLongitude;
      }

      await _navigationService.launchMap(targetLat, targetLng);
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.couldNotLaunchMaps(e.toString()) ??
                  'Could not launch maps: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order.id} Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () async {
              if (_currentPosition != null && _mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    15,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: LatLng(
            widget.order.vendorLatitude,
            widget.order.vendorLongitude,
          ),
          zoom: 13,
        ),
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        mapType: MapType.normal,
        zoomControlsEnabled: false,
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'recenter',
            onPressed: _fitBounds,
            child: const Icon(Icons.center_focus_strong),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'navigate',
            onPressed: _launchNavigation,
            icon: const Icon(Icons.navigation),
            label: Text(AppLocalizations.of(context)?.navigate ?? 'Navigate'),
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
