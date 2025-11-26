using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/vendor/profile")]
[ApiController]
[Authorize]
public class VendorProfileController : ControllerBase
{
    private readonly TalabiDbContext _context;
    private readonly ILogger<VendorProfileController> _logger;

    public VendorProfileController(
        TalabiDbContext context,
        ILogger<VendorProfileController> logger)
    {
        _context = context;
        _logger = logger;
    }

    private string? GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

    private async Task<Vendor?> GetCurrentVendorAsync(bool createIfMissing = false)
    {
        var userId = GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return null;
        }

        var vendor = await _context.Vendors
            .FirstOrDefaultAsync(v => v.OwnerId == userId);

        if (vendor == null && createIfMissing)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null)
            {
                return null;
            }

            vendor = new Vendor
            {
                OwnerId = user.Id,
                Name = user.FullName ?? user.Email ?? "Vendor",
                Address = string.Empty,
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };

            _context.Vendors.Add(vendor);
            await _context.SaveChangesAsync();

            _logger.LogInformation("Vendor profile created automatically for user {UserId}", userId);
        }

        return vendor;
    }

    // GET: api/vendor/profile
    [HttpGet]
    public async Task<ActionResult<VendorProfileDto>> GetProfile()
    {
        var vendor = await GetCurrentVendorAsync(createIfMissing: true);
        if (vendor == null)
            return NotFound("Vendor not found for current user");

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

        return Ok(profile);
    }

    // PUT: api/vendor/profile
    [HttpPut]
    public async Task<IActionResult> UpdateProfile(UpdateVendorProfileDto dto)
    {
        var vendor = await GetCurrentVendorAsync();
        if (vendor == null)
            return NotFound("Vendor not found for current user");

        // Update only provided fields
        if (dto.Name != null)
            vendor.Name = dto.Name;
        if (dto.ImageUrl != null)
            vendor.ImageUrl = dto.ImageUrl;
        if (dto.Address != null)
            vendor.Address = dto.Address;
        if (dto.City != null)
            vendor.City = dto.City;
        if (dto.Latitude.HasValue)
            vendor.Latitude = dto.Latitude.Value;
        if (dto.Longitude.HasValue)
            vendor.Longitude = dto.Longitude.Value;
        if (dto.PhoneNumber != null)
            vendor.PhoneNumber = dto.PhoneNumber;
        if (dto.Description != null)
            vendor.Description = dto.Description;

        vendor.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    // PUT: api/vendor/profile/image
    [HttpPut("image")]
    public async Task<IActionResult> UpdateImage([FromBody] UpdateImageDto dto)
    {
        var vendor = await GetCurrentVendorAsync();
        if (vendor == null)
            return NotFound("Vendor not found for current user");

        vendor.ImageUrl = dto.ImageUrl;
        vendor.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    // GET: api/vendor/profile/settings
    [HttpGet("settings")]
    public async Task<ActionResult<VendorSettingsDto>> GetSettings()
    {
        var vendor = await GetCurrentVendorAsync(createIfMissing: true);
        if (vendor == null)
            return NotFound("Vendor not found for current user");

        var settings = new VendorSettingsDto
        {
            MinimumOrderAmount = vendor.MinimumOrderAmount,
            DeliveryFee = vendor.DeliveryFee,
            EstimatedDeliveryTime = vendor.EstimatedDeliveryTime,
            IsActive = vendor.IsActive,
            OpeningHours = vendor.OpeningHours
        };

        return Ok(settings);
    }

    // PUT: api/vendor/profile/settings
    [HttpPut("settings")]
    public async Task<IActionResult> UpdateSettings(UpdateVendorSettingsDto dto)
    {
        var vendor = await GetCurrentVendorAsync();
        if (vendor == null)
            return NotFound("Vendor not found for current user");

        // Update only provided fields
        if (dto.MinimumOrderAmount.HasValue)
            vendor.MinimumOrderAmount = dto.MinimumOrderAmount;
        if (dto.DeliveryFee.HasValue)
            vendor.DeliveryFee = dto.DeliveryFee;
        if (dto.EstimatedDeliveryTime.HasValue)
            vendor.EstimatedDeliveryTime = dto.EstimatedDeliveryTime;
        if (dto.IsActive.HasValue)
            vendor.IsActive = dto.IsActive.Value;
        if (dto.OpeningHours != null)
            vendor.OpeningHours = dto.OpeningHours;

        vendor.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    // PUT: api/vendor/profile/settings/active
    [HttpPut("settings/active")]
    public async Task<IActionResult> ToggleActive([FromBody] ToggleActiveDto dto)
    {
        var vendor = await GetCurrentVendorAsync();
        if (vendor == null)
            return NotFound("Vendor not found for current user");

        vendor.IsActive = dto.IsActive;
        vendor.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return NoContent();
    }
}

public class UpdateImageDto
{
    public string? ImageUrl { get; set; }
}

public class ToggleActiveDto
{
    public bool IsActive { get; set; }
}
