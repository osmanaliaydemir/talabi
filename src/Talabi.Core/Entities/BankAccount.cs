using Talabi.Core.Entities;

namespace Talabi.Core.Entities;

public class BankAccount : BaseEntity
{
    public string AppUserId { get; set; } = null!;
    public string AccountName { get; set; } = string.Empty;
    public string Iban { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
}
