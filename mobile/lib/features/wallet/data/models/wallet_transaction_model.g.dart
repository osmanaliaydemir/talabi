// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_transaction_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WalletTransaction _$WalletTransactionFromJson(Map<String, dynamic> json) =>
    WalletTransaction(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      amount: (json['amount'] as num).toDouble(),
      transactionType:
          $enumDecode(_$TransactionTypeEnumMap, json['transactionType']),
      description: json['description'] as String,
      referenceId: json['referenceId'] as String?,
      customerOrderId: json['customerOrderId'] as String?,
      transactionDate: DateTime.parse(json['transactionDate'] as String),
    );

Map<String, dynamic> _$WalletTransactionToJson(WalletTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'walletId': instance.walletId,
      'amount': instance.amount,
      'transactionType': _$TransactionTypeEnumMap[instance.transactionType]!,
      'description': instance.description,
      'referenceId': instance.referenceId,
      'customerOrderId': instance.customerOrderId,
      'transactionDate': instance.transactionDate.toIso8601String(),
    };

const _$TransactionTypeEnumMap = {
  TransactionType.deposit: 1,
  TransactionType.withdrawal: 2,
  TransactionType.payment: 3,
  TransactionType.refund: 4,
  TransactionType.earning: 5,
};
