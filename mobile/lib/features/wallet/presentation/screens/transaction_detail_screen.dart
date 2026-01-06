import 'package:flutter/material.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/features/wallet/data/models/wallet_transaction_model.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/orders/presentation/screens/vendor/order_detail_screen.dart'
    as vendor;
import 'package:mobile/features/orders/presentation/screens/courier/order_detail_screen.dart'
    as courier;

class TransactionDetailScreen extends StatelessWidget {
  final WalletTransaction transaction;
  final bool isVendor;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.isVendor,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isPositive =
        transaction.transactionType == TransactionType.deposit ||
        transaction.transactionType == TransactionType.earning ||
        transaction.transactionType == TransactionType.refund;

    final primaryColor = isVendor ? Colors.deepPurple : AppTheme.primaryOrange;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.transactionDetail),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: isPositive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    child: Icon(
                      isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    transaction.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isPositive ? "+" : "-"}${transaction.amount.toStringAsFixed(2)} TRY',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Details List
            _buildDetailItem(
              context,
              Icons.calendar_today_outlined,
              localizations.dateLabel,
              DateFormat(
                'dd MMMM yyyy, HH:mm',
              ).format(transaction.transactionDate),
            ),
            _buildDetailItem(
              context,
              Icons.info_outline,
              localizations.transactionType,
              _getTransactionTypeString(context, transaction.transactionType),
            ),
            if (transaction.referenceId != null)
              _buildDetailItem(
                context,
                Icons.tag,
                localizations.referenceNo,
                transaction.referenceId!,
              ),
            const SizedBox(height: 40),
            // Action Button
            if (transaction.referenceId != null &&
                (transaction.transactionType == TransactionType.earning ||
                    transaction.transactionType == TransactionType.payment))
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (isVendor) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => vendor.VendorOrderDetailScreen(
                            orderId: transaction.referenceId!,
                          ),
                        ),
                      );
                    } else {
                      // Handle courier or other types
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => courier.OrderDetailScreen(
                            orderId: transaction.referenceId!,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(localizations.viewOrder),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.grey.shade600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTransactionTypeString(BuildContext context, TransactionType type) {
    final localizations = AppLocalizations.of(context)!;
    switch (type) {
      case TransactionType.deposit:
        return localizations.transactionDeposit;
      case TransactionType.withdrawal:
        return localizations.transactionWithdrawal;
      case TransactionType.payment:
        return localizations.transactionPayment;
      case TransactionType.refund:
        return localizations.transactionRefund;
      case TransactionType.earning:
        return localizations.transactionEarning;
    }
  }
}
