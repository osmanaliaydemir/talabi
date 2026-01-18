using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class WalletTransaction : BaseEntity
{
    public Guid WalletId { get; set; }
    public Wallet Wallet { get; set; } = null!;

    public decimal Amount { get; set; }
    public TransactionType TransactionType { get; set; }
    public string Description { get; set; } = string.Empty;
    public string? ReferenceId { get; set; } // OrderId, PaymentId etc.
    public string? CustomerOrderId { get; set; }

    public DateTime TransactionDate { get; set; } = DateTime.UtcNow;
}
