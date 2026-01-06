namespace Talabi.Core.DTOs;

public class BankAccountDto
{
    public Guid Id { get; set; }
    public string AccountName { get; set; }
    public string Iban { get; set; }
    public bool IsDefault { get; set; }
}

public class CreateBankAccountRequest
{
    public string AccountName { get; set; }
    public string Iban { get; set; }
    public bool IsDefault { get; set; }
}

public class UpdateBankAccountRequest
{
    public Guid Id { get; set; }
    public string AccountName { get; set; }
    public string Iban { get; set; }
    public bool IsDefault { get; set; }
}
