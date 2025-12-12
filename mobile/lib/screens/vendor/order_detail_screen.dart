import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/currency.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/screens/vendor/widgets/header.dart';
import 'package:mobile/widgets/cached_network_image_widget.dart';
import 'package:mobile/widgets/custom_confirmation_dialog.dart';

class VendorOrderDetailScreen extends StatefulWidget {
  const VendorOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<VendorOrderDetailScreen> createState() =>
      _VendorOrderDetailScreenState();
}

class _VendorOrderDetailScreenState extends State<VendorOrderDetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await _apiService.getVendorOrder(widget.orderId);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sipariş yüklenemedi: $e')));
      }
    }
  }

  Future<void> _acceptOrder() async {
    final localizations = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomConfirmationDialog(
        title: localizations.acceptOrderTitle,
        message: localizations.acceptOrderConfirmation,
        confirmText: localizations.acceptOrder,
        cancelText: localizations.cancel,
        icon: Icons.check_circle_outline,
        iconColor: Colors.green.shade700,
        confirmButtonColor: Colors.green.shade700,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.acceptOrder(widget.orderId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sipariş kabul edildi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadOrder();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  Future<void> _rejectOrder() async {
    final localizations = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    bool isValid = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => CustomConfirmationDialog(
          title: 'Sipariş Reddi',
          message: 'Bu siparişi reddetmek istediğinizden emin misiniz?',
          confirmText: 'Reddet',
          cancelText: localizations.cancel,
          icon: Icons.cancel_outlined,
          iconColor: Colors.red.shade700,
          confirmButtonColor: Colors.red.shade700,
          isConfirmEnabled: isValid,
          onConfirm: () => Navigator.pop(context, true),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Red sebebinizi girin (en az 10 karakter):',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 4,
                onChanged: (value) {
                  setState(() {
                    isValid = value.length >= 10;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Red sebebi...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.red.shade700,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              if (reasonController.text.isNotEmpty && !isValid)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'En az 10 karakter girmelisiniz (${reasonController.text.length}/10)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          onCancel: () => Navigator.pop(context, false),
        ),
      ),
    );

    if (confirmed == true && reasonController.text.length >= 10) {
      try {
        await _apiService.rejectOrder(widget.orderId, reasonController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sipariş reddedildi'),
              backgroundColor: AppTheme.primaryOrange,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    final localizations = AppLocalizations.of(context)!;

    // Onay popup'ı göster
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomConfirmationDialog(
        title: 'Sipariş Durumu Güncelleme',
        message: 'Siparişi "Hazır" olarak işaretlemek istediğinizden emin misiniz?',
        confirmText: 'Hazır Olarak İşaretle',
        cancelText: localizations.cancel,
        icon: Icons.check_circle_outline,
        iconColor: Colors.green.shade700,
        confirmButtonColor: Colors.green.shade700,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed == true) {
      try {
        await _apiService.updateOrderStatus(widget.orderId, newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sipariş durumu güncellendi'),
              backgroundColor: Colors.green,
            ),
          );
          _loadOrder();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  Future<void> _showCourierSelection() async {
    try {
      // Müsait kuryeler listesini al
      final couriers = await _apiService.getAvailableCouriers(widget.orderId);

      if (!mounted) return;

      if (couriers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yakında müsait kurye bulunamadı'),
            backgroundColor: AppTheme.primaryOrange,
          ),
        );
        return;
      }

      // Kurye seçim dialog'unu göster
      final selectedCourier = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.delivery_dining,
                      color: AppTheme.primaryOrange,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Müsait Kuryeler',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Bir kurye seçin',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              // Courier list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: couriers.length,
                  itemBuilder: (context, index) {
                    final courier = couriers[index];
                    return _buildCourierCard(courier);
                  },
                ),
              ),
            ],
          ),
        ),
      );

      if (selectedCourier != null) {
        // Show confirmation dialog before assigning
        final confirmed = await _showAssignCourierConfirmation(
          selectedCourier['fullName'],
        );
        if (confirmed == true && mounted) {
          await _assignCourier(selectedCourier['id'].toString());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Widget _buildCourierCard(Map<String, dynamic> courier) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.pop(context, courier),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: AppTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courier['fullName'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${courier['averageRating'].toStringAsFixed(1)} (${courier['totalDeliveries']} teslimat)',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Distance badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${courier['distance']} km',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Details
              Row(
                children: [
                  _buildCourierDetailChip(
                    Icons.motorcycle,
                    courier['vehicleType'],
                    Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildCourierDetailChip(
                    Icons.access_time,
                    '~${courier['estimatedArrivalMinutes']} dk',
                    AppTheme.primaryOrange,
                  ),
                  const SizedBox(width: 8),
                  _buildCourierDetailChip(
                    Icons.shopping_bag,
                    '${courier['currentActiveOrders']}/${courier['maxActiveOrders']}',
                    Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourierDetailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  String _getLocalizedString(String key, String fallback) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) return fallback;

    try {
      final dynamic loc = localizations;
      switch (key) {
        case 'assignCourierConfirmationTitle':
          try {
            return loc.assignCourierConfirmationTitle as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'assignCourierConfirmationMessage':
          try {
            return loc.assignCourierConfirmationMessage as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'assign':
          try {
            return loc.assign as String? ?? fallback;
          } catch (_) {
            return fallback;
          }
        case 'courierAssignedSuccessfully':
          try {
            return loc.courierAssignedSuccessfully as String? ?? fallback;
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

  Future<bool?> _showAssignCourierConfirmation(String courierName) async {
    final localizations = AppLocalizations.of(context);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => CustomConfirmationDialog(
        title: _getLocalizedString(
          'assignCourierConfirmationTitle',
          'Kurye Atama',
        ),
        message:
            '${_getLocalizedString('assignCourierConfirmationMessage', 'Siparişi {courierName} adlı kuryeye atamak istediğinizden emin misiniz?').replaceFirst('{courierName}', courierName)}',
        confirmText: _getLocalizedString('assign', 'Atama Yap'),
        cancelText: localizations?.cancel ?? 'İptal',
        icon: Icons.check_circle_outline,
        iconColor: AppTheme.primaryOrange,
        confirmButtonColor: AppTheme.primaryOrange,
        onConfirm: () => Navigator.pop(dialogContext, true),
        onCancel: () => Navigator.pop(dialogContext, false),
      ),
    );
  }

  Future<void> _assignCourier(String courierId) async {
    try {
      await _apiService.assignCourierToOrder(widget.orderId, courierId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getLocalizedString(
                'courierAssignedSuccessfully',
                'Kurye başarıyla atandı',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kurye atanamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _autoAssignCourier() async {
    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CustomConfirmationDialog(
        title: 'Otomatik Kurye Ataması',
        message: 'Sistem en yakın ve en uygun kuryeyi otomatik olarak atayacak. Devam etmek istiyor musunuz?',
        confirmText: 'Evet, Ata',
        cancelText: 'Vazgeç',
        icon: Icons.auto_awesome,
        iconColor: Colors.green,
        confirmButtonColor: Colors.green,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed != true) return;

    try {
      final result = await _apiService.autoAssignCourier(widget.orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kurye otomatik atandı: ${result['courierName']}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Otomatik atama başarısız: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.primaryOrange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'delivered':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_top_rounded;
      case 'preparing':
        return Icons.kitchen_rounded;
      case 'ready':
        return Icons.check_circle_rounded;
      case 'delivered':
        return Icons.delivery_dining_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Bekliyor';
      case 'preparing':
        return 'Hazırlanıyor';
      case 'ready':
        return 'Hazır';
      case 'delivered':
        return 'Teslim Edildi';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use TRY as default currency for order display
    // In the future, currency can be retrieved from order items if available
    const Currency displayCurrency = Currency.try_;

    if (_isLoading) {
      return const Scaffold(
        appBar: VendorHeader(title: 'Sipariş Detayı', showBackButton: true),
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    if (_order == null) {
      return const Scaffold(
        appBar: VendorHeader(title: 'Sipariş Detayı', showBackButton: true),
        body: Center(child: Text('Sipariş bulunamadı')),
      );
    }

    final status = _order!['status'] as String;
    final customerOrderId =
        _order!['customerOrderId']?.toString() ??
        _order!['id']?.toString() ??
        'N/A';

    return Scaffold(
      appBar: VendorHeader(
        title: 'Sipariş #$customerOrderId',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom:
              (status == 'Pending' ||
                  status == 'Preparing' ||
                  status == 'Ready')
              ? 100
              : 16, // Butonlar için alt boşluk
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(status),
            const SizedBox(height: 16),
            // Customer info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Müşteri Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'Sipariş No',
                      '#${_order!['customerOrderId'] ?? _order!['id']}',
                    ),
                    _buildInfoRow('İsim', _order!['customerName']),
                    _buildInfoRow('E-posta', _order!['customerEmail']),
                    _buildInfoRow(
                      'Tarih',
                      DateTime.parse(
                        _order!['createdAt'],
                      ).toString().substring(0, 16),
                    ),
                  ],
                ),
              ),
            ),
            // Courier info - only show if courier is assigned
            if (_order!['courier'] != null) ...[
              const SizedBox(height: 16),
              _buildCourierInfoCard(),
            ],
            const SizedBox(height: 16),
            // Order items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sipariş Detayları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_order!['items'] as List).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            if (item['productImageUrl'] != null)
                              OptimizedCachedImage.productThumbnail(
                                imageUrl: item['productImageUrl'],
                                width: 50,
                                height: 50,
                                borderRadius: BorderRadius.circular(8),
                              )
                            else
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.image),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['productName'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${item['quantity']} adet x ${CurrencyFormatter.format(item['unitPrice'].toDouble(), displayCurrency)}',
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                item['totalPrice'].toDouble(),
                                displayCurrency,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Toplam',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(
                            (_order!['totalAmount'] as num).toDouble(),
                            displayCurrency,
                          ),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: status == 'Pending'
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _acceptOrder,
                        icon: const Icon(Icons.check),
                        label: const Text('Kabul Et'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _rejectOrder,
                        icon: const Icon(Icons.close),
                        label: const Text('Reddet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : status == 'Preparing'
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _updateStatus('Ready'),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Hazır Olarak İşaretle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            )
          : status == 'Ready'
          ? Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showCourierSelection,
                        icon: const Icon(Icons.person_search),
                        label: const Text('Kurye Seç'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _autoAssignCourier,
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Otomatik Ata'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildStatusCard(String status) {
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.15),
            statusColor.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(statusIcon, color: statusColor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sipariş Durumu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            _buildStatusBadge(status, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color statusColor) {
    String badgeText;
    IconData badgeIcon;

    switch (status.toLowerCase()) {
      case 'pending':
        badgeText = 'Bekliyor';
        badgeIcon = Icons.hourglass_empty;
        break;
      case 'preparing':
        badgeText = 'Hazırlanıyor';
        badgeIcon = Icons.kitchen;
        break;
      case 'ready':
        badgeText = 'Hazır';
        badgeIcon = Icons.check_circle_outline;
        break;
      case 'delivered':
        badgeText = 'Teslim Edildi';
        badgeIcon = Icons.done_all;
        break;
      case 'cancelled':
        badgeText = 'İptal';
        badgeIcon = Icons.cancel;
        break;
      default:
        badgeText = 'Aktif';
        badgeIcon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            badgeText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourierInfoCard() {
    final localizations = AppLocalizations.of(context)!;
    final courier = _order!['courier'] as Map<String, dynamic>?;

    if (courier == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.delivery_dining,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  localizations.courierInformation,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(localizations.fullName, courier['name'] ?? ''),
            if (courier['phoneNumber'] != null)
              _buildInfoRow(localizations.phoneNumber, courier['phoneNumber']),
            if (courier['vehicleType'] != null)
              _buildInfoRow(localizations.vehicleType, courier['vehicleType']),
            if (courier['status'] != null)
              _buildInfoRow(
                'Durum',
                _getCourierStatusText(courier['status'], localizations),
              ),
            if (courier['assignedAt'] != null)
              _buildInfoRow(
                localizations.assignedAt,
                _formatDateTime(courier['assignedAt']),
              ),
            if (courier['acceptedAt'] != null)
              _buildInfoRow(
                localizations.acceptedAt,
                _formatDateTime(courier['acceptedAt']),
              ),
            if (courier['pickedUpAt'] != null)
              _buildInfoRow(
                localizations.pickedUpAt,
                _formatDateTime(courier['pickedUpAt']),
              ),
            if (courier['outForDeliveryAt'] != null)
              _buildInfoRow(
                localizations.outForDeliveryAt,
                _formatDateTime(courier['outForDeliveryAt']),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '-';
    try {
      DateTime date;
      if (dateTime is String) {
        date = DateTime.parse(dateTime);
      } else {
        return dateTime.toString();
      }
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime.toString();
    }
  }

  String _getCourierStatusText(String status, AppLocalizations localizations) {
    switch (status.toLowerCase()) {
      case 'assigned':
        return localizations.assigned;
      case 'accepted':
        return localizations.accepted;
      case 'rejected':
        return localizations.rejected;
      case 'pickedup':
      case 'picked_up':
        return localizations.pickedUp;
      case 'outfordelivery':
      case 'out_for_delivery':
        return localizations.outForDelivery;
      case 'delivered':
        return localizations.delivered;
      default:
        return status;
    }
  }
}
