import 'package:flutter/material.dart';
import '../../models/delivery_zone_models.dart';
import '../../models/location_item.dart';
import '../../services/api_service.dart';
import '../../config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';

class DeliveryZonesScreen extends StatefulWidget {
  const DeliveryZonesScreen({super.key});

  @override
  State<DeliveryZonesScreen> createState() => _DeliveryZonesScreenState();
}

class _DeliveryZonesScreenState extends State<DeliveryZonesScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool _isSaving = false;

  List<LocationItem> _cities = [];
  LocationItem? _selectedCity;

  CityZoneDto? _cityZoneData;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      final cities = await _apiService.getDeliveryZones() as List<LocationItem>;
      if (mounted) {
        setState(() {
          _cities = cities;
          if (_cities.isNotEmpty) {
            _selectedCity = _cities.first;
            _loadCityData(_selectedCity!.id);
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading cities: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCityData(String cityId) async {
    setState(() => _isLoading = true);
    try {
      final data =
          await _apiService.getDeliveryZones(cityId: cityId) as CityZoneDto;
      if (mounted) {
        setState(() {
          _cityZoneData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading zones: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveZones() async {
    if (_selectedCity == null || _cityZoneData == null) return;

    setState(() => _isSaving = true);
    try {
      final selectedLocalities = <String>[];

      for (var district in _cityZoneData!.districts) {
        for (var locality in district.localities) {
          if (locality.isSelected) {
            selectedLocalities.add(locality.id);
          }
        }
      }

      final dto = DeliveryZoneSyncDto(
        cityId: _selectedCity!.id,
        localityIds: selectedLocalities,
      );

      await _apiService.syncDeliveryZones(dto);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.deliveryZonesUpdated),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving zones: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.deliveryZones),
        actions: [
          if (_selectedCity != null)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveZones,
            ),
        ],
      ),
      body: _isLoading && _cities.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCitySelector(localizations),
                if (_isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_cityZoneData != null)
                  Expanded(child: _buildZonesList()),
              ],
            ),
    );
  }

  Widget _buildCitySelector(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: DropdownButtonFormField<LocationItem>(
        decoration: InputDecoration(
          labelText: localizations.selectCity, // Assumed key, fallback?
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        value: _selectedCity,
        items: _cities.map((city) {
          return DropdownMenuItem(value: city, child: Text(city.name));
        }).toList(),
        onChanged: (val) {
          if (val != null && val != _selectedCity) {
            setState(() {
              _selectedCity = val;
              _cityZoneData = null;
            });
            _loadCityData(val.id);
          }
        },
      ),
    );
  }

  Widget _buildZonesList() {
    if (_cityZoneData!.districts.isEmpty) {
      return const Center(child: Text('No districts found for this city.'));
    }

    return ListView.builder(
      itemCount: _cityZoneData!.districts.length,
      itemBuilder: (context, index) {
        final district = _cityZoneData!.districts[index];
        return ExpansionTile(
          title: Text(
            district.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${district.localities.where((l) => l.isSelected).length} selected',
          ),
          children: district.localities.map((locality) {
            return CheckboxListTile(
              title: Text(locality.name),
              value: locality.isSelected,
              activeColor: AppTheme.vendorPrimary,
              onChanged: (bool? val) {
                setState(() {
                  locality.isSelected = val ?? false;
                });
              },
            );
          }).toList(),
        );
      },
    );
  }
}
