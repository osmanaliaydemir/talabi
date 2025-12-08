using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Satıcı profil işlemleri için controller
/// </summary>
[Route("api/vendor/profile")]
[ApiController]
[Authorize]
public class VendorProfileController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    /// <summary>
    /// VendorProfileController constructor
    /// </summary>
    public VendorProfileController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier) ?? throw new UnauthorizedAccessException();

    private async Task<Vendor?> GetCurrentVendorAsync()
    {
        var userId = GetUserId();
        var vendor = await _unitOfWork.Vendors.Query()
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
            return NotFound(new ApiResponse<VendorProfileDto>("Satıcı profili bulunamadı", "VENDOR_PROFILE_NOT_FOUND"));
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
            RatingCount = vendor.RatingCount
        };

        return Ok(new ApiResponse<VendorProfileDto>(profile, "Satıcı profili başarıyla getirildi"));
    }

    /// <summary>
    /// Satıcı profil bilgilerini günceller
    /// </summary>
    /// <param name="dto">Güncellenecek profil bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut]
    public async Task<ActionResult<ApiResponse<object>>> UpdateProfile([FromBody] UpdateVendorProfileDto dto)
    {
        try
        {
            if (dto == null)
            {
                return BadRequest(new ApiResponse<object>("Geçersiz istek", "INVALID_REQUEST"));
            }

            var vendor = await GetCurrentVendorAsync();
            if (vendor == null)
            {
                return NotFound(new ApiResponse<object>("Satıcı profili bulunamadı", "VENDOR_PROFILE_NOT_FOUND"));
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

            vendor.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Vendors.Update(vendor);
            await _unitOfWork.SaveChangesAsync();

            return Ok(new ApiResponse<object>(new { }, "Satıcı profili başarıyla güncellendi"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                $"Satıcı profili güncellenirken bir hata oluştu: {ex.Message}",
                "INTERNAL_SERVER_ERROR"
            ));
        }
    }

    /// <summary>
    /// Satıcı profil resmini günceller
    /// </summary>
    /// <param name="imageUrl">Yeni resim URL'i</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("image")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateImage([FromBody] UpdateVendorImageDto dto)
    {
        try
        {
            if (dto == null || string.IsNullOrEmpty(dto.ImageUrl))
            {
                return BadRequest(new ApiResponse<object>("Geçersiz istek", "INVALID_REQUEST"));
            }

            var vendor = await GetCurrentVendorAsync();
            if (vendor == null)
            {
                return NotFound(new ApiResponse<object>("Satıcı profili bulunamadı", "VENDOR_PROFILE_NOT_FOUND"));
            }

            vendor.ImageUrl = dto.ImageUrl;
            vendor.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Vendors.Update(vendor);
            await _unitOfWork.SaveChangesAsync();

            return Ok(new ApiResponse<object>(new { }, "Satıcı profil resmi başarıyla güncellendi"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                $"Satıcı profil resmi güncellenirken bir hata oluştu: {ex.Message}",
                "INTERNAL_SERVER_ERROR"
            ));
        }
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
            return NotFound(new ApiResponse<VendorSettingsDto>("Satıcı profili bulunamadı", "VENDOR_PROFILE_NOT_FOUND"));
        }

        var settings = new VendorSettingsDto
        {
            MinimumOrderAmount = vendor.MinimumOrderAmount,
            DeliveryFee = vendor.DeliveryFee,
            EstimatedDeliveryTime = vendor.EstimatedDeliveryTime,
            IsActive = vendor.IsActive,
            OpeningHours = vendor.OpeningHours
        };

        return Ok(new ApiResponse<VendorSettingsDto>(settings, "Satıcı ayarları başarıyla getirildi"));
    }

    /// <summary>
    /// Satıcı ayarlarını günceller
    /// </summary>
    /// <param name="dto">Güncellenecek ayar bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("settings")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateSettings([FromBody] UpdateVendorSettingsDto dto)
    {
        try
        {
            if (dto == null)
            {
                return BadRequest(new ApiResponse<object>("Geçersiz istek", "INVALID_REQUEST"));
            }

            var vendor = await GetCurrentVendorAsync();
            if (vendor == null)
            {
                return NotFound(new ApiResponse<object>("Satıcı profili bulunamadı", "VENDOR_PROFILE_NOT_FOUND"));
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

            _unitOfWork.Vendors.Update(vendor);
            await _unitOfWork.SaveChangesAsync();

            return Ok(new ApiResponse<object>(new { }, "Satıcı ayarları başarıyla güncellendi"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                $"Satıcı ayarları güncellenirken bir hata oluştu: {ex.Message}",
                "INTERNAL_SERVER_ERROR"
            ));
        }
    }

    /// <summary>
    /// Satıcı aktif/pasif durumunu günceller
    /// </summary>
    /// <param name="isActive">Aktif durumu</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("settings/active")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateActiveStatus([FromBody] UpdateVendorActiveStatusDto dto)
    {
        try
        {
            if (dto == null)
            {
                return BadRequest(new ApiResponse<object>("Geçersiz istek", "INVALID_REQUEST"));
            }

            var vendor = await GetCurrentVendorAsync();
            if (vendor == null)
            {
                return NotFound(new ApiResponse<object>("Satıcı profili bulunamadı", "VENDOR_PROFILE_NOT_FOUND"));
            }

            vendor.IsActive = dto.IsActive;
            vendor.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Vendors.Update(vendor);
            await _unitOfWork.SaveChangesAsync();

            return Ok(new ApiResponse<object>(new { }, "Satıcı aktif durumu başarıyla güncellendi"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                $"Satıcı aktif durumu güncellenirken bir hata oluştu: {ex.Message}",
                "INTERNAL_SERVER_ERROR"
            ));
        }
    }
}

