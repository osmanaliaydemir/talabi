using Talabi.Core.Enums;

namespace Talabi.Core.DTOs;

public class CreateWithdrawalRequest
{
    public decimal Amount { get; set; }
    public string Iban { get; set; } = string.Empty;
    public string BankAccountName { get; set; } = string.Empty;
    public string? Note { get; set; }
}

public class WithdrawalRequestDto
{
    public Guid Id { get; set; }
    public decimal Amount { get; set; }
    public string Iban { get; set; } = string.Empty;
    public string BankAccountName { get; set; } = string.Empty;
    public string? Note { get; set; }
    public string? AdminNote { get; set; }
    public WithdrawalStatus Status { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? StatusUpdatedAt { get; set; }
}
