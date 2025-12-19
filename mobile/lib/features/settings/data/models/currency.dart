enum Currency {
  try_('TRY', '₺'),
  usd('USD', '\$'),
  syp('SYP', 'ل.س');

  const Currency(this.code, this.symbol);

  final String code;
  final String symbol;

  static Currency fromString(String? value) {
    if (value == null) return Currency.try_;
    switch (value.toUpperCase()) {
      case 'TRY':
        return Currency.try_;
      case 'USD':
        return Currency.usd;
      case 'SYP':
        return Currency.syp;
      default:
        return Currency.try_;
    }
  }

  static Currency fromInt(int? value) {
    if (value == null) return Currency.try_;
    switch (value) {
      case 0:
        return Currency.try_;
      case 1:
        return Currency.usd;
      case 2:
        return Currency.syp;
      default:
        return Currency.try_;
    }
  }

  int toInt() {
    switch (this) {
      case Currency.try_:
        return 0;
      case Currency.usd:
        return 1;
      case Currency.syp:
        return 2;
    }
  }

  String toJson() => code;
}
