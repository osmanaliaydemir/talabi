using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Satıcı profil işlemleri için controller
/// </summary>
[Route("api/vendor/profile")]
[ApiController]
[Authorize]
public class VendorProfileController : BaseController
{
    private const string ResourceName = "VendorProfileResources";

    /// <summary>
    /// VendorProfileController constructor
    /// </summary>
    public VendorProfileController(
        IUnitOfWork unitOfWork,
        ILogger<VendorProfileController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
    }

    private async Task<Vendor?> GetCurrentVendorAsync()
    {
        var userId = UserContext.GetUserId();
        if (userId == null) return null;

        var vendor = await UnitOfWork.Vendors.Query()
            .Include(v => v.WorkingHours)
            .FirstOrDefaultAsync(v => v.OwnerId == userId);
        return vendor;
    }

    /// <summary>
    /// Satıcı profil bilgilerini getirir
    /// </summary>
    /// <returns>Satıcı profil bilgileri</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<VendorProfileDto>>> GetProfile()
    {
        var vendor = await GetCurrentVendorAsync();
        if (vendor == null)
        {
            return NotFound(new ApiResponse<VendorProfileDto>(LocalizationService.GetLocalizedString(ResourceName, "VendorProfileNotFound", CurrentCulture), "VENDOR_PROFILE_NOT_FOUND"));
        }

        var profile = new VendorProfileDto
        {
            Id = vendor.Id,
            Name = vendor.Name,
            ImageUrl = vendor.ImageUrl,
            Address = vendor.Address,
            City = vendor.City,
            Latitude = vendor.Latitude,
            Longitude = vendor.Longitude,
            PhoneNumber = vendor.PhoneNumber,
            Description = vendor.Description,
            Rating = vendor.Rating,
            RatingCount = vendor.RatingCount,
            BusyStatus = vendor.BusyStatus,
            WorkingHours = vendor.WorkingHours.Select(wh => new WorkingHourDto
            {
                DayOfWeek = (int)wh.DayOfWeek,
                DayName = LocalizationService.GetLocalizedString("CommonResources", wh.DayOfWeek.ToString(), CurrentCulture),
                StartTime = wh.StartTime,
                EndTime = wh.EndTime,
                IsClosed = wh.IsClosed
            }).ToList()
        };

        return Ok(new ApiResponse<VendorProfileDto>(profile, LocalizationService.GetLocalizedString(ResourceName, "VendorProfileRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Satıcı profil bilgilerini günceller
    /// </summary>
    /// <param name="dto">Güncellenecek profil bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut]
    public async Task<ActionResult<ApiResponse<object>>> UpdateProfile([FromBody] UpdateVendorProfileDto dto)
    {
        if (dto == null)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture), "INVALID_REQUEST"));
        }

        var vendor = await GetCurrentVendorAsync();
        if (vendor == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "VendorProfileNotFound", CurrentCulture), "VENDOR_PROFILE_NOT_FOUND"));
        }

        // Update fields if provided
        if (!string.IsNullOrEmpty(dto.Name))
        {
            vendor.Name = dto.Name;
        }

        if (dto.ImageUrl != null)
        {
            vendor.ImageUrl = dto.ImageUrl;
        }

        if (!string.IsNullOrEmpty(dto.Address))
        {
            vendor.Address = dto.Address;
        }

        if (dto.City != null)
        {
            vendor.City = dto.City;
        }

        if (dto.Latitude.HasValue)
        {
            vendor.Latitude = dto.Latitude.Value;
        }

        if (dto.Longitude.HasValue)
        {
            vendor.Longitude = dto.Longitude.Value;
        }

        if (dto.PhoneNumber != null)
        {
            vendor.PhoneNumber = dto.PhoneNumber;
        }

        if (dto.Description != null)
        {
            vendor.Description = dto.Description;
        }

        int maxRetries = 3;
        for (int i = 0; i < maxRetries; i++)
        {
            try
            {
                if (i > 0)
                {
                    // Reload vendor for retry
                    var userId = UserContext.GetUserId();
                    if (userId == null) return Unauthorized(new ApiResponse<object>(LocalizationService.GetLocalizedString("ErrorResources", "Unauthorized", CurrentCulture), "UNAUTHORIZED"));

                    vendor = await UnitOfWork.Vendors.Query()
                       .Include(v => v.WorkingHours)
                       .FirstOrDefaultAsync(v => v.OwnerId == userId);

                    if (vendor == null) return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "VendorProfileNotFound", CurrentCulture), "VENDOR_PROFILE_NOT_FOUND"));
                }

                if (dto.WorkingHours != null)
                {
                    var existingHours = vendor.WorkingHours.ToList();
                    var incomingDays = dto.WorkingHours.Select(x => x.DayOfWeek).ToHashSet();

                    // 1. Update existing and Identify to Remove
                    foreach (var existing in existingHours)
                    {
                        var incoming = dto.WorkingHours.FirstOrDefault(x => x.DayOfWeek == (int)existing.DayOfWeek);
                        if (incoming != null)
                        {
                            // Update
                            existing.StartTime = incoming.StartTime;
                            existing.EndTime = incoming.EndTime;
                            existing.IsClosed = incoming.IsClosed;
                            // Ensure nulls if closed logic is consistent
                            if (existing.IsClosed)
                            {
                                existing.StartTime = null;
                                existing.EndTime = null;
                            }
                        }
                        else
                        {
                            // Remove if not in incoming
                            UnitOfWork.VendorWorkingHours.Remove(existing);
                        }
                    }

                    // 2. Add new
                    foreach (var incoming in dto.WorkingHours)
                    {
                        if (!existingHours.Any(x => (int)x.DayOfWeek == incoming.DayOfWeek))
                        {
                            vendor.WorkingHours.Add(new VendorWorkingHour
                            {
                                VendorId = vendor.Id,
                                DayOfWeek = (DayOfWeek)incoming.DayOfWeek,
                                StartTime = incoming.IsClosed ? null : incoming.StartTime,
                                EndTime = incoming.IsClosed ? null : incoming.EndTime,
                                IsClosed = incoming.IsClosed
                            });
                        }
                    }
                }

                vendor.UpdatedAt = DateTime.UtcNow;
                UnitOfWork.Vendors.Update(vendor);
                await UnitOfWork.SaveChangesAsync();
                break; // Success
            }
            catch (DbUpdateConcurrencyException)
            {
                if (i == maxRetries - 1) throw;
                await Task.Delay(100);
            }
        }

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "VendorProfileUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Satıcı profil resmini günceller
    /// </summary>
    /// <param name="dto">Yeni resim bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("image")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateImage([FromBody] UpdateVendorImageDto dto)
    {
        if (dto == null || string.IsNullOrEmpty(dto.ImageUrl))
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture), "INVALID_REQUEST"));
        }

        var vendor = await GetCurrentVendorAsync();
        if (vendor == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "VendorProfileNotFound", CurrentCulture), "VENDOR_PROFILE_NOT_FOUND"));
        }

        vendor.ImageUrl = dto.ImageUrl;
        vendor.UpdatedAt = DateTime.UtcNow;

        UnitOfWork.Vendors.Update(vendor);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "VendorImageUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Satıcı ayarlarını getirir
    /// </summary>
    /// <returns>Satıcı ayarları</returns>
    [HttpGet("settings")]
    public async Task<ActionResult<ApiResponse<VendorSettingsDto>>> GetSettings()
    {
        var vendor = await GetCurrentVendorAsync();
        if (vendor == null)
        {
            return NotFound(new ApiResponse<VendorSettingsDto>(LocalizationService.GetLocalizedString(ResourceName, "VendorProfileNotFound", CurrentCulture), "VENDOR_PROFILE_NOT_FOUND"));
        }

        var settings = new VendorSettingsDto
        {
            MinimumOrderAmount = vendor.MinimumOrderAmount,
            DeliveryFee = vendor.DeliveryFee,
            EstimatedDeliveryTime = vendor.EstimatedDeliveryTime,
            IsActive = vendor.IsActive,
            OpeningHours = vendor.OpeningHours
        };

        return Ok(new ApiResponse<VendorSettingsDto>(settings, LocalizationService.GetLocalizedString(ResourceName, "VendorSettingsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Satıcı ayarlarını günceller
    /// </summary>
    /// <param name="dto">Güncellenecek ayar bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("settings")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateSettings([FromBody] UpdateVendorSettingsDto dto)
    {
        if (dto == null)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture), "INVALID_REQUEST"));
        }

        var vendor = await GetCurrentVendorAsync();
        if (vendor == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "VendorProfileNotFound", CurrentCulture), "VENDOR_PROFILE_NOT_FOUND"));
        }

        // Update fields if provided
        if (dto.MinimumOrderAmount.HasValue)
        {
            vendor.MinimumOrderAmount = dto.MinimumOrderAmount.Value;
        }

        if (dto.DeliveryFee.HasValue)
        {
            vendor.DeliveryFee = dto.DeliveryFee.Value;
        }

        if (dto.EstimatedDeliveryTime.HasValue)
        {
            vendor.EstimatedDeliveryTime = dto.EstimatedDeliveryTime.Value;
        }

        if (dto.IsActive.HasValue)
        {
            vendor.IsActive = dto.IsActive.Value;
        }

        if (dto.OpeningHours != null)
        {
            vendor.OpeningHours = dto.OpeningHours;
        }

        vendor.UpdatedAt = DateTime.UtcNow;

        UnitOfWork.Vendors.Update(vendor);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "VendorSettingsUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Satıcı aktif/pasif durumunu günceller
    /// </summary>
    /// <param name="dto">Aktif durumu</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("settings/active")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateActiveStatus([FromBody] UpdateVendorActiveStatusDto dto)
    {
        if (dto == null)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture), "INVALID_REQUEST"));
        }

        var vendor = await GetCurrentVendorAsync();
        if (vendor == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "VendorProfileNotFound", CurrentCulture), "VENDOR_PROFILE_NOT_FOUND"));
        }

        vendor.IsActive = dto.IsActive;
        vendor.UpdatedAt = DateTime.UtcNow;

        UnitOfWork.Vendors.Update(vendor);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "VendorActiveStatusUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Satıcı yoğunluk durumunu günceller
    /// </summary>
    /// <param name="dto">Yoğunluk durumu</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("settings/status")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateBusyStatus([FromBody] UpdateVendorBusyStatusDto dto)
    {
        if (dto == null)
        {
            return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture), "INVALID_REQUEST"));
        }

        var vendor = await GetCurrentVendorAsync();
        if (vendor == null)
        {
            return NotFound(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "VendorProfileNotFound", CurrentCulture), "VENDOR_PROFILE_NOT_FOUND"));
        }

        vendor.BusyStatus = dto.BusyStatus;
        vendor.UpdatedAt = DateTime.UtcNow;

        UnitOfWork.Vendors.Update(vendor);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "VendorBusyStatusUpdatedSuccessfully", CurrentCulture)));
    }
}

