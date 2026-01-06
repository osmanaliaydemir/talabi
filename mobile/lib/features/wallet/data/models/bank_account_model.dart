import 'package:json_annotation/json_annotation.dart';

part 'bank_account_model.g.dart';

@JsonSerializable()
class BankAccount {
  BankAccount({
    required this.id,
    required this.accountName,
    required this.iban,
    required this.isDefault,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) =>
      _$BankAccountFromJson(json);

  final String id;
  final String accountName;
  final String iban;
  final bool isDefault;

  Map<String, dynamic> toJson() => _$BankAccountToJson(this);
}

@JsonSerializable()
class CreateBankAccountRequest {
  CreateBankAccountRequest({
    required this.accountName,
    required this.iban,
    required this.isDefault,
  });

  factory CreateBankAccountRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBankAccountRequestFromJson(json);

  final String accountName;
  final String iban;
  final bool isDefault;

  Map<String, dynamic> toJson() => _$CreateBankAccountRequestToJson(this);
}

@JsonSerializable()
class UpdateBankAccountRequest {
  UpdateBankAccountRequest({
    required this.id,
    required this.accountName,
    required this.iban,
    required this.isDefault,
  });

  factory UpdateBankAccountRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateBankAccountRequestFromJson(json);

  final String id;
  final String accountName;
  final String iban;
  final bool isDefault;

  Map<String, dynamic> toJson() => _$UpdateBankAccountRequestToJson(this);
}
