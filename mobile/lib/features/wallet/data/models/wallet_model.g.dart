// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wallet _$WalletFromJson(Map<String, dynamic> json) => Wallet(
      id: json['id'] as String,
      appUserId: json['appUserId'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$WalletToJson(Wallet instance) => <String, dynamic>{
      'id': instance.id,
      'appUserId': instance.appUserId,
      'balance': instance.balance,
      'currency': instance.currency,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
