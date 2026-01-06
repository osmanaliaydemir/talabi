// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BankAccount _$BankAccountFromJson(Map<String, dynamic> json) => BankAccount(
      id: json['id'] as String,
      accountName: json['accountName'] as String,
      iban: json['iban'] as String,
      isDefault: json['isDefault'] as bool,
    );

Map<String, dynamic> _$BankAccountToJson(BankAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountName': instance.accountName,
      'iban': instance.iban,
      'isDefault': instance.isDefault,
    };

CreateBankAccountRequest _$CreateBankAccountRequestFromJson(
        Map<String, dynamic> json) =>
    CreateBankAccountRequest(
      accountName: json['accountName'] as String,
      iban: json['iban'] as String,
      isDefault: json['isDefault'] as bool,
    );

Map<String, dynamic> _$CreateBankAccountRequestToJson(
        CreateBankAccountRequest instance) =>
    <String, dynamic>{
      'accountName': instance.accountName,
      'iban': instance.iban,
      'isDefault': instance.isDefault,
    };

UpdateBankAccountRequest _$UpdateBankAccountRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateBankAccountRequest(
      id: json['id'] as String,
      accountName: json['accountName'] as String,
      iban: json['iban'] as String,
      isDefault: json['isDefault'] as bool,
    );

Map<String, dynamic> _$UpdateBankAccountRequestToJson(
        UpdateBankAccountRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'accountName': instance.accountName,
      'iban': instance.iban,
      'isDefault': instance.isDefault,
    };
