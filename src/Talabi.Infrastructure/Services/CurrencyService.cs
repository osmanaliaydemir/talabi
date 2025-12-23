using Microsoft.Extensions.Logging;
using Talabi.Core.Services;

namespace Talabi.Infrastructure.Services;

public class CurrencyService(HttpClient httpClient, ILogger<CurrencyService> logger) : ICurrencyService
{
    private readonly HttpClient _httpClient = httpClient;
    private readonly ILogger<CurrencyService> _logger = logger;

    // Cache for exchange rates (in production, use Redis or similar)
    private readonly Dictionary<string, decimal> _exchangeRates = new()
    {
        { "TRY_USDT", 0.034m }, // Example: 1 TRY = 0.034 USDT
        { "USDT_TRY", 29.41m }  // Example: 1 USDT = 29.41 TRY
    };

    public decimal Convert(decimal amount, string fromCurrency, string toCurrency)
    {
        if (fromCurrency == toCurrency)
            return amount;

        var rate = GetExchangeRate(fromCurrency, toCurrency);
        return amount * rate;
    }

    public decimal GetExchangeRate(string fromCurrency, string toCurrency)
    {
        if (fromCurrency == toCurrency)
            return 1.0m;

        var key = $"{fromCurrency}_{toCurrency}";
        if (_exchangeRates.TryGetValue(key, out var rate))
        {
            return rate;
        }

        // Try reverse rate
        var reverseKey = $"{toCurrency}_{fromCurrency}";
        if (_exchangeRates.TryGetValue(reverseKey, out var reverseRate))
        {
            return 1.0m / reverseRate;
        }

        _logger.LogWarning($"Exchange rate not found for {fromCurrency} to {toCurrency}, using default 1.0");
        return 1.0m;
    }

    public Task<decimal> GetExchangeRateAsync(string fromCurrency, string toCurrency)
    {
        // TODO: Implement real-time exchange rate fetching from an API
        // For now, return cached rate
        return Task.FromResult(GetExchangeRate(fromCurrency, toCurrency));
    }
}

