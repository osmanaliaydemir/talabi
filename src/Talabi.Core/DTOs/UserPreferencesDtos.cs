namespace Talabi.Core.DTOs;

public class UserPreferencesDto
{
    public string Language { get; set; } = "tr";
    public string Currency { get; set; } = "TRY";
    public string? TimeZone { get; set; }
    public string? DateFormat { get; set; }
    public string? TimeFormat { get; set; }
}

public class UpdateUserPreferencesDto
{
    public string? Language { get; set; }
    public string? Currency { get; set; }
    public string? TimeZone { get; set; }
    public string? DateFormat { get; set; }
    public string? TimeFormat { get; set; }
}

public class SupportedLanguageDto
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string NativeName { get; set; } = string.Empty;
}

public class SupportedCurrencyDto
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Symbol { get; set; } = string.Empty;
    public decimal ExchangeRate { get; set; } // Exchange rate to base currency (TRY)
}

