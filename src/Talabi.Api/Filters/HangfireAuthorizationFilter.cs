using Hangfire.Dashboard;
using System.Security.Claims;

namespace Talabi.Api.Filters;

/// <summary>
/// Hangfire Dashboard authorization filter - Only allows Admin users
/// </summary>
public class HangfireAuthorizationFilter : IDashboardAuthorizationFilter
{
    public bool Authorize(DashboardContext context)
    {
        var httpContext = context.GetHttpContext();
        
        // Check if user is authenticated
        if (!httpContext.User.Identity?.IsAuthenticated ?? true)
        {
            return false;
        }

        // Check if user has Admin role
        // JWT token'dan role claim'ini kontrol et
        // AuthService'te hem "role" claim'i (UserRole enum) hem de ClaimTypes.Role (Identity role) ekleniyor
        var roleClaim = httpContext.User.FindFirst(ClaimTypes.Role)?.Value 
                       ?? httpContext.User.FindFirst("role")?.Value
                       ?? httpContext.User.FindFirst("Role")?.Value;

        // Admin rolü kontrolü
        if (string.IsNullOrWhiteSpace(roleClaim))
        {
            return false;
        }

        // Role claim'i "Admin" (UserRole enum string) veya Identity role olarak "Admin" olmalı
        // UserRole.Admin = 3, ama ToString() ile "Admin" döner
        return roleClaim.Equals("Admin", StringComparison.OrdinalIgnoreCase);
    }
}

