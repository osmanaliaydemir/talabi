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
public class CourierController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public CourierController(TalabiDbContext context)
    {
        _context = context;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    // Update courier's current location
    [HttpPut("{courierId}/location")]
    public async Task<ActionResult> UpdateLocation(int courierId, UpdateCourierLocationDto dto)
    {
        var courier = await _context.Couriers.FindAsync(courierId);
        if (courier == null)
        {
            return NotFound("Courier not found");
        }

        // Verify the courier belongs to the current user
        if (courier.UserId != GetUserId())
        {
            return Forbid();
        }

        courier.CurrentLatitude = dto.Latitude;
        courier.CurrentLongitude = dto.Longitude;
        courier.LastLocationUpdate = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return Ok(new { Message = "Location updated" });
    }

    // Get courier's current location
    [HttpGet("{courierId}/location")]
    public async Task<ActionResult<CourierLocationDto>> GetLocation(int courierId)
    {
        var courier = await _context.Couriers.FindAsync(courierId);
        if (courier == null)
        {
            return NotFound("Courier not found");
        }

        if (!courier.CurrentLatitude.HasValue || !courier.CurrentLongitude.HasValue)
        {
            return NotFound("Courier location not available");
        }

        return Ok(new CourierLocationDto
        {
            CourierId = courier.Id,
            CourierName = courier.Name,
            Latitude = courier.CurrentLatitude.Value,
            Longitude = courier.CurrentLongitude.Value,
            LastUpdate = courier.LastLocationUpdate ?? DateTime.UtcNow
        });
    }

    // Get all active couriers with their locations
    [HttpGet("active")]
    public async Task<ActionResult<List<CourierLocationDto>>> GetActiveCouriers()
    {
        var couriers = await _context.Couriers
            .Where(c => c.IsActive && 
                       c.CurrentLatitude.HasValue && 
                       c.CurrentLongitude.HasValue)
            .Select(c => new CourierLocationDto
            {
                CourierId = c.Id,
                CourierName = c.Name,
                Latitude = c.CurrentLatitude!.Value,
                Longitude = c.CurrentLongitude!.Value,
                LastUpdate = c.LastLocationUpdate ?? DateTime.UtcNow
            })
            .ToListAsync();

        return Ok(couriers);
    }
}

