using Microsoft.AspNetCore.Localization;
using System.Globalization;

namespace Talabi.Portal.Middleware;

/// <summary>
/// Özelleştirilmiş kültür middleware'i
/// </summary>
public class CultureMiddleware
{
    private readonly RequestDelegate _next;

    /// <summary>
    /// CultureMiddleware constructor
    /// </summary>
    /// <param name="next">Sonraki middleware</param>
    public CultureMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    /// <summary>
    /// Middleware'i çalıştır
    /// </summary>
    /// <param name="context">HTTP context</param>
    /// <returns>Task</returns>
    public async Task InvokeAsync(HttpContext context)
    {
        // Get culture from cookie
        var cultureCookie = context.Request.Cookies["Talabi.Portal.Culture"];

        if (!string.IsNullOrEmpty(cultureCookie))
        {
            try
            {
                var culture = CookieRequestCultureProvider.ParseCookieValue(cultureCookie);
                if (culture != null)
                {
                    // Set both culture and UI culture
                    var cultureInfo = new CultureInfo(culture.Cultures.FirstOrDefault().Value ?? "tr-TR");
                    var uiCultureInfo = new CultureInfo(culture.UICultures.FirstOrDefault().Value ?? "tr-TR");

                    CultureInfo.CurrentCulture = cultureInfo;
                    CultureInfo.CurrentUICulture = uiCultureInfo;

                    // Also set thread cultures
                    Thread.CurrentThread.CurrentCulture = cultureInfo;
                    Thread.CurrentThread.CurrentUICulture = uiCultureInfo;
                }
            }
            catch (Exception ex)
            {
                // Log error but don't break the request
                Console.WriteLine($"Culture parsing error: {ex.Message}");
            }
        }

        await _next(context);
    }
}

/// <summary>
/// Middleware kayıt extension metodu
/// </summary>
public static class CultureMiddlewareExtensions
{
    /// <summary>
    /// Culture middleware'i kaydet
    /// </summary>
    /// <param name="builder">Application builder</param>
    /// <returns>Application builder</returns>
    public static IApplicationBuilder UseCultureMiddleware(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<CultureMiddleware>();
    }
}
