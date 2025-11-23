import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile/services/api_service.dart';
import 'dart:async';

class DeliveryTrackingScreen extends StatefulWidget {
  final int orderId;

  const DeliveryTrackingScreen({super.key, required this.orderId});

  @override
  State<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends State<DeliveryTrackingScreen> {
  final ApiService _apiService = ApiService();
  GoogleMapController? _mapController;
  String? _googleMapsApiKey;

  Map<String, dynamic>? _trackingData;
  bool _isLoading = true;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  Future<void> _initializeTracking() async {
    try {
      final apiKey = await _apiService.getGoogleMapsApiKey();
      setState(() {
        _googleMapsApiKey = apiKey;
      });

      await _loadTrackingData();

      // Update tracking data every 10 seconds
      _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _loadTrackingData();
      });
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

  Future<void> _loadTrackingData() async {
    try {
      final data = await _apiService.getDeliveryTracking(widget.orderId);
      setState(() {
        _trackingData = data;
        _isLoading = false;
      });

      _updateMap();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Takip bilgisi yüklenemedi: $e')),
        );
      }
    }
  }

  void _updateMap() {
    if (_trackingData == null || _mapController == null) return;

    final vendorLat = _trackingData!['vendorLatitude'] as num;
    final vendorLng = _trackingData!['vendorLongitude'] as num;
    final deliveryLat = _trackingData!['deliveryLatitude'] as num;
    final deliveryLng = _trackingData!['deliveryLongitude'] as num;

    // Calculate bounds to show all markers
    final bounds = LatLngBounds(
      southwest: LatLng(
        [vendorLat, deliveryLat].reduce((a, b) => a < b ? a : b).toDouble(),
        [vendorLng, deliveryLng].reduce((a, b) => a < b ? a : b).toDouble(),
      ),
      northeast: LatLng(
        [vendorLat, deliveryLat].reduce((a, b) => a > b ? a : b).toDouble(),
        [vendorLng, deliveryLng].reduce((a, b) => a > b ? a : b).toDouble(),
      ),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  Set<Marker> _buildMarkers() {
    if (_trackingData == null) return {};

    final markers = <Marker>{};

    // Vendor marker
    final vendorLat = (_trackingData!['vendorLatitude'] as num).toDouble();
    final vendorLng = (_trackingData!['vendorLongitude'] as num).toDouble();
    markers.add(
      Marker(
        markerId: const MarkerId('vendor'),
        position: LatLng(vendorLat, vendorLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'Market',
          snippet: _trackingData!['vendorAddress'] as String,
        ),
      ),
    );

    // Delivery address marker
    final deliveryLat = (_trackingData!['deliveryLatitude'] as num).toDouble();
    final deliveryLng = (_trackingData!['deliveryLongitude'] as num).toDouble();
    markers.add(
      Marker(
        markerId: const MarkerId('delivery'),
        position: LatLng(deliveryLat, deliveryLng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Teslimat Adresi',
          snippet: _trackingData!['deliveryAddress'] as String,
        ),
      ),
    );

    // Courier marker (if available)
    if (_trackingData!['courierLatitude'] != null &&
        _trackingData!['courierLongitude'] != null) {
      final courierLat = (_trackingData!['courierLatitude'] as num).toDouble();
      final courierLng = (_trackingData!['courierLongitude'] as num).toDouble();
      markers.add(
        Marker(
          markerId: const MarkerId('courier'),
          position: LatLng(courierLat, courierLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: 'Kurye',
            snippet: _trackingData!['courierName'] as String? ?? 'Kurye',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_trackingData == null) return {};

    final polylines = <Polyline>{};

    // Route from vendor to delivery address
    final vendorLat = (_trackingData!['vendorLatitude'] as num).toDouble();
    final vendorLng = (_trackingData!['vendorLongitude'] as num).toDouble();
    final deliveryLat = (_trackingData!['deliveryLatitude'] as num).toDouble();
    final deliveryLng = (_trackingData!['deliveryLongitude'] as num).toDouble();

    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: [
          LatLng(vendorLat, vendorLng),
          LatLng(deliveryLat, deliveryLng),
        ],
        color: Colors.blue,
        width: 3,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );

    // Route from courier to delivery (if courier is available)
    if (_trackingData!['courierLatitude'] != null &&
        _trackingData!['courierLongitude'] != null) {
      final courierLat = (_trackingData!['courierLatitude'] as num).toDouble();
      final courierLng = (_trackingData!['courierLongitude'] as num).toDouble();

      polylines.add(
        Polyline(
          polylineId: const PolylineId('courier_route'),
          points: [
            LatLng(courierLat, courierLng),
            LatLng(deliveryLat, deliveryLng),
          ],
          color: Colors.green,
          width: 4,
        ),
      );
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _googleMapsApiKey == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Teslimat Takibi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_trackingData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Teslimat Takibi')),
        body: const Center(child: Text('Takip bilgisi bulunamadı')),
      );
    }

    final vendorLat = (_trackingData!['vendorLatitude'] as num).toDouble();
    final vendorLng = (_trackingData!['vendorLongitude'] as num).toDouble();
    final deliveryLat = (_trackingData!['deliveryLatitude'] as num).toDouble();
    final deliveryLng = (_trackingData!['deliveryLongitude'] as num).toDouble();

    final centerLat = (vendorLat + deliveryLat) / 2;
    final centerLng = (vendorLng + deliveryLng) / 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teslimat Takibi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrackingData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status card
          Card(
            margin: const EdgeInsets.all(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sipariş #${widget.orderId}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Durum: ${_trackingData!['orderStatus']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_trackingData!['estimatedDeliveryTime'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tahmini Teslimat: ${_formatDateTime(_trackingData!['estimatedDeliveryTime'])}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                  if (_trackingData!['courierName'] != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining, size: 16),
                        const SizedBox(width: 4),
                        Text('Kurye: ${_trackingData!['courierName']}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Map
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(centerLat, centerLng),
                zoom: 12,
              ),
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _updateMap();
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime.toString());
      return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
