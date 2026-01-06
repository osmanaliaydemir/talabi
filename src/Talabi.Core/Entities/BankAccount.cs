using Talabi.Core.Entities;

namespace Talabi.Core.Entities;

public class BankAccount : BaseEntity
{
    public string AppUserId { get; set; }
    public string AccountName { get; set; }
    public string Iban { get; set; }
    public bool IsDefault { get; set; }
}
