import 'dart:async';
import 'dart:convert';
import 'package:mobile/utils/custom_routes.dart';
import 'package:flutter/material.dart';

import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/features/orders/presentation/screens/vendor/orders_screen.dart';
import 'package:mobile/features/products/presentation/screens/vendor/products_screen.dart';
import 'package:mobile/features/reports/presentation/screens/vendor/reports_screen.dart';
import 'package:mobile/features/reviews/presentation/screens/vendor/reviews_screen.dart';
import 'package:mobile/features/profile/presentation/screens/vendor/edit_profile_screen.dart';
import 'package:mobile/features/settings/data/models/currency.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:mobile/features/dashboard/presentation/widgets/vendor_header.dart';
import 'package:mobile/features/dashboard/presentation/widgets/vendor_bottom_nav.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:provider/provider.dart';
import 'package:mobile/services/signalr_service.dart';

import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/pending_approval_widget.dart';
import 'package:mobile/features/wallet/presentation/screens/wallet_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  bool _isCheckingProfile = true;

  final SignalRService _signalRService = SignalRService();
  StreamSubscription? _newOrderSubscription;

  @override
  void initState() {
    super.initState();
    _checkProfileAndLoad();
    _initSignalR();
  }

  Future<void> _initSignalR() async {
    await _signalRService.startConnection();
    _setupSignalRListener();
  }

  void _setupSignalRListener() {
    _newOrderSubscription = _signalRService.onVendorNewOrder.listen((data) {
      debugPrint('Vendor Dashboard: New Order Received via SignalR');
      if (mounted) {
        // Show notification/toast
        ToastMessage.show(
          context,
          message: 'Yeni sipariş alındı!',
          isSuccess: true,
        );

        // Sesli ve Titreşimli Bildirim Tetikle
        try {
          NotificationService().showManualNotification(
            title: 'Yeni Sipariş!',
            body: 'Tebrikler, yeni bir sipariş aldınız.',
            payload: json.encode(data), // datayı json string'e çevir
          );
        } catch (e) {
          debugPrint('Notification Error: $e');
        }

        // Refresh dashboard data
        _loadSummary();
      }
    });
  }

  @override
  void dispose() {
    _newOrderSubscription?.cancel();
    _signalRService.stopConnection(); // Stop connection to clean up resources
    super.dispose();
  }

  /// Zorunlu profil alanlarını kontrol eder
  bool _isProfileComplete(Map<String, dynamic> profile) {
    // Zorunlu alanlar:
    // 1. İşletme Adı (name)
    // 2. Konum (latitude, longitude)
    // 3. Açık Adres (address)
    // 4. Şehir (city)
    // 5. Telefon Numarası (phoneNumber)

    final name = profile['name'] as String?;
    final latitude = profile['latitude'];
    final longitude = profile['longitude'];
    final address = profile['address'] as String?;
    final city = profile['city'] as String?;
    final phoneNumber = profile['phoneNumber'] as String?;

    // Tüm zorunlu alanların dolu olup olmadığını kontrol et
    final isNameValid = name != null && name.trim().isNotEmpty;
    final isLocationValid = latitude != null && longitude != null;
    final isAddressValid = address != null && address.trim().isNotEmpty;
    final isCityValid = city != null && city.trim().isNotEmpty;
    final isPhoneValid = phoneNumber != null && phoneNumber.trim().isNotEmpty;

    return isNameValid &&
        isLocationValid &&
        isAddressValid &&
        isCityValid &&
        isPhoneValid;
  }

  Future<void> _checkProfileAndLoad() async {
    try {
      // Önce profil bilgilerini çek
      final profile = await _apiService.getVendorProfile();

      // Zorunlu alanları kontrol et
      if (!_isProfileComplete(profile)) {
        // Profil eksikse tamamlama ekranına yönlendir
        if (mounted) {
          Navigator.of(context).pushReplacement(
            NoSlidePageRoute(
              builder: (context) =>
                  const VendorEditProfileScreen(isOnboarding: true),
            ),
          );
        }
        return;
      }

      // Profil yüklendikten sonra SignalR grubuna katıl
      if (profile.containsKey('id')) {
        final vendorId = profile['id'].toString();
        debugPrint('Connecting to Vendor SignalR Group: $vendorId');
        // Bağlantı kurulana kadar bekle veya hemen katılmayı dene
        if (_signalRService.isConnected) {
          await _signalRService.joinVendorGroup(vendorId);
        } else {
          // Bağlantı henüz hazır değilse, bağlantı sonrası için tekrar dene (basit retry)
          Future.delayed(const Duration(seconds: 2), () async {
            await _signalRService.joinVendorGroup(vendorId);
          });
        }
      }

      // Profil tamamsa dashboard'u yükle
      setState(() {
        _isCheckingProfile = false;
      });
      _loadSummary();
    } catch (e) {
      // Profil yüklenirken hata oluşursa, dashboard'u yüklemeyi dene
      // (belki profil zaten tamamlanmıştır)
      setState(() {
        _isCheckingProfile = false;
      });
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _apiService.getVendorSummary();
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ToastMessage.show(
          context,
          message: localizations.summaryLoadError(e.toString()),
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final localizations = AppLocalizations.of(context);

    if (!auth.isActive) {
      return const PendingApprovalWidget();
    }

    if (_isCheckingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA), // Light corporate background
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    const Currency displayCurrency = Currency.syp;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: VendorHeader(
        title: localizations?.vendorDashboard ?? 'Satıcı Paneli',
        subtitle: auth.email ?? '',
        onRefresh: _loadSummary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        color: primaryColor,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    _buildWelcomeSection(context, auth, localizations),
                    const SizedBox(height: 24),

                    // Stats Grid
                    Text(
                      localizations?.vendorDashboard ?? 'Genel Bakış',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        _buildStatCard(
                          context,
                          localizations?.todayOrders ?? 'Bugünkü Siparişler',
                          '${_summary?['todayOrders'] ?? 0}',
                          Icons.shopping_bag_outlined,
                          Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              NoSlidePageRoute(
                                builder: (context) =>
                                    const VendorOrdersScreen(initialIndex: 4),
                              ),
                            );
                          },
                        ),
                        _buildStatCard(
                          context,
                          localizations?.pendingOrders ?? 'Bekleyen Siparişler',
                          '${_summary?['pendingOrders'] ?? 0}',
                          Icons.hourglass_empty_outlined,
                          Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              NoSlidePageRoute(
                                builder: (context) =>
                                    const VendorOrdersScreen(initialIndex: 0),
                              ),
                            );
                          },
                        ),
                        _buildStatCard(
                          context,
                          localizations?.todayRevenue ?? 'Bugünkü Gelir',
                          CurrencyFormatter.format(
                            (_summary?['todayRevenue'] ?? 0).toDouble(),
                            displayCurrency,
                          ),
                          Icons.account_balance_wallet_outlined,
                          Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              NoSlidePageRoute(
                                builder: (context) => const WalletScreen(
                                  bottomNavigationBar: VendorBottomNav(
                                    currentIndex: 3,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        _buildStatCard(
                          context,
                          localizations?.weeklyRevenue ?? 'Haftalık Gelir',
                          CurrencyFormatter.format(
                            (_summary?['weekRevenue'] ?? 0).toDouble(),
                            displayCurrency,
                          ),
                          Icons.trending_up,
                          Colors.purple,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Alerts Section
                    FutureBuilder<Map<String, dynamic>>(
                      future: _apiService.getDashboardAlerts(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();

                        final alerts = snapshot.data!;
                        final criticalStockCount =
                            alerts['criticalStockCount'] as int? ?? 0;
                        final delayedOrdersCount =
                            alerts['delayedOrdersCount'] as int? ?? 0;
                        final unansweredReviewsCount =
                            alerts['unansweredReviewsCount'] as int? ?? 0;

                        if (criticalStockCount == 0 &&
                            delayedOrdersCount == 0 &&
                            unansweredReviewsCount == 0) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations?.attentionRequired ??
                                  'Dikkat Gerekenler',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (criticalStockCount > 0)
                              _buildAlertCard(
                                context,
                                localizations?.criticalStockAlert(
                                      criticalStockCount,
                                    ) ??
                                    '$criticalStockCount ürün kritik stok seviyesinde',
                                Icons.warning_amber_rounded,
                                Colors.red.shade600,
                                Colors.red.shade50,
                                () => Navigator.push(
                                  context,
                                  NoSlidePageRoute(
                                    builder: (_) =>
                                        const VendorProductsScreen(),
                                  ),
                                ),
                              ),
                            if (delayedOrdersCount > 0)
                              _buildAlertCard(
                                context,
                                localizations?.delayedOrdersAlert(
                                      delayedOrdersCount,
                                    ) ??
                                    '$delayedOrdersCount sipariş gecikmiş durumda',
                                Icons.timer_off_outlined,
                                Colors.orange.shade800,
                                Colors.orange.shade50,
                                () => Navigator.push(
                                  context,
                                  NoSlidePageRoute(
                                    builder: (_) => const VendorOrdersScreen(),
                                  ),
                                ),
                              ),
                            if (unansweredReviewsCount > 0)
                              _buildAlertCard(
                                context,
                                localizations?.unansweredReviewsAlert(
                                      unansweredReviewsCount,
                                    ) ??
                                    '$unansweredReviewsCount cevaplanmamış yorum var',
                                Icons.rate_review_outlined,
                                Colors.blue.shade700,
                                Colors.blue.shade50,
                                () => Navigator.push(
                                  context,
                                  NoSlidePageRoute(
                                    builder: (_) => const VendorReviewsScreen(),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),

                    // Quick Actions
                    Text(
                      localizations?.quickActions ?? 'Hızlı İşlemler',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActionsGrid(context, localizations),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 0),
    );
  }

  Widget _buildWelcomeSection(
    BuildContext context,
    AuthProvider auth,
    AppLocalizations? localizations,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hoş Geldiniz,',
              style: TextStyle(
                color: Color(0xFF718096),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              auth.fullName ?? localizations?.vendor ?? 'Satıcı',
              style: const TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.store_rounded,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    String message,
    IconData icon,
    Color iconColor,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4A5568),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(
    BuildContext context,
    AppLocalizations? localizations,
  ) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.2,
      children: [
        _buildActionTile(
          context,
          localizations?.orders ?? 'Siparişler',
          Icons.receipt_long_rounded,
          const Color(0xFF3182CE),
          () {
            TapLogger.logNavigation('VendorDashboard', 'VendorOrders');
            Navigator.push(
              context,
              NoSlidePageRoute(builder: (_) => const VendorOrdersScreen()),
            );
          },
        ),
        _buildActionTile(
          context,
          localizations?.products ?? 'Ürünler',
          Icons.inventory_2_rounded,
          const Color(0xFF805AD5),
          () {
            TapLogger.logNavigation('VendorDashboard', 'VendorProducts');
            Navigator.push(
              context,
              NoSlidePageRoute(builder: (_) => const VendorProductsScreen()),
            );
          },
        ),
        _buildActionTile(
          context,
          localizations?.reports ?? 'Raporlar',
          Icons.bar_chart_rounded,
          const Color(0xFF38A169),
          () {
            TapLogger.logNavigation('VendorDashboard', 'VendorReports');
            Navigator.push(
              context,
              NoSlidePageRoute(builder: (_) => const VendorReportsScreen()),
            );
          },
        ),
        _buildActionTile(
          context,
          localizations != null
              ? (localizations.reviews(0).split('(')[0].trim())
              : 'Yorumlar',
          Icons.chat_bubble_outline_rounded,
          const Color(0xFFD69E2E),
          () {
            TapLogger.logNavigation('VendorDashboard', 'VendorReviews');
            Navigator.push(
              context,
              NoSlidePageRoute(builder: (_) => const VendorReviewsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
