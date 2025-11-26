using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/vendor/profile")]
[ApiController]
[Authorize]
public class VendorProfileController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public VendorProfileController(TalabiDbContext context)
    {
        _context = context;
    }

    private string? GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

    private async Task<int?> GetVendorIdAsync()
    {
        var userId = GetUserId();
        var vendor = await _context.Vendors
            .FirstOrDefaultAsync(v => v.OwnerId == userId);
        return vendor?.Id;
    }

    // GET: api/vendor/profile
    [HttpGet]
    public async Task<ActionResult<VendorProfileDto>> GetProfile()
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var vendor = await _context.Vendors
            .Where(v => v.Id == vendorId.Value)
            .Select(v => new VendorProfileDto
            {
                Id = v.Id,
                Name = v.Name,
                ImageUrl = v.ImageUrl,
                Address = v.Address,
                City = v.City,
                Latitude = v.Latitude,
                Longitude = v.Longitude,
                PhoneNumber = v.PhoneNumber,
                Description = v.Description,
                Rating = v.Rating,
                RatingCount = v.RatingCount
            })
            .FirstOrDefaultAsync();

        if (vendor == null)
            return NotFound("Vendor not found");

        return Ok(vendor);
    }

    // PUT: api/vendor/profile
    [HttpPut]
    public async Task<IActionResult> UpdateProfile(UpdateVendorProfileDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var vendor = await _context.Vendors
            .FirstOrDefaultAsync(v => v.Id == vendorId.Value);

        if (vendor == null)
            return NotFound("Vendor not found");

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
            vendor.Latitude = dto.Latitude;
        if (dto.Longitude.HasValue)
            vendor.Longitude = dto.Longitude;
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
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var vendor = await _context.Vendors
            .FirstOrDefaultAsync(v => v.Id == vendorId.Value);

        if (vendor == null)
            return NotFound("Vendor not found");

        vendor.ImageUrl = dto.ImageUrl;
        vendor.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    // GET: api/vendor/profile/settings
    [HttpGet("settings")]
    public async Task<ActionResult<VendorSettingsDto>> GetSettings()
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var vendor = await _context.Vendors
            .Where(v => v.Id == vendorId.Value)
            .Select(v => new VendorSettingsDto
            {
                MinimumOrderAmount = v.MinimumOrderAmount,
                DeliveryFee = v.DeliveryFee,
                EstimatedDeliveryTime = v.EstimatedDeliveryTime,
                IsActive = v.IsActive,
                OpeningHours = v.OpeningHours
            })
            .FirstOrDefaultAsync();

        if (vendor == null)
            return NotFound("Vendor not found");

        return Ok(vendor);
    }

    // PUT: api/vendor/profile/settings
    [HttpPut("settings")]
    public async Task<IActionResult> UpdateSettings(UpdateVendorSettingsDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var vendor = await _context.Vendors
            .FirstOrDefaultAsync(v => v.Id == vendorId.Value);

        if (vendor == null)
            return NotFound("Vendor not found");

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
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
            return NotFound("Vendor not found for current user");

        var vendor = await _context.Vendors
            .FirstOrDefaultAsync(v => v.Id == vendorId.Value);

        if (vendor == null)
            return NotFound("Vendor not found");

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
