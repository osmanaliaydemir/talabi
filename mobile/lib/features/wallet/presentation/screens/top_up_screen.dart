import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/api_service.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key, this.isVendor = false});

  final bool isVendor;

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final ApiService _apiService = GetIt.I<ApiService>();
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  final List<double> _predefinedAmounts = [50, 100, 200, 500];

  Future<void> _deposit(AppLocalizations localizations) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(localizations.enterValidAmount)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.deposit(amount);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(localizations.topUpSuccessful)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final primaryColor = widget.isVendor
        ? Colors.deepPurple
        : AppTheme.primaryOrange;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.topUp),
        backgroundColor: widget.isVendor ? AppTheme.vendorPrimary : null,
        foregroundColor: widget.isVendor ? Colors.white : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.amountToTopUp,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                suffixText: 'TRY',
                border: OutlineInputBorder(),
                hintText: '0.00',
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _predefinedAmounts.map((amount) {
                return InkWell(
                  onTap: () {
                    _amountController.text = amount.toStringAsFixed(0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${amount.toInt()} ₺',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _deposit(localizations),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        localizations.makePayment,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
