import 'package:mobile/utils/custom_routes.dart';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/orders/presentation/screens/vendor/order_detail_screen.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:mobile/features/dashboard/presentation/widgets/vendor_header.dart';
import 'package:mobile/features/dashboard/presentation/widgets/vendor_bottom_nav.dart';
import 'package:mobile/services/logger_service.dart';

class VendorOrdersScreen extends StatefulWidget {
  final int initialIndex;

  const VendorOrdersScreen({super.key, this.initialIndex = 0});

  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  List<dynamic> _orders = [];
  String? _selectedStatus;

  int _currentPage = 1;
  static const int _pageSize = 6;
  static const int _tabCount = 6;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  late ScrollController _scrollController;

  Map<String, int> _orderCounts = {
    'Pending': 0,
    'Preparing': 0,
    'Ready': 0,
    'OutForDelivery': 0,
    'Delivered': 0,
    'Cancelled': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
    _tabController.addListener(_handleTabChange);
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    // İlk tab'ı (initialIndex'e göre) seç
    final statuses = [
      'Pending',
      'Preparing',
      'Ready',
      'OutForDelivery',
      'Delivered',
      'Cancelled',
    ];
    _selectedStatus = statuses[widget.initialIndex];
    _loadOrderCounts();
    _loadOrders();
  }

  Future<void> _loadOrderCounts() async {
    try {
      final statuses = [
        'Pending',
        'Preparing',
        'Ready',
        'OutForDelivery',
        'Delivered',
        'Cancelled',
      ];
      final counts = <String, int>{};

      for (final status in statuses) {
        try {
          final totalCount = await _getTotalOrderCount(status);
          counts[status] = totalCount;
        } catch (e) {
          counts[status] = 0;
        }
      }

      if (mounted) {
        setState(() {
          _orderCounts = counts;
        });
      }
    } catch (e) {
      LoggerService().error(
        'Sipariş sayıları yüklenemedi: $e',
        e,
        StackTrace.current,
      );
    }
  }

  Future<int> _getTotalOrderCount(String? status) async {
    try {
      // API'den sadece ilk sayfayı çekip totalCount'u alıyoruz
      // Bu çok daha verimli - tüm sayfaları çekmeye gerek yok
      final response = await _apiService.getVendorOrdersWithCount(
        status: status,
        page: 1,
        pageSize: 1, // Sadece totalCount için, items'a ihtiyacımız yok
      );
      return response['totalCount'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreData) {
      _loadMoreOrders();
    }
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      // Tab değişimi tamamlandığında çalışır
      final statuses = [
        'Pending',
        'Preparing',
        'Ready',
        'OutForDelivery',
        'Delivered',
        'Cancelled',
      ];
      final newStatus = statuses[_tabController.index];

      // Status değiştiyse siparişleri yeniden yükle
      if (_selectedStatus != newStatus) {
        setState(() {
          _selectedStatus = newStatus;
        });
        // Asenkron işlemleri setState dışında çağır
        // Sadece seçili status için siparişleri yükle
        // Order counts zaten _loadOrders içinde refresh durumunda yüklenecek
        _loadOrders(isRefresh: true, updateCounts: false);
      }
    }
  }

  Future<void> _loadOrders({
    bool isRefresh = false,
    bool showLoading = true,
    bool updateCounts = true,
  }) async {
    if (isRefresh) {
      setState(() {
        _isFirstLoad = true;
        _currentPage = 1;
        _hasMoreData = true;
        _orders.clear();
      });
    }

    if (showLoading && _isFirstLoad) {
      setState(() {
        _isFirstLoad = true;
      });
    }

    try {
      final orders = await _apiService.getVendorOrders(
        status: _selectedStatus,
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (mounted) {
        setState(() {
          if (isRefresh) {
            _orders = orders;
          } else {
            _orders.addAll(orders);
          }

          _isFirstLoad = false;
          _isLoadingMore = false;

          if (orders.length < _pageSize) {
            _hasMoreData = false;
          }
        });

        // Order counts'u sadece updateCounts=true olduğunda yükle
        // Tab geçişlerinde false olarak gönderilir (performans için)
        if (isRefresh && updateCounts) {
          _loadOrderCounts();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFirstLoad = false;
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Siparişler yüklenemedi: $e')));
      }
    }
  }

  Future<void> _loadMoreOrders() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadOrders(isRefresh: false, showLoading: false);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.deepPurple;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.green;
      case 'assigned':
      case 'accepted':
      case 'outfordelivery':
        return Colors.orange;
      case 'delivered':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, AppLocalizations localizations) {
    switch (status.toLowerCase()) {
      case 'pending':
        return localizations.pending;
      case 'preparing':
        return localizations.preparing;
      case 'ready':
        return localizations.ready;
      case 'assigned':
        return 'Kuryeye Atandı';
      case 'accepted':
        return 'Kurye Kabul Etti';
      case 'outfordelivery':
        return 'Teslimata Çıktı';
      case 'delivered':
        return localizations.delivered;
      case 'cancelled':
        return localizations.cancelled;
      default:
        return status;
    }
  }

  String _formatDateFromOrder(
    Map<String, dynamic> order,
    AppLocalizations localizations,
  ) {
    final dateValue =
        order['createdAt'] ??
        order['CreatedAt'] ??
        order['created_at'] ??
        order['date'] ??
        order['Date'];

    if (dateValue == null) {
      const dateLabel = 'Tarih';
      return '$dateLabel: -';
    }

    return _formatDate(dateValue, localizations);
  }

  String _formatDate(dynamic dateValue, AppLocalizations localizations) {
    const dateLabel = 'Tarih';

    if (dateValue == null) {
      return '$dateLabel: -';
    }

    try {
      late DateTime dateTime;
      if (dateValue is String) {
        if (dateValue.isEmpty) {
          return '$dateLabel: -';
        }
        var dateString = dateValue;
        if (dateString.contains('.') && dateString.contains('T')) {
          final parts = dateString.split('.');
          if (parts.length > 1) {
            final timePart = parts[1].split(RegExp(r'[+-Z]'));
            if (timePart.isNotEmpty && timePart[0].length > 3) {
              dateString =
                  '${parts[0]}.${timePart[0].substring(0, 3)}${dateString.substring(dateString.indexOf(timePart[0]) + timePart[0].length)}';
            }
          }
        }
        dateTime = DateTime.parse(dateString);
      } else if (dateValue is DateTime) {
        dateTime = dateValue;
      } else if (dateValue is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else {
        return '$dateLabel: -';
      }

      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year.toString();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return '$dateLabel: $day.$month.$year $hour:$minute';
    } catch (e) {
      return '$dateLabel: -';
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    const Currency displayCurrency = Currency.syp;

    return Scaffold(
      appBar: VendorHeader(
        title: localizations.vendorOrders,
        leadingIcon: Icons.shopping_bag_outlined,
        showBackButton: false,
        onRefresh: () {
          _loadOrderCounts();
          _loadOrders(isRefresh: true);
        },
        orderCounts: _orderCounts,
        selectedStatus: _selectedStatus,
      ),
      body: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.deepPurple,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: [
                Tab(text: localizations.pending),
                Tab(text: localizations.preparing),
                Tab(text: localizations.ready),
                Tab(text: localizations.outForDelivery),
                Tab(text: localizations.delivered),
                Tab(text: localizations.cancelledOrders),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Colors.white,
              backgroundColor: Colors.deepPurple,
              onRefresh: () => _loadOrders(isRefresh: true, showLoading: false),
              child: _isFirstLoad
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.deepPurple,
                      ),
                    )
                  : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            localizations.noOrdersFound,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: _orders.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _orders.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final order = _orders[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(order['status']),
                              child: const Icon(
                                Icons.receipt,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              '${localizations.order} #${order['customerOrderId'] ?? order['id']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${localizations.customer}: ${order['customerName']}',
                                ),
                                Text(
                                  _formatDateFromOrder(order, localizations),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      order['status'],
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _getStatusText(
                                      order['status'],
                                      localizations,
                                    ),
                                    style: TextStyle(
                                      color: _getStatusColor(order['status']),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyFormatter.format(
                                    (order['totalAmount'] as num).toDouble(),
                                    displayCurrency,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            onTap: () {
                              TapLogger.logTap(
                                'Order #${order['id']}',
                                action: 'View Detail',
                              );
                              Navigator.push(
                                context,
                                NoSlidePageRoute(
                                  builder: (context) => VendorOrderDetailScreen(
                                    orderId: order['id'],
                                  ),
                                ),
                              ).then((_) => _loadOrders(isRefresh: true));
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 1),
    );
  }
}
