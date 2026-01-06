import 'package:json_annotation/json_annotation.dart';

part 'wallet_transaction_model.g.dart';

enum TransactionType {
  @JsonValue(1)
  deposit,
  @JsonValue(2)
  withdrawal,
  @JsonValue(3)
  payment,
  @JsonValue(4)
  refund,
  @JsonValue(5)
  earning,
}

@JsonSerializable()
class WalletTransaction {
  WalletTransaction({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.transactionType,
    required this.description,
    this.referenceId,
    required this.transactionDate,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionFromJson(json);
  Map<String, dynamic> toJson() => _$WalletTransactionToJson(this);

  final String id;
  final String walletId;
  final double amount;
  final TransactionType transactionType;
  final String description;
  final String? referenceId;
  final DateTime transactionDate;
}
