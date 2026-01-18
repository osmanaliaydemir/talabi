using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class Wallet : BaseEntity
{
    public string AppUserId { get; set; } = null!;
    public AppUser AppUser { get; set; } = null!;

    public decimal Balance { get; set; }
    public string Currency { get; set; } = "TRY";

    public ICollection<WalletTransaction> Transactions { get; set; }

    public Wallet()
    {
        Transactions = new HashSet<WalletTransaction>();
    }
}
