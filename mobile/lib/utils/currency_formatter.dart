import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double amount, String currency) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
      locale: 'tr_TR', // Use Turkish locale for number formatting
    );

    return formatter.format(amount);
  }

  static String formatWithLocale(
    double amount,
    String currency,
    Locale locale,
  ) {
    final formatter = NumberFormat.currency(
      symbol: _getCurrencySymbol(currency),
      decimalDigits: 2,
      locale: locale.toString(),
    );

    return formatter.format(amount);
  }

  static String _getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'TRY':
        return '₺';
      case 'USDT':
        return 'USDT';
      default:
        return currency;
    }
  }

  static double convert(
    double amount,
    String fromCurrency,
    String toCurrency,
    double exchangeRate,
  ) {
    if (fromCurrency == toCurrency) {
      return amount;
    }

    // Convert to base currency (TRY) first if needed
    if (fromCurrency == 'USDT') {
      amount = amount / exchangeRate; // USDT to TRY
    }

    // Convert to target currency
    if (toCurrency == 'USDT') {
      return amount * exchangeRate; // TRY to USDT
    }

    return amount; // Already in TRY
  }
}
