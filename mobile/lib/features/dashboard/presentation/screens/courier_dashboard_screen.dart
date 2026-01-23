import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:mobile/config/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/profile/data/models/courier.dart';
import 'package:mobile/features/orders/data/models/courier_order.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/services/location_service.dart';
import 'package:mobile/services/location_permission_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/features/dashboard/presentation/widgets/courier_header.dart';
import 'package:mobile/features/dashboard/presentation/widgets/courier_bottom_nav.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';
import 'package:mobile/config/injection.dart';
import 'package:mobile/services/signalr_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile/widgets/pending_approval_widget.dart';

class CourierDashboardScreen extends StatefulWidget {
  const CourierDashboardScreen({super.key});

  @override
  State<CourierDashboardScreen> createState() => _CourierDashboardScreenState();
}

class _CourierDashboardScreenState extends State<CourierDashboardScreen> {
  final CourierService _courierService = CourierService();
  final NotificationService _notificationService = NotificationService();
  final SignalRService _signalRService = getIt<SignalRService>();

  late final LocationService _locationService;
  Courier? _courier;
  CourierStatistics? _statistics;
  List<CourierOrder> _activeOrders = [];
  bool _isLoading = true;
  bool _isStatusUpdating = false;
  final Set<String> _processingOrders = {};

  StreamSubscription? _orderAssignedSubscription;
  StreamSubscription? _signalRSubscription;

  @override
  void initState() {
    super.initState();

    _locationService = LocationService(_courierService);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _locationService.setContext(context);
      }
    });
    _loadData();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    await _notificationService.init();

    // SignalR bağlantısını başlat
    await _signalRService.startConnection();

    // Listen to the broadcast stream (FCM)
    _orderAssignedSubscription = _notificationService.orderAssignedStream
        .listen((orderId) {
          _handleNewOrder(orderId);
        });

    // Listen to SignalR stream (Real-time)
    _signalRSubscription = _signalRService.onOrderAssigned.listen((data) {
      if (data.containsKey('orderId')) {
        final orderId = data['orderId'].toString();
        _handleNewOrder(orderId);

        // Trigger sound and vibration via local notification
        _notificationService.showManualNotification(
          title: 'Yeni Sipariş!',
          body: 'Sipariş #$orderId size atandı. Hemen inceleyin!',
          payload: json.encode({'orderId': orderId, 'type': 'order_assigned'}),
        );
      }
    });
  }

  void _handleNewOrder(String orderId) {
    // Reload data when new order is assigned
    _loadData();
    // Show snackbar
    if (mounted) {
      final localizations = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizations?.newOrderAssigned(orderId) ??
                'New order #$orderId assigned!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              // Navigate to order details if needed, or just let them see the updated list
              // For now, reloading the list is enough as it appears in "Active Orders" section usually
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _orderAssignedSubscription?.cancel();
    _signalRSubscription?.cancel();
    _notificationService.stop();
    _locationService.stopLocationTracking();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courier = await _courierService.getProfile();

      // Start location tracking if courier is available
      if (courier.status == 'Available') {
        await _locationService.startLocationTracking();
      } else {
        _locationService.stopLocationTracking();
      }

      final statistics = await _courierService.getStatistics();

      final orders = await _courierService.getActiveOrders();

      if (mounted) {
        setState(() {
          _courier = courier;
          _statistics = statistics;
          _activeOrders = orders;
          _isLoading = false;
        });

        // SignalR grubuna courierId ile katıl (profil yüklendikten sonra)
        if (courier.id.isNotEmpty) {
          await _signalRService.joinCourierGroupWithId(courier.id);
        }

        // Check if vehicle type is not selected
        if (courier.vehicleType == null || courier.vehicleType!.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showVehicleTypeBottomSheet();
          });
        }
        // Check if working hours are not set
        else if (courier.workingHoursStart == null ||
            courier.workingHoursEnd == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showWorkingHoursBottomSheet();
          });
        }
        // Check if location is not set (only if vehicle type is already selected)
        else if (courier.currentLatitude == null ||
            courier.currentLongitude == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showLocationSelectionBottomSheet();
          });
        }
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierDashboardScreen: ERROR loading data',
        e,
        stackTrace,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Failed to')
                  ? e.toString()
                  : (localizations?.failedToLoadActiveOrders ??
                        'Error loading data: $e'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _toggleStatus(bool value) async {
    if (_courier == null) {
      LoggerService().warning(
        'CourierDashboardScreen: Cannot toggle status - courier is null',
      );
      return;
    }

    final newStatus = value ? 'Available' : 'Offline';

    setState(() {
      _isStatusUpdating = true;
    });

    try {
      await _courierService.updateStatus(newStatus);

      // Handle location tracking based on new status
      if (value) {
        await _locationService.startLocationTracking();
      } else {
        _locationService.stopLocationTracking();
      }

      await _loadData(); // Reload to get updated profile
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierDashboardScreen: ERROR updating status',
        e,
        stackTrace,
      );
      if (mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Failed to')
                  ? e.toString()
                  : (localizations?.failedToUpdateStatus ??
                        'Error updating status: $e'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStatusUpdating = false;
        });
      }
    }
  }

  Future<void> _showVehicleTypeBottomSheet() async {
    final vehicleTypes = [
      {
        'key': 'Motorcycle',
        'name': _getLocalizedString(context, 'motorcycle', 'Motor'),
        'icon': Icons.motorcycle,
      },
      {
        'key': 'Car',
        'name': _getLocalizedString(context, 'car', 'Araba'),
        'icon': Icons.directions_car,
      },
      {
        'key': 'Bicycle',
        'name': _getLocalizedString(context, 'bicycle', 'Bisiklet'),
        'icon': Icons.pedal_bike,
      },
    ];

    String? selectedVehicleType;

    await showModalBottomSheet(
      context: context,
      isDismissible: false, // Zorunlu - kapatılamaz
      enableDrag: false, // Zorunlu - sürüklenemez
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    _getLocalizedString(
                      context,
                      'selectVehicleType',
                      'Araç Türü Seçin',
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    _getLocalizedString(
                      context,
                      'selectVehicleTypeDescription',
                      'Lütfen kullanacağınız araç türünü seçin. Bu seçim zorunludur.',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Vehicle type options
                  ...vehicleTypes.map((vehicle) {
                    final isSelected = selectedVehicleType == vehicle['key'];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedVehicleType = vehicle['key'] as String;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.courierPrimary.withValues(alpha: 0.1)
                              : Colors.grey[100],
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.courierPrimary
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              vehicle['icon'] as IconData,
                              size: 32,
                              color: isSelected
                                  ? AppTheme.courierPrimary
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                vehicle['name'] as String,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? AppTheme.courierPrimary
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppTheme.courierPrimary,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: selectedVehicleType != null
                          ? () async {
                              Navigator.of(context).pop();
                              await _updateVehicleType(selectedVehicleType!);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.courierPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _getLocalizedString(context, 'save', 'Kaydet'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateVehicleType(String vehicleType) async {
    try {
      await _courierService.updateProfile({'vehicleType': vehicleType});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getLocalizedString(
                context,
                'vehicleTypeUpdatedSuccessfully',
                'Araç türü başarıyla güncellendi',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reload data to get updated profile
        await _loadData();

        // Show location selection bottom sheet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showLocationSelectionBottomSheet();
        });
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierDashboardScreen: ERROR updating vehicle type',
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getLocalizedString(
                context,
                'failedToUpdateVehicleType',
                'Araç türü güncellenemedi: $e',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showWorkingHoursBottomSheet() async {
    TimeOfDay? startTime;
    TimeOfDay? endTime;
    String? errorMessage;

    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            Future<void> selectTime(bool isStart) async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: isStart
                    ? (startTime ?? const TimeOfDay(hour: 9, minute: 0))
                    : (endTime ?? const TimeOfDay(hour: 18, minute: 0)),
              );
              if (picked != null) {
                setState(() {
                  if (isStart) {
                    startTime = picked;
                  } else {
                    endTime = picked;
                  }
                });
              }
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    _getLocalizedString(
                      context,
                      'workingHoursRequired',
                      'Çalışma Saatleri Zorunludur',
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getLocalizedString(
                      context,
                      'workingHoursRequiredDescription',
                      'Sipariş almaya başlamak için lütfen çalışma saatlerinizi belirleyin.',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getLocalizedString(
                                context,
                                'workingHoursStart',
                                'Başlangıç Saati',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => selectTime(true),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      startTime?.format(context) ??
                                          _getLocalizedString(
                                            context,
                                            'selectTime',
                                            'Saat Seçin',
                                          ),
                                      style: TextStyle(
                                        color: startTime != null
                                            ? AppTheme.textPrimary
                                            : AppTheme.textSecondary,
                                        fontWeight: startTime != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.access_time,
                                      color: AppTheme.courierPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getLocalizedString(
                                context,
                                'workingHoursEnd',
                                'Bitiş Saati',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => selectTime(false),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      endTime?.format(context) ??
                                          _getLocalizedString(
                                            context,
                                            'selectTime',
                                            'Saat Seçin',
                                          ),
                                      style: TextStyle(
                                        color: endTime != null
                                            ? AppTheme.textPrimary
                                            : AppTheme.textSecondary,
                                        fontWeight: endTime != null
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.access_time,
                                      color: AppTheme.courierPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: startTime != null && endTime != null
                          ? () async {
                              setState(() {
                                errorMessage = null;
                              });
                              try {
                                await _updateWorkingHours(startTime!, endTime!);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              } catch (e) {
                                setState(() {
                                  errorMessage = e.toString();
                                });
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.courierPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text(
                        _getLocalizedString(context, 'save', 'Kaydet'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateWorkingHours(
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    final startString =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endString =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

    try {
      await _courierService.updateProfile({
        'workingHoursStart': startString,
        'workingHoursEnd': endString,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getLocalizedString(
                context,
                'workingHoursUpdatedSuccessfully',
                'Çalışma saatleri başarıyla güncellendi',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData();
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierDashboardScreen: ERROR updating working hours',
        e,
        stackTrace,
      );
      throw _getLocalizedString(
        // ignore: use_build_context_synchronously
        context,
        'failedToUpdateWorkingHours',
        'Çalışma saatleri güncellenemedi',
      );
    }
  }

  Future<void> _showLocationSelectionBottomSheet() async {
    double? selectedLatitude;
    double? selectedLongitude;
    bool isGettingLocation = false;
    String? errorMessage;

    await showModalBottomSheet(
      context: context,
      isDismissible: false, // Zorunlu - kapatılamaz
      enableDrag: false, // Zorunlu - sürüklenemez
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            Future<void> getCurrentLocation() async {
              setState(() {
                isGettingLocation = true;
                errorMessage = null;
              });

              try {
                // First check if location services are enabled
                final serviceEnabled =
                    await LocationPermissionService.checkLocationServices(
                      context,
                    );
                if (!context.mounted) return;
                if (!serviceEnabled) {
                  setState(() {
                    isGettingLocation = false;
                    errorMessage = _getLocalizedString(
                      context,
                      'locationServicesDisabledMessage',
                      'Konum servisleri kapalı. Lütfen ayarlardan açın.',
                    );
                  });
                  return;
                }

                final position =
                    await LocationPermissionService.getCurrentLocation(context);
                if (!context.mounted) return;
                if (position != null) {
                  setState(() {
                    selectedLatitude = position.latitude;
                    selectedLongitude = position.longitude;
                    isGettingLocation = false;
                  });
                } else {
                  setState(() {
                    isGettingLocation = false;
                    errorMessage = _getLocalizedString(
                      context,
                      'failedToUpdateLocation',
                      'Konum alınamadı',
                    );
                  });
                }
              } catch (e) {
                setState(() {
                  isGettingLocation = false;
                  errorMessage = e.toString();
                });
              }
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    _getLocalizedString(
                      context,
                      'selectLocationRequired',
                      'Konum Seçimi Zorunlu',
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    _getLocalizedString(
                      context,
                      'selectLocationRequiredDescription',
                      'Lütfen konumunuzu seçin. Bu bilgi sipariş almak için gereklidir.',
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Location info
                  if (selectedLatitude != null && selectedLongitude != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.courierPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.courierPrimary,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppTheme.courierPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getLocalizedString(
                                  context,
                                  'selectedLocation',
                                  'Seçilen Konum',
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.courierPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lat: ${selectedLatitude!.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            'Lng: ${selectedLongitude!.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Use current location button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isGettingLocation ? null : getCurrentLocation,
                      icon: isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        isGettingLocation
                            ? _getLocalizedString(
                                context,
                                'gettingCurrentLocation',
                                'Konumunuz alınıyor...',
                              )
                            : _getLocalizedString(
                                context,
                                'useCurrentLocation',
                                'Mevcut Konumu Kullan',
                              ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.courierPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Select from map button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(
                          context,
                        ).pushNamed('/courier/location-management').then((_) {
                          // After returning from location management, reload data
                          _loadData();
                        });
                      },
                      icon: const Icon(Icons.map),
                      label: Text(
                        _getLocalizedString(
                          context,
                          'selectFromMap',
                          'Haritadan Seç',
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.courierPrimary,
                        side: const BorderSide(
                          color: AppTheme.courierPrimary,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          selectedLatitude != null && selectedLongitude != null
                          ? () async {
                              Navigator.of(context).pop();
                              await _updateLocation(
                                selectedLatitude!,
                                selectedLongitude!,
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.courierPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _getLocalizedString(context, 'save', 'Kaydet'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  if (selectedLatitude == null || selectedLongitude == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _getLocalizedString(
                          context,
                          'pleaseSelectLocation',
                          'Lütfen bir konum seçin',
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateLocation(double latitude, double longitude) async {
    try {
      await _courierService.updateLocation(latitude, longitude);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getLocalizedString(
                context,
                'locationUpdatedSuccessfully',
                'Konum başarıyla güncellendi',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reload data to get updated profile
        await _loadData();
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierDashboardScreen: ERROR updating location',
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getLocalizedString(
                context,
                'failedToUpdateLocation',
                'Konum güncellenemedi: $e',
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getLocalizedString(
    BuildContext context,
    String key,
    String fallback,
  ) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return fallback;

    // Dynamic localization access - will work after flutter gen-l10n
    // For now, return fallback if property doesn't exist
    try {
      // Try to access properties using noSuchMethod or direct access
      // Since we can't use reflection, we'll use a try-catch with dynamic access
      final dynamic loc = localizations;
      switch (key) {
        case 'motorcycle':
          try {
            return loc.motorcycle as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'car':
          try {
            return loc.car as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'bicycle':
          try {
            return loc.bicycle as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'selectVehicleType':
          try {
            return loc.selectVehicleType as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'selectVehicleTypeDescription':
          try {
            return loc.selectVehicleTypeDescription as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'save':
          return localizations.save;
        case 'vehicleTypeUpdatedSuccessfully':
          try {
            return loc.vehicleTypeUpdatedSuccessfully as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'failedToUpdateVehicleType':
          try {
            return loc.failedToUpdateVehicleType as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'selectLocationRequired':
          try {
            return loc.selectLocationRequired as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'selectLocationRequiredDescription':
          try {
            return loc.selectLocationRequiredDescription as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'useCurrentLocation':
          try {
            return loc.useCurrentLocation as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'selectFromMap':
          try {
            return loc.selectFromMap as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'locationUpdatedSuccessfully':
          try {
            return loc.locationUpdatedSuccessfully as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'failedToUpdateLocation':
          try {
            return loc.failedToUpdateLocation as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'gettingCurrentLocation':
          try {
            return loc.gettingCurrentLocation as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'pleaseSelectLocation':
          try {
            return loc.pleaseSelectLocation as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'selectedLocation':
          try {
            return loc.selectedLocation as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'locationServicesDisabledMessage':
          try {
            return loc.locationServicesDisabledMessage as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        default:
          return fallback;
      }
    } catch (e) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final localizations = AppLocalizations.of(context);

    if (!authProvider.isActive) {
      return const PendingApprovalWidget();
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: CourierHeader(
          title: localizations?.roleCourier ?? 'Kurye Paneli',
          subtitle: authProvider.email ?? '',
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
        bottomNavigationBar: const CourierBottomNav(currentIndex: 0),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: localizations?.roleCourier ?? 'Kurye Paneli',
        subtitle: authProvider.email ?? '',
        onRefresh: _loadData,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card (like vendor)
              Card(
                color: Colors.teal.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        size: 48,
                        color: Colors.teal.shade700,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations?.courierWelcome ??
                                  'Welcome Back, Courier!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _courier?.name ??
                                  authProvider.fullName ??
                                  authProvider.email ??
                                  '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(localizations?.statusUpdated ?? "Status").split(' ').first}:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getLocalizedStatus(_courier?.status ?? 'Offline'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(
                                _courier?.status ?? 'Offline',
                              ),
                            ),
                          ),
                        ],
                      ),
                      _isStatusUpdating
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.courierPrimary,
                              ),
                            )
                          : Switch(
                              value:
                                  _courier?.status == 'Available' ||
                                  _courier?.status == 'Busy' ||
                                  _courier?.status == 'Assigned',
                              activeThumbColor: AppTheme.courierPrimary,
                              onChanged: (value) {
                                if (_courier?.status == 'Busy' ||
                                    _courier?.status == 'Assigned') {
                                  final localizations = AppLocalizations.of(
                                    context,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations
                                                ?.cannotChangeStatusWhileBusy ??
                                            'Kurye meşgulken durum değiştirilemez',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                _toggleStatus(value);
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Stats cards (like vendor)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.history,
                      title:
                          localizations?.deliveryHistory ?? 'Delivery History',
                      value: _statistics?.todayDeliveries.toString() ?? '0',
                      subtitle: localizations?.today ?? 'Today',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.attach_money,
                      title: localizations?.earnings ?? 'Earnings',
                      value: CurrencyFormatter.format(
                        _statistics?.todayEarnings ?? 0,
                        Currency.try_,
                      ),
                      subtitle: localizations?.today ?? 'Today',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.star,
                      title: localizations?.rating ?? 'Rating',
                      value:
                          _statistics?.averageRating.toStringAsFixed(1) ??
                          '0.0',
                      subtitle:
                          '(${_statistics?.totalRatings ?? 0} ${(localizations?.reviews(_statistics?.totalRatings ?? 0) ?? '').replaceAll(RegExp(r'[\(\)]'), '').replaceAll('${_statistics?.totalRatings ?? 0}', '').trim().isNotEmpty ? (localizations?.reviews(_statistics?.totalRatings ?? 0) ?? '').replaceAll(RegExp(r'[\(\)]'), '').replaceAll('${_statistics?.totalRatings ?? 0}', '').trim() : "reviews"})',
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.local_shipping,
                      title: localizations?.total ?? 'Total',
                      value: _statistics?.totalDeliveries.toString() ?? '0',
                      subtitle: localizations?.allTime ?? 'All time',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Quick Actions (like vendor)
              Text(
                localizations?.quickActions ?? 'Quick Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildActionCard(
                    context,
                    localizations?.activeDeliveries ?? 'Active Deliveries',
                    Icons.delivery_dining,
                    Colors.teal,
                    () {
                      Navigator.of(
                        context,
                      ).pushNamed('/courier/active-deliveries');
                    },
                  ),
                  _buildActionCard(
                    context,
                    localizations?.earnings ?? 'Earnings',
                    Icons.attach_money,
                    Colors.green,
                    () {
                      Navigator.of(context).pushNamed('/courier/earnings');
                    },
                  ),
                  _buildActionCard(
                    context,
                    localizations?.profile ?? 'Profile',
                    Icons.person,
                    Colors.blue,
                    () {
                      Navigator.of(context).pushNamed('/courier/profile');
                    },
                  ),
                  _buildActionCard(
                    context,
                    localizations?.deliveryHistory ?? 'Delivery History',
                    Icons.history,
                    Colors.purple,
                    () {
                      Navigator.of(
                        context,
                      ).pushNamed('/courier/active-deliveries', arguments: 1);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Active Deliveries Section
              Text(
                localizations?.activeDeliveries ?? 'Active Deliveries',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _activeOrders.isEmpty
                  ? Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                localizations?.noActiveDeliveries ??
                                    'No active deliveries',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: Text(
                                  localizations?.refresh ?? 'Refresh',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _activeOrders.length,
                      itemBuilder: (context, index) {
                        final order = _activeOrders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.of(context)
                                  .pushNamed(
                                    '/courier/order-detail',
                                    arguments: order.id,
                                  );
                              if (result == true) {
                                _loadData(); // Reload if order was completed
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        order.customerOrderId.isNotEmpty
                                            ? 'Order #${order.customerOrderId}'
                                            : 'Order #${order.id}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            CurrencyFormatter.format(
                                              order.deliveryFee,
                                              Currency.try_,
                                            ),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Divider(),
                                  _buildLocationRow(
                                    icon: Icons.store,
                                    title: order.vendorName,
                                    subtitle: order.vendorAddress,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildLocationRow(
                                    icon: Icons.location_on,
                                    iconColor: Colors.redAccent,
                                    title: order.customerName,
                                    subtitle: order.deliveryAddress,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Chip(
                                        backgroundColor: _statusColor(
                                          order.status,
                                        ).withValues(alpha: 0.15),
                                        label: Text(
                                          order.status,
                                          style: TextStyle(
                                            color: _statusColor(order.status),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (order.courierStatus != null) ...[
                                        const SizedBox(width: 8),
                                        Chip(
                                          backgroundColor: _courierStatusColor(
                                            order.courierStatus!,
                                          ).withValues(alpha: 0.15),
                                          label: Text(
                                            _courierStatusLabel(
                                              order.courierStatus!,
                                            ),
                                            style: TextStyle(
                                              color: _courierStatusColor(
                                                order.courierStatus!,
                                              ),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      Text(
                                        DateFormat(
                                          'HH:mm',
                                        ).format(order.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildOrderActions(context, order),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CourierBottomNav(currentIndex: 0),
    );
  }

  String _getLocalizedStatus(String status) {
    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'tr') {
      switch (status) {
        case 'Available':
          return 'Müsait';
        case 'Offline':
          return 'Çevrimdışı';
        case 'Busy':
          return 'Meşgul';
        case 'Break':
          return 'Mola';
        case 'Assigned':
          return 'Atandı';
        default:
          return status;
      }
    } else if (locale.languageCode == 'ar') {
      switch (status) {
        case 'Available':
          return 'متاح';
        case 'Offline':
          return 'غير متصل';
        case 'Busy':
          return 'مشغول';
        case 'Break':
          return 'استراحة';
        case 'Assigned':
          return 'معين';
        default:
          return status;
      }
    } else {
      // English
      return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return Colors.green;
      case 'Busy':
      case 'Assigned':
        return AppTheme.primaryOrange;
      case 'Break':
        return Colors.blue;
      case 'Offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = Colors.teal,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showRejectOrderDialog(
    String orderId,
    AppLocalizations? localizations,
  ) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CustomConfirmationDialog(
            title:
                localizations?.rejectOrderTitle ??
                localizations?.rejectOrder ??
                'Reject Order',
            message: '',
            confirmText:
                localizations?.rejectOrder ?? localizations?.reject ?? 'Reject',
            cancelText: localizations?.cancel ?? 'Cancel',
            icon: Icons.cancel_outlined,
            iconColor: Colors.red,
            confirmButtonColor: Colors.red,
            isConfirmEnabled: reasonController.text.trim().isNotEmpty,
            onConfirm: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            onCancel: () => Navigator.of(context).pop(false),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations?.rejectReasonDescription ??
                        'Please enter the reason for rejecting this order (minimum 1 character):',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reasonController,
                    decoration: InputDecoration(
                      hintText: localizations?.rejectReasonHint ?? 'Reason...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations?.rejectReasonDescription ??
                            'Reason is required';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim();
      await _performOrderAction(
        orderId: orderId,
        action: () => _courierService.rejectOrder(orderId, reason),
        successMessage: localizations?.orderRejected ?? 'Order rejected',
      );
    }
  }

  Future<void> _showAcceptOrderConfirmation(
    String orderId,
    AppLocalizations? localizations,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CustomConfirmationDialog(
        title: localizations?.acceptOrderTitle ?? 'Accept Order',
        message:
            localizations?.acceptOrderConfirmation ??
            'Are you sure you want to accept this order?',
        confirmText:
            localizations?.acceptOrder ?? localizations?.accept ?? 'Accept',
        cancelText: localizations?.cancel ?? 'Cancel',
        icon: Icons.check_circle_outline,
        iconColor: Colors.teal,
        confirmButtonColor: Colors.teal,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );

    if (confirmed == true && mounted) {
      await _performOrderAction(
        orderId: orderId,
        action: () => _courierService.acceptOrder(orderId),
        successMessage: localizations?.orderAccepted ?? 'Order accepted',
      );
    }
  }

  Widget _buildOrderActions(BuildContext context, CourierOrder order) {
    final localizations = AppLocalizations.of(context);
    var status = order.status.toLowerCase();
    // Force 'assigned' status logic if not explicitly accepted yet, to ensure buttons appear
    if (order.courierStatus == OrderCourierStatus.assigned ||
        order.courierAcceptedAt == null) {
      status = 'assigned';
    }
    final isProcessing = _processingOrders.contains(order.id);

    switch (status) {
      case 'assigned':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isProcessing
                    ? null
                    : () => _showRejectOrderDialog(order.id, localizations),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.teal,
                        ),
                      )
                    : Text(localizations?.reject ?? 'Reject'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () =>
                          _showAcceptOrderConfirmation(order.id, localizations),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(localizations?.accept ?? 'Accept'),
              ),
            ),
          ],
        );
      case 'accepted':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isProcessing
                ? null
                : () => _performOrderAction(
                    orderId: order.id,
                    action: () => _courierService.pickupOrder(order.id),
                    successMessage:
                        localizations?.orderMarkedAsPickedUp ??
                        'Order marked as picked up',
                  ),
            icon: isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.inventory_2_outlined),
            label: Text(localizations?.markAsPickedUp ?? 'Mark as Picked Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        );
      case 'outfordelivery':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isProcessing
                ? null
                : () => _performOrderAction(
                    orderId: order.id,
                    action: () => _courierService.deliverOrder(order.id),
                    successMessage:
                        localizations?.orderDelivered ?? 'Order delivered',
                  ),
            icon: isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.done_all),
            label: Text(localizations?.markAsDelivered ?? 'Mark as Delivered'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _performOrderAction({
    required String orderId,
    required Future<bool> Function() action,
    required String successMessage,
  }) async {
    if (_processingOrders.contains(orderId)) return;

    setState(() {
      _processingOrders.add(orderId);
    });

    try {
      final success = await action();
      if (!mounted) {
        return;
      }

      if (!success) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              localizations?.actionCouldNotBeCompleted ??
                  'Action could not be completed',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage), backgroundColor: Colors.teal),
      );
      await _loadData();
    } catch (e, stackTrace) {
      LoggerService().error(
        'CourierDashboardScreen: ERROR performing order action',
        e,
        stackTrace,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingOrders.remove(orderId);
        });
      } else {
        _processingOrders.remove(orderId);
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return AppTheme.primaryOrange;
      case 'accepted':
        return Colors.blue;
      case 'outfordelivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _courierStatusColor(OrderCourierStatus status) {
    switch (status) {
      case OrderCourierStatus.assigned:
        return Colors.blue;
      case OrderCourierStatus.accepted:
        return Colors.green;
      case OrderCourierStatus.rejected:
        return Colors.red;
      case OrderCourierStatus.pickedUp:
        return Colors.orange;
      case OrderCourierStatus.outForDelivery:
        return Colors.purple;
      case OrderCourierStatus.delivered:
        return Colors.green.shade700;
    }
  }

  String _courierStatusLabel(OrderCourierStatus status) {
    switch (status) {
      case OrderCourierStatus.assigned:
        return 'Assigned';
      case OrderCourierStatus.accepted:
        return 'Accepted';
      case OrderCourierStatus.rejected:
        return 'Rejected';
      case OrderCourierStatus.pickedUp:
        return 'Picked Up';
      case OrderCourierStatus.outForDelivery:
        return 'On the Way';
      case OrderCourierStatus.delivered:
        return 'Delivered';
    }
  }
}

Widget _buildActionCard(
  BuildContext context,
  String title,
  IconData icon,
  Color color,
  VoidCallback onTap,
) {
  return Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
