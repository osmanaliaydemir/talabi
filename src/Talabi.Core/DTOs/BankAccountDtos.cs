namespace Talabi.Core.DTOs;

public class BankAccountDto
{
    public Guid Id { get; set; }
    public string AccountName { get; set; } = string.Empty;
    public string Iban { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
}

public class CreateBankAccountRequest
{
    public string AccountName { get; set; } = string.Empty;
    public string Iban { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
}

public class UpdateBankAccountRequest
{
    public Guid Id { get; set; }
    public string AccountName { get; set; } = string.Empty;
    public string Iban { get; set; } = string.Empty;
    public bool IsDefault { get; set; }
}
