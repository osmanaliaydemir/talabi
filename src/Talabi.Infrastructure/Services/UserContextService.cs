using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Interfaces;
using Microsoft.Extensions.Logging;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace Talabi.Infrastructure.Services;

/// <summary>
/// Kullanıcı context servisi implementasyonu
/// Mevcut kullanıcı bilgilerini ve rollerini sağlar
/// </summary>
public class UserContextService : IUserContextService
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<UserContextService> _logger;

    public UserContextService(
        IHttpContextAccessor httpContextAccessor,
        IUnitOfWork unitOfWork,
        ILogger<UserContextService> logger)
    {
        _httpContextAccessor = httpContextAccessor;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public string? GetUserId()
    {
        var user = _httpContextAccessor.HttpContext?.User;
        if (user == null) return null;

        // Prefer standard NameIdentifier
        var id = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!string.IsNullOrWhiteSpace(id)) return id;

        // JWT subject claim (depends on MapInboundClaims / NameClaimType settings)
        id = user.FindFirstValue(JwtRegisteredClaimNames.Sub) ?? user.FindFirstValue("sub");
        if (!string.IsNullOrWhiteSpace(id)) return id;

        // Fallbacks (some providers use these)
        id = user.FindFirstValue("uid") ?? user.FindFirstValue(ClaimTypes.Name);
        if (!string.IsNullOrWhiteSpace(id)) return id;

        return null;
    }

    public async Task<Guid?> GetVendorIdAsync()
    {
        var userId = GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return null;
        }

        try
        {
            var vendor = await _unitOfWork.Vendors.Query()
                .FirstOrDefaultAsync(v => v.OwnerId == userId);
            return vendor?.Id;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting vendor ID for user: {UserId}", userId);
            return null;
        }
    }

    public async Task<Guid?> GetCourierIdAsync()
    {
        var userId = GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return null;
        }

        try
        {
            var courier = await _unitOfWork.Couriers.Query()
                .FirstOrDefaultAsync(c => c.UserId == userId);
            return courier?.Id;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting courier ID for user: {UserId}", userId);
            return null;
        }
    }

    public async Task<Guid?> GetCustomerIdAsync()
    {
        var userId = GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return null;
        }

        try
        {
            var customer = await _unitOfWork.Customers.Query()
                .FirstOrDefaultAsync(c => c.UserId == userId);
            return customer?.Id;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting customer ID for user: {UserId}", userId);
            return null;
        }
    }

    public async Task<bool> IsVendorAsync()
    {
        var vendorId = await GetVendorIdAsync();
        return vendorId.HasValue;
    }

    public async Task<bool> IsCourierAsync()
    {
        var courierId = await GetCourierIdAsync();
        return courierId.HasValue;
    }
}

