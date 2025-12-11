import 'package:flutter/material.dart';

import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/vendor/orders_screen.dart';
import 'package:mobile/screens/vendor/products_screen.dart';
import 'package:mobile/screens/vendor/reports_screen.dart';
import 'package:mobile/screens/vendor/reviews_screen.dart';
import 'package:mobile/models/currency.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/utils/navigation_logger.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/vendor/widgets/header.dart';
import 'package:mobile/screens/vendor/widgets/bottom_nav.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:provider/provider.dart';

import 'package:mobile/l10n/app_localizations.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _summary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
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
                              MaterialPageRoute(
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
                              MaterialPageRoute(
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
                              MaterialPageRoute(
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
                              MaterialPageRoute(
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
