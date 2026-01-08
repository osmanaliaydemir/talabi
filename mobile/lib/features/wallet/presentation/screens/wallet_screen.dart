import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/features/wallet/data/models/wallet_model.dart';
import 'package:mobile/features/wallet/data/models/wallet_transaction_model.dart';
import 'package:mobile/features/wallet/data/models/withdrawal_request_model.dart';
import 'package:mobile/features/wallet/presentation/screens/top_up_screen.dart';
import 'package:mobile/features/wallet/presentation/screens/withdraw_screen.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/features/wallet/presentation/screens/transaction_detail_screen.dart';
import 'package:mobile/features/dashboard/presentation/widgets/vendor_header.dart';
import 'package:mobile/widgets/empty_state_widget.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, this.bottomNavigationBar});

  final Widget? bottomNavigationBar;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final ApiService _apiService = GetIt.I<ApiService>();
  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  List<WithdrawalRequest> _withdrawalRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final wallet = await _apiService.getWallet();
      final transactions = await _apiService.getWalletTransactions();
      final withdrawalRequests = await _apiService.getWithdrawalRequests();

      if (mounted) {
        setState(() {
          _wallet = wallet;
          _transactions = transactions;
          _withdrawalRequests = withdrawalRequests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isVendor = widget.bottomNavigationBar != null;

    return Scaffold(
      appBar: isVendor
          ? VendorHeader(
              title: localizations.myWallet,
              leadingIcon: Icons.account_balance_wallet,
              showBackButton: false,
              onRefresh: _loadData,
            )
          : AppBar(title: Text(localizations.myWallet)),
      bottomNavigationBar: widget.bottomNavigationBar,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(localizations, isVendor),
                      if (_withdrawalRequests.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          localizations.withdrawalRequests,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        _buildWithdrawalRequestsList(localizations),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        localizations.transactionHistory,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildTransactionList(localizations, isVendor),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWithdrawalRequestsList(AppLocalizations localizations) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _withdrawalRequests.length,
        itemBuilder: (context, index) {
          final request = _withdrawalRequests[index];

          Color statusColor;
          String statusText;
          IconData statusIcon;

          switch (request.status) {
            case WithdrawalStatus.pending:
              statusColor = Colors.orange;
              statusText = localizations.pending;
              statusIcon = Icons.timer;
              break;
            case WithdrawalStatus.approved:
              statusColor = Colors.blue;
              statusText = localizations.approved;
              statusIcon = Icons.check_circle_outline;
              break;
            case WithdrawalStatus.rejected:
              statusColor = Colors.red;
              statusText = localizations.rejected;
              statusIcon = Icons.cancel_outlined;
              break;
            case WithdrawalStatus.completed:
              statusColor = Colors.green;
              statusText = localizations.completed;
              statusIcon = Icons.check_circle;
              break;
          }

          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${request.amount.toStringAsFixed(2)} ₺',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Icon(statusIcon, color: statusColor, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.createdAt.toString().split(' ')[0],
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(AppLocalizations localizations, bool isVendor) {
    final primaryColor = isVendor ? Colors.deepPurple : AppTheme.primaryOrange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.currentBalance,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${_wallet?.balance.toStringAsFixed(2)} ${_wallet?.currency ?? "TRY"}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TopUpScreen(isVendor: isVendor),
                      ),
                    ).then((_) => _loadData());
                  },
                  icon: const Icon(Icons.add),
                  label: Text(localizations.topUpBalance),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WithdrawScreen(
                          isVendor: isVendor,
                          currentBalance: _wallet?.balance ?? 0.0,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                  icon: const Icon(Icons.arrow_upward),
                  label: Text(localizations.withdraw),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(AppLocalizations localizations, bool isVendor) {
    if (_transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: EmptyStateWidget(
          message: localizations.noTransactionsYet,
          iconData: Icons.account_balance_wallet_outlined,
          isCompact: true,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final isPositive =
            transaction.transactionType == TransactionType.deposit ||
            transaction.transactionType == TransactionType.earning ||
            transaction.transactionType == TransactionType.refund;

        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TransactionDetailScreen(
                  transaction: transaction,
                  isVendor: isVendor,
                ),
              ),
            );
          },
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: isPositive
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            child: Icon(
              isPositive ? Icons.arrow_downward : Icons.arrow_upward,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
          title: Text(transaction.description),
          subtitle: Text(
            transaction.transactionDate.toString().split('.')[0],
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Text(
            '${isPositive ? "+" : "-"}${transaction.amount.toStringAsFixed(2)} TRY',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }
}
