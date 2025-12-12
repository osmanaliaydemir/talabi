using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;

namespace Getir.MerchantPortal.Middleware;

/// <summary>
/// Kimlik doğrulanmış kullanıcıların geçerli JWT token'a sahip olduğunu doğrular
/// </summary>
public class SessionValidationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<SessionValidationMiddleware> _logger;

    /// <summary>
    /// SessionValidationMiddleware constructor
    /// </summary>
    /// <param name="next">Sonraki middleware</param>
    /// <param name="logger">Logger instance</param>
    public SessionValidationMiddleware(
        RequestDelegate next,
        ILogger<SessionValidationMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    /// <summary>
    /// Middleware'i çalıştır
    /// </summary>
    /// <param name="context">HTTP context</param>
    /// <returns>Task</returns>
    public async Task InvokeAsync(HttpContext context)
    {
        // Skip validation for login/logout pages and static files
        var path = context.Request.Path.Value?.ToLower() ?? "";
        if (path.Contains("/auth/login") || 
            path.Contains("/auth/logout") ||
            path.Contains("/css/") ||
            path.Contains("/js/") ||
            path.Contains("/lib/") ||
            path.Contains("/sounds/"))
        {
            await _next(context);
            return;
        }

        // Check if user is authenticated via cookie
        if (context.User.Identity?.IsAuthenticated == true)
        {
            // Validate that session has JWT token
            var jwtToken = context.Session.GetString("JwtToken");
            
            if (string.IsNullOrEmpty(jwtToken))
            {
                // Cookie exists but session is invalid (expired/cleared)
                _logger.LogWarning("Authenticated user has no JWT token in session. Signing out user.");
                
                // Clear cookie authentication
                await context.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
                
                // Clear any remaining session data
                context.Session.Clear();
                
                // Redirect to login with return URL
                var returnUrl = context.Request.Path + context.Request.QueryString;
                context.Response.Redirect($"/Auth/Login?returnUrl={Uri.EscapeDataString(returnUrl)}");
                return;
            }
        }

        await _next(context);
    }
}

/// <summary>
/// Middleware kayıt extension metodu
/// </summary>
public static class SessionValidationMiddlewareExtensions
{
    /// <summary>
    /// Session validation middleware'i kaydet
    /// </summary>
    /// <param name="builder">Application builder</param>
    /// <returns>Application builder</returns>
    public static IApplicationBuilder UseSessionValidation(this IApplicationBuilder builder)
    {
        return builder.UseMiddleware<SessionValidationMiddleware>();
    }
}

