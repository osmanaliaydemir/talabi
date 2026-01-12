import 'package:mobile/utils/custom_routes.dart';
import 'package:flutter/material.dart';

import 'package:mobile/services/api_service.dart';
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

import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/widgets/pending_approval_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _checkProfileAndLoad();
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

    // Profil kontrolü yapılıyorsa loading göster
    if (_isCheckingProfile) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    // Use TRY as default currency for vendor dashboard revenue
    const Currency displayCurrency = Currency.try_;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: VendorHeader(
        title: localizations?.vendorDashboard ?? 'Satıcı Paneli',
        subtitle: auth.email ?? '',
        onRefresh: _loadSummary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.deepPurple),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome card
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.store,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizations != null
                                        ? localizations.welcomeVendor(
                                            auth.fullName ??
                                                localizations.vendor,
                                          )
                                        : 'Hoş Geldiniz, ${auth.fullName ?? "Satıcı"}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    auth.email ?? '',
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
                    // Stats cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            localizations?.todayOrders ?? 'Bugünkü Siparişler',
                            '${_summary?['todayOrders'] ?? 0}',
                            Icons.shopping_bag,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            localizations?.pendingOrders ??
                                'Bekleyen Siparişler',
                            '${_summary?['pendingOrders'] ?? 0}',
                            Icons.pending,
                            Colors.deepPurple,
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
                            localizations?.todayRevenue ?? 'Bugünkü Gelir',
                            CurrencyFormatter.format(
                              (_summary?['todayRevenue'] ?? 0).toDouble(),
                              displayCurrency,
                            ),
                            Icons.attach_money,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            localizations?.weeklyRevenue ?? 'Haftalık Gelir',
                            CurrencyFormatter.format(
                              (_summary?['weekRevenue'] ?? 0).toDouble(),
                              displayCurrency,
                            ),
                            Icons.trending_up,
                            Colors.purple,
                          ),
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
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                            ),
                            const SizedBox(height: 12),
                            if (criticalStockCount > 0)
                              Card(
                                color: Colors.red[50],
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.production_quantity_limits,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    localizations?.criticalStockAlert(
                                          criticalStockCount,
                                        ) ??
                                        '$criticalStockCount ürün kritik stok seviyesinde',
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      NoSlidePageRoute(
                                        builder: (context) =>
                                            const VendorProductsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if (delayedOrdersCount > 0)
                              Card(
                                color: Colors.orange[50],
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.timer_off,
                                    color: Colors.orange,
                                  ),
                                  title: Text(
                                    localizations?.delayedOrdersAlert(
                                          delayedOrdersCount,
                                        ) ??
                                        '$delayedOrdersCount sipariş gecikmiş durumda',
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      NoSlidePageRoute(
                                        builder: (context) =>
                                            const VendorOrdersScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if (unansweredReviewsCount > 0)
                              Card(
                                color: Colors.blue[50],
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.rate_review,
                                    color: Colors.blue,
                                  ),
                                  title: Text(
                                    localizations?.unansweredReviewsAlert(
                                          unansweredReviewsCount,
                                        ) ??
                                        '$unansweredReviewsCount cevaplanmamış yorum var',
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      NoSlidePageRoute(
                                        builder: (context) =>
                                            const VendorReviewsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),

                    // Quick actions
                    Text(
                      localizations?.quickActions ?? 'Hızlı İşlemler',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                          localizations?.orders ?? 'Siparişler',
                          Icons.receipt_long,
                          Colors.blue,
                          () {
                            TapLogger.logNavigation(
                              'VendorDashboard',
                              'VendorOrders',
                            );
                            Navigator.push(
                              context,
                              NoSlidePageRoute(
                                builder: (context) =>
                                    const VendorOrdersScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          localizations?.products ?? 'Ürünler',
                          Icons.inventory_2,
                          Colors.purple,
                          () {
                            TapLogger.logNavigation(
                              'VendorDashboard',
                              'VendorProducts',
                            );
                            Navigator.push(
                              context,
                              NoSlidePageRoute(
                                builder: (context) =>
                                    const VendorProductsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          localizations?.reports ?? 'Raporlar',
                          Icons.bar_chart,
                          Colors.green,
                          () {
                            TapLogger.logNavigation(
                              'VendorDashboard',
                              'VendorReports',
                            );
                            Navigator.push(
                              context,
                              NoSlidePageRoute(
                                builder: (context) =>
                                    const VendorReportsScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          context,
                          localizations != null
                              ? (localizations.reviews(0).split('(')[0].trim())
                              : 'Yorumlar',
                          Icons.comment,
                          Colors.deepPurple,
                          () {
                            TapLogger.logNavigation(
                              'VendorDashboard',
                              'VendorReviews',
                            );
                            Navigator.push(
                              context,
                              NoSlidePageRoute(
                                builder: (context) =>
                                    const VendorReviewsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const VendorBottomNav(currentIndex: 0),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
