import 'package:json_annotation/json_annotation.dart';

part 'withdrawal_request_model.g.dart';

enum WithdrawalStatus {
  @JsonValue(0)
  pending,
  @JsonValue(1)
  approved,
  @JsonValue(2)
  rejected,
  @JsonValue(3)
  completed,
}

@JsonSerializable()
class WithdrawalRequest {
  WithdrawalRequest({
    required this.id,
    required this.appUserId,
    required this.amount,
    required this.iban,
    required this.bankAccountName,
    this.note,
    this.adminNote,
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.completedAt,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) =>
      _$WithdrawalRequestFromJson(json);

  final String id;
  final String appUserId;
  final double amount;
  final String iban;
  final String bankAccountName;
  final String? note;
  final String? adminNote;
  final WithdrawalStatus status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? completedAt;

  Map<String, dynamic> toJson() => _$WithdrawalRequestToJson(this);
}

@JsonSerializable(createFactory: false)
class CreateWithdrawalRequestParams {
  CreateWithdrawalRequestParams({
    required this.amount,
    required this.iban,
    required this.bankAccountName,
    this.note,
  });
  final double amount;
  final String iban;
  final String bankAccountName;
  final String? note;
  Map<String, dynamic> toJson() => _$CreateWithdrawalRequestParamsToJson(this);
}
