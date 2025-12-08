using System.Text.Json.Serialization;

namespace Talabi.Core.DTOs;

public class UserPreferencesDto
{
    [JsonPropertyName("language")]
    public string Language { get; set; } = "tr";
    
    [JsonPropertyName("currency")]
    public string Currency { get; set; } = "TRY";
    
    [JsonPropertyName("timeZone")]
    public string? TimeZone { get; set; }
    
    [JsonPropertyName("dateFormat")]
    public string? DateFormat { get; set; }
    
    [JsonPropertyName("timeFormat")]
    public string? TimeFormat { get; set; }
}

public class UpdateUserPreferencesDto
{
    [JsonPropertyName("language")]
    public string? Language { get; set; }
    
    [JsonPropertyName("currency")]
    public string? Currency { get; set; }
    
    [JsonPropertyName("timeZone")]
    public string? TimeZone { get; set; }
    
    [JsonPropertyName("dateFormat")]
    public string? DateFormat { get; set; }
    
    [JsonPropertyName("timeFormat")]
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

