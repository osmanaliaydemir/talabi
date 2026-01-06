import 'package:json_annotation/json_annotation.dart';

part 'wallet_model.g.dart';

@JsonSerializable()
class Wallet {
  Wallet({
    required this.id,
    required this.appUserId,
    required this.balance,
    required this.currency,
    required this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);

  final String id;
  final String appUserId;
  final double balance;
  final String currency;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$WalletToJson(this);
}
