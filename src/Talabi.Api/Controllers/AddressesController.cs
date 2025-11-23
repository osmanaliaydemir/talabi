using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class AddressesController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public AddressesController(TalabiDbContext context)
    {
        _context = context;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    [HttpGet]
    public async Task<ActionResult<IEnumerable<AddressDto>>> GetAddresses()
    {
        var userId = GetUserId();

        var addresses = await _context.UserAddresses
            .Where(a => a.UserId == userId)
            .OrderByDescending(a => a.IsDefault)
            .ThenByDescending(a => a.CreatedAt)
            .Select(a => new AddressDto
            {
                Id = a.Id,
                Title = a.Title,
                FullAddress = a.FullAddress,
                City = a.City,
                District = a.District,
                PostalCode = a.PostalCode,
                IsDefault = a.IsDefault,
                Latitude = a.Latitude,
                Longitude = a.Longitude
            })
            .ToListAsync();

        return Ok(addresses);
    }

    [HttpPost]
    public async Task<ActionResult<AddressDto>> CreateAddress(CreateAddressDto dto)
    {
        var userId = GetUserId();

        var address = new UserAddress
        {
            UserId = userId,
            Title = dto.Title,
            FullAddress = dto.FullAddress,
            City = dto.City,
            District = dto.District,
            PostalCode = dto.PostalCode,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            IsDefault = false
        };

        // If this is the first address, make it default
        var hasAddresses = await _context.UserAddresses.AnyAsync(a => a.UserId == userId);
        if (!hasAddresses)
        {
            address.IsDefault = true;
        }

        _context.UserAddresses.Add(address);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetAddresses), new AddressDto
        {
            Id = address.Id,
            Title = address.Title,
            FullAddress = address.FullAddress,
            City = address.City,
            District = address.District,
            PostalCode = address.PostalCode,
            IsDefault = address.IsDefault,
            Latitude = address.Latitude,
            Longitude = address.Longitude
        });
    }

    [HttpPut("{id}")]
    public async Task<ActionResult> UpdateAddress(int id, UpdateAddressDto dto)
    {
        var userId = GetUserId();

        var address = await _context.UserAddresses
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (address == null)
        {
            return NotFound();
        }

        address.Title = dto.Title;
        address.FullAddress = dto.FullAddress;
        address.City = dto.City;
        address.District = dto.District;
        address.PostalCode = dto.PostalCode;
        address.Latitude = dto.Latitude;
        address.Longitude = dto.Longitude;

        await _context.SaveChangesAsync();

        return Ok(new { Message = "Address updated successfully" });
    }

    [HttpPut("{id}/set-default")]
    public async Task<ActionResult> SetDefaultAddress(int id)
    {
        var userId = GetUserId();

        var address = await _context.UserAddresses
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (address == null)
        {
            return NotFound();
        }

        // Remove default from all other addresses
        var userAddresses = await _context.UserAddresses
            .Where(a => a.UserId == userId)
            .ToListAsync();

        foreach (var addr in userAddresses)
        {
            addr.IsDefault = addr.Id == id;
        }

        await _context.SaveChangesAsync();

        return Ok(new { Message = "Default address updated" });
    }

    [HttpDelete("{id}")]
    public async Task<ActionResult> DeleteAddress(int id)
    {
        var userId = GetUserId();

        var address = await _context.UserAddresses
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (address == null)
        {
            return NotFound();
        }

        _context.UserAddresses.Remove(address);
        await _context.SaveChangesAsync();

        // If deleted address was default, set another as default
        if (address.IsDefault)
        {
            var newDefault = await _context.UserAddresses
                .Where(a => a.UserId == userId)
                .FirstOrDefaultAsync();

            if (newDefault != null)
            {
                newDefault.IsDefault = true;
                await _context.SaveChangesAsync();
            }
        }

        return Ok(new { Message = "Address deleted successfully" });
    }
}
