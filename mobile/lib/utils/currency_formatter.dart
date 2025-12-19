import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/features/settings/data/models/currency.dart' as currency_model;

class CurrencyFormatter {
  static String format(double amount, currency_model.Currency currency) {
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
      locale: 'tr_TR', // Use Turkish locale for number formatting
    );

    return formatter.format(amount);
  }

  static String formatWithString(double amount, String currencyCode) {
    final currency = currency_model.Currency.fromString(currencyCode);
    return format(amount, currency);
  }

  static String formatWithLocale(
    double amount,
    currency_model.Currency currency,
    Locale locale,
  ) {
    final formatter = NumberFormat.currency(
      symbol: currency.symbol,
      decimalDigits: 2,
      locale: locale.toString(),
    );

    return formatter.format(amount);
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
