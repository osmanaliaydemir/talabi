// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'withdrawal_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WithdrawalRequest _$WithdrawalRequestFromJson(Map<String, dynamic> json) =>
    WithdrawalRequest(
      id: json['id'] as String,
      appUserId: json['appUserId'] as String,
      amount: (json['amount'] as num).toDouble(),
      iban: json['iban'] as String,
      bankAccountName: json['bankAccountName'] as String,
      note: json['note'] as String?,
      adminNote: json['adminNote'] as String?,
      status: $enumDecode(_$WithdrawalStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      approvedAt: json['approvedAt'] == null
          ? null
          : DateTime.parse(json['approvedAt'] as String),
      rejectedAt: json['rejectedAt'] == null
          ? null
          : DateTime.parse(json['rejectedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$WithdrawalRequestToJson(WithdrawalRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'appUserId': instance.appUserId,
      'amount': instance.amount,
      'iban': instance.iban,
      'bankAccountName': instance.bankAccountName,
      'note': instance.note,
      'adminNote': instance.adminNote,
      'status': _$WithdrawalStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'approvedAt': instance.approvedAt?.toIso8601String(),
      'rejectedAt': instance.rejectedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };

const _$WithdrawalStatusEnumMap = {
  WithdrawalStatus.pending: 0,
  WithdrawalStatus.approved: 1,
  WithdrawalStatus.rejected: 2,
  WithdrawalStatus.completed: 3,
};

Map<String, dynamic> _$CreateWithdrawalRequestParamsToJson(
        CreateWithdrawalRequestParams instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'iban': instance.iban,
      'bankAccountName': instance.bankAccountName,
      'note': instance.note,
    };
