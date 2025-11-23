namespace Talabi.Core.Services;

public interface ICurrencyService
{
    decimal Convert(decimal amount, string fromCurrency, string toCurrency);
    decimal GetExchangeRate(string fromCurrency, string toCurrency);
    Task<decimal> GetExchangeRateAsync(string fromCurrency, string toCurrency);
}

