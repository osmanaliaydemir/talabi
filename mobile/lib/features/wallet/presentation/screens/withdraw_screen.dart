import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/toast_message.dart';
import 'package:mobile/features/wallet/data/models/bank_account_model.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({
    super.key,
    this.isVendor = false,
    required this.currentBalance,
  });

  final bool isVendor;
  final double currentBalance;

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final ApiService _apiService = GetIt.I<ApiService>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();
  bool _isLoading = false;
  List<BankAccount> _bankAccounts = [];
  bool _isAccountsLoading = false;
  BankAccount? _selectedAccount;

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
  }

  Future<void> _loadBankAccounts() async {
    setState(() => _isAccountsLoading = true);
    try {
      final accounts = await _apiService.getBankAccounts();
      if (mounted) {
        setState(() {
          _bankAccounts = accounts;
          if (_bankAccounts.isNotEmpty) {
            _selectedAccount = _bankAccounts.firstWhere(
              (a) => a.isDefault,
              orElse: () => _bankAccounts.first,
            );
            _ibanController.text = _selectedAccount!.iban;
          }
        });
      }
    } catch (e) {
      // Quietly fail for bank accounts fetch
    } finally {
      if (mounted) {
        setState(() => _isAccountsLoading = false);
      }
    }
  }

  Future<void> _addOrEditAccount(
    AppLocalizations localizations, {
    BankAccount? account,
  }) async {
    final nameController = TextEditingController(text: account?.accountName);
    final ibanController = TextEditingController(text: account?.iban);
    bool isDefault = account?.isDefault ?? false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            account == null
                ? localizations.addAccount
                : localizations.editAccount,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: localizations.accountName,
                  hintText: 'Ziraat, Maaş vb.',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ibanController,
                decoration: InputDecoration(
                  labelText: localizations.ibanOrAccountNumber,
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text(localizations.defaultLabel),
                value: isDefault,
                onChanged: (val) =>
                    setDialogState(() => isDefault = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ToastMessage.show(
                    context,
                    message: localizations.accountNameRequired,
                    isSuccess: false,
                  );
                  return;
                }
                if (ibanController.text.trim().isEmpty) {
                  ToastMessage.show(
                    context,
                    message: localizations.ibanRequired,
                    isSuccess: false,
                  );
                  return;
                }

                try {
                  if (account == null) {
                    await _apiService.addBankAccount(
                      CreateBankAccountRequest(
                        accountName: nameController.text.trim(),
                        iban: ibanController.text.trim(),
                        isDefault: isDefault,
                      ),
                    );
                  } else {
                    await _apiService.updateBankAccount(
                      UpdateBankAccountRequest(
                        id: account.id,
                        accountName: nameController.text.trim(),
                        iban: ibanController.text.trim(),
                        isDefault: isDefault,
                      ),
                    );
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  _loadBankAccounts();
                } catch (e) {
                  if (context.mounted) {
                    ToastMessage.show(
                      context,
                      message: e.toString(),
                      isSuccess: false,
                    );
                  }
                }
              },
              child: Text(localizations.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount(
    AppLocalizations localizations,
    BankAccount account,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.deleteAccount),
        content: Text(localizations.areYouSure),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              localizations.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.deleteBankAccount(account.id);
        _loadBankAccounts();
      } catch (e) {
        if (mounted) {
          ToastMessage.show(context, message: e.toString(), isSuccess: false);
        }
      }
    }
  }

  final List<double> _predefinedAmounts = [100, 250, 500, 1000];

  Future<void> _withdraw(AppLocalizations localizations) async {
    final amount = double.tryParse(_amountController.text);
    final iban = _ibanController.text.trim();

    if (amount == null || amount <= 0) {
      ToastMessage.show(
        context,
        message: localizations.enterValidAmount,
        isSuccess: false,
      );
      return;
    }

    if (amount > widget.currentBalance) {
      ToastMessage.show(
        context,
        message: localizations.insufficientBalance,
        isSuccess: false,
      );
      return;
    }

    if (iban.isEmpty || iban.length < 10) {
      ToastMessage.show(
        context,
        message: localizations.enterValidIban,
        isSuccess: false,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.withdraw(amount, iban);
      if (mounted) {
        ToastMessage.show(
          context,
          message: localizations.withdrawSuccessful,
          isSuccess: true,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException) {
        if (e.response?.data != null && e.response?.data is Map) {
          final data = e.response!.data as Map;
          if (data.containsKey('message')) {
            errorMessage = data['message'];
          } else if (data.containsKey('error')) {
            errorMessage = data['error'];
          }
        }
      }

      if (mounted) {
        ToastMessage.show(context, message: errorMessage, isSuccess: false);
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
        title: Text(localizations.withdrawBalance),
        backgroundColor: widget.isVendor ? AppTheme.vendorPrimary : null,
        foregroundColor: widget.isVendor ? Colors.white : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.amountToWithdraw,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${localizations.balance}: ${widget.currentBalance.toStringAsFixed(2)} TRY',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                suffixIcon: TextButton(
                  onPressed: () {
                    _amountController.text = widget.currentBalance
                        .toStringAsFixed(2);
                  },
                  child: Text(
                    localizations.all,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                suffixText: 'TRY',
                border: const OutlineInputBorder(),
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
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.savedAccounts,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _addOrEditAccount(localizations),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(localizations.addAccount),
                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                ),
              ],
            ),
            if (_isAccountsLoading)
              const Center(child: CircularProgressIndicator())
            else if (_bankAccounts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  localizations.noSavedAccounts,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _bankAccounts.length,
                  itemBuilder: (context, index) {
                    final acc = _bankAccounts[index];
                    final isSelected = _selectedAccount?.id == acc.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onLongPress: () {
                          showModalBottomSheet(
                            context: context,
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.edit),
                                    title: Text(localizations.editAccount),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _addOrEditAccount(
                                        localizations,
                                        account: acc,
                                      );
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    title: Text(localizations.deleteAccount),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _deleteAccount(localizations, acc);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        onTap: () {
                          setState(() {
                            _selectedAccount = acc;
                            _ibanController.text = acc.iban;
                          });
                        },
                        child: Container(
                          width: 160,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? primaryColor.withValues(alpha: 0.05)
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      acc.accountName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isSelected
                                            ? primaryColor
                                            : Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (acc.isDefault)
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: Colors.amber,
                                    ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                acc.iban,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            Text(
              localizations.ibanOrAccountNumber,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ibanController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'IBAN / Hesap No',
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () => _withdraw(localizations),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        localizations.withdraw,
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
