using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public class SettingsService : ISettingsService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IUserContextService _userContextService;
    private readonly ILogger<SettingsService> _logger;

    public SettingsService(
        IUnitOfWork unitOfWork,
        IUserContextService userContextService,
        ILogger<SettingsService> logger)
    {
        _unitOfWork = unitOfWork;
        _userContextService = userContextService;
        _logger = logger;
    }

    private async Task<Guid?> GetVendorIdAsync(CancellationToken ct)
    {
        var userId = _userContextService.GetUserId();
        if (string.IsNullOrEmpty(userId)) return null;

        var vendor = await _unitOfWork.Vendors.Query()
            .Select(v => new { v.Id, v.OwnerId })
            .FirstOrDefaultAsync(v => v.OwnerId == userId, ct);

        return vendor?.Id;
    }

    public async Task<VendorSettingsDto?> GetVendorSettingsAsync(CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return null;

            var vendor = await _unitOfWork.Vendors.Query()
                .FirstOrDefaultAsync(v => v.Id == vendorId.Value, ct);

            if (vendor == null) return null;

            return new VendorSettingsDto
            {
                MinimumOrderAmount = vendor.MinimumOrderAmount ?? 0,
                DeliveryFee = vendor.DeliveryFee ?? 0,
                EstimatedDeliveryTime = vendor.EstimatedDeliveryTime ?? 30,
                IsActive = vendor.IsActive,
                OpeningHours = vendor.OpeningHours
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting vendor settings");
            return null;
        }
    }

    public async Task<bool> UpdateVendorSettingsAsync(VendorSettingsDto dto, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return false;

            var vendor = await _unitOfWork.Vendors.Query()
                .FirstOrDefaultAsync(v => v.Id == vendorId.Value, ct);

            if (vendor == null) return false;

            vendor.MinimumOrderAmount = dto.MinimumOrderAmount;
            vendor.DeliveryFee = dto.DeliveryFee;
            vendor.EstimatedDeliveryTime = dto.EstimatedDeliveryTime;
            vendor.IsActive = dto.IsActive;
            vendor.OpeningHours = dto.OpeningHours;
            vendor.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Vendors.Update(vendor);
            await _unitOfWork.SaveChangesAsync(ct);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating vendor settings");
            return false;
        }
    }

    public async Task<SystemSettingsDto?> GetSystemSettingsAsync(CancellationToken ct = default)
    {
        try
        {
            var userId = _userContextService.GetUserId();
            if (string.IsNullOrEmpty(userId)) return null;

            var settings = await _unitOfWork.NotificationSettings.Query()
                .FirstOrDefaultAsync(s => s.UserId == userId, ct);

            if (settings == null)
            {
                // Return defaults if not found
                return new SystemSettingsDto
                {
                    OrderUpdates = true,
                    Promotions = true,
                    NewProducts = true
                };
            }

            return new SystemSettingsDto
            {
                OrderUpdates = settings.OrderUpdates,
                Promotions = settings.Promotions,
                NewProducts = settings.NewProducts
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting system settings");
            return null;
        }
    }

    public async Task<bool> UpdateSystemSettingsAsync(SystemSettingsDto dto, CancellationToken ct = default)
    {
        try
        {
            var userId = _userContextService.GetUserId();
            if (string.IsNullOrEmpty(userId)) return false;

            var settings = await _unitOfWork.NotificationSettings.Query()
                .FirstOrDefaultAsync(s => s.UserId == userId, ct);

            if (settings == null)
            {
                settings = new NotificationSettings
                {
                    UserId = userId,
                    OrderUpdates = dto.OrderUpdates,
                    Promotions = dto.Promotions,
                    NewProducts = dto.NewProducts
                };
                await _unitOfWork.NotificationSettings.AddAsync(settings);
            }
            else
            {
                settings.OrderUpdates = dto.OrderUpdates;
                settings.Promotions = dto.Promotions;
                settings.NewProducts = dto.NewProducts;
                settings.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.NotificationSettings.Update(settings);
            }

            await _unitOfWork.SaveChangesAsync(ct);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating system settings");
            return false;
        }
    }
}
