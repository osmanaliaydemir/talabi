using Microsoft.AspNetCore.Http;

namespace Talabi.Api.Middleware;

/// <summary>
/// Middleware to add security headers including Content Security Policy
/// </summary>
public class SecurityHeadersMiddleware
{
    private readonly RequestDelegate _next;

    public SecurityHeadersMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Content Security Policy - Güçlendirilmiş (unsafe-inline ve unsafe-eval kaldırıldı)
        context.Response.Headers.Append("Content-Security-Policy", 
            "default-src 'self'; " +
            "script-src 'self'; " +  // unsafe-inline ve unsafe-eval kaldırıldı (XSS koruması)
            "style-src 'self' 'unsafe-inline'; " +  // CSS için unsafe-inline gerekli (Scalar UI için)
            "img-src 'self' data: https:; " +
            "font-src 'self' data:; " +
            "connect-src 'self'; " +
            "frame-ancestors 'none';");

        // X-Content-Type-Options
        context.Response.Headers.Append("X-Content-Type-Options", "nosniff");

        // X-Frame-Options
        context.Response.Headers.Append("X-Frame-Options", "DENY");

        // X-XSS-Protection (legacy, but still useful for older browsers)
        context.Response.Headers.Append("X-XSS-Protection", "1; mode=block");

        // Referrer-Policy
        context.Response.Headers.Append("Referrer-Policy", "strict-origin-when-cross-origin");

        // Permissions-Policy
        context.Response.Headers.Append("Permissions-Policy", 
            "geolocation=(), microphone=(), camera=()");

        await _next(context);
    }
}

