using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class WithdrawalRequest : BaseEntity
{
    public string AppUserId { get; set; } = string.Empty;
    public AppUser? AppUser { get; set; }

    public decimal Amount { get; set; }
    public string Iban { get; set; } = string.Empty;
    public string BankAccountName { get; set; } = string.Empty;
    public string? Note { get; set; }
    public string? AdminNote { get; set; }

    public WithdrawalStatus Status { get; set; } = WithdrawalStatus.Pending;

    public DateTime? ApprovedAt { get; set; }
    public string? ApprovedBy { get; set; }

    public DateTime? RejectedAt { get; set; }
    public string? RejectedBy { get; set; }

    public DateTime? CompletedAt { get; set; }
    public string? CompletedBy { get; set; }
}
