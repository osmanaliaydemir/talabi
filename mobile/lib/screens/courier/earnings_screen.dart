import 'package:flutter/material.dart';

import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/models/courier_earning.dart';
import 'package:mobile/models/currency.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/utils/currency_formatter.dart';
import 'package:mobile/screens/courier/widgets/header.dart';
import 'package:mobile/screens/courier/widgets/bottom_nav.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CourierService _courierService = CourierService();

  EarningsSummary? _todayEarnings;
  EarningsSummary? _weeklyEarnings;
  EarningsSummary? _monthlyEarnings;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    LoggerService().debug('EarningsScreen: Loading earnings...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      LoggerService().debug('EarningsScreen: Fetching today, weekly, and monthly earnings...');
      final results = await Future.wait([
        _courierService.getTodayEarnings(),
        _courierService.getWeeklyEarnings(),
        _courierService.getMonthlyEarnings(),
      ]);

      LoggerService().debug(
        'EarningsScreen: Earnings loaded - Today: ${results[0].totalEarnings}, Week: ${results[1].totalEarnings}, Month: ${results[2].totalEarnings}',
      );
      if (mounted) {
        setState(() {
          _todayEarnings = results[0];
          _weeklyEarnings = results[1];
          _monthlyEarnings = results[2];
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      LoggerService().error('EarningsScreen: ERROR loading earnings', e, stackTrace);
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CourierHeader(
        title: localizations?.earningsTitle ?? 'Kazançlar',
        leadingIcon: Icons.ssid_chart_outlined,
        showBackButton: false,
        onRefresh: _loadEarnings,
      ),
      body: Column(
        children: [
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.teal,
              labelColor: Colors.teal,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: localizations?.todayEarnings ?? 'Today'),
                Tab(text: localizations?.thisWeek ?? 'This Week'),
                Tab(text: localizations?.thisMonth ?? 'This Month'),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.teal))
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: $_error',
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadEarnings,
                          child: Text(localizations?.retry ?? 'Retry'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEarningsTab(_todayEarnings!),
                      _buildEarningsTab(_weeklyEarnings!),
                      _buildEarningsTab(_monthlyEarnings!),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CourierBottomNav(currentIndex: 2),
    );
  }

  Widget _buildEarningsTab(EarningsSummary summary) {
    final localizations = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _loadEarnings,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.teal,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      localizations?.totalEarningsLabel ?? 'Total Earnings',
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(
                        summary.totalEarnings,
                        Currency.try_,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          localizations?.deliveries ?? 'Deliveries',
                          '${summary.totalDeliveries}',
                        ),
                        _buildStatItem(
                          localizations?.avgPerDelivery ?? 'Avg. per Delivery',
                          CurrencyFormatter.format(
                            summary.averageEarningPerDelivery,
                            Currency.try_,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Earnings List
            Text(
              localizations?.history ?? 'History',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (summary.earnings.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    localizations?.noEarningsForPeriod ??
                        'No earnings found for this period.',
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: summary.earnings.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final earning = summary.earnings[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.shade100,
                      child: const Icon(Icons.attach_money, color: Colors.teal),
                    ),
                    title: Text('Order #${earning.orderId}'),
                    subtitle: Text(
                      DateFormat('MMM d, HH:mm').format(earning.earnedAt),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          CurrencyFormatter.format(
                            earning.totalEarning,
                            Currency.try_,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                        if (earning.tipAmount > 0)
                          Text(
                            '+${CurrencyFormatter.format(earning.tipAmount, Currency.try_)} tip',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
