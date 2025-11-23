using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/notifications")]
[ApiController]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public NotificationsController(TalabiDbContext context)
    {
        _context = context;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    [HttpGet("settings")]
    public async Task<ActionResult<NotificationSettingsDto>> GetSettings()
    {
        var userId = GetUserId();

        var settings = await _context.NotificationSettings
            .FirstOrDefaultAsync(ns => ns.UserId == userId);

        if (settings == null)
        {
            // Create default settings
            settings = new Core.Entities.NotificationSettings
            {
                UserId = userId,
                OrderUpdates = true,
                Promotions = true,
                NewProducts = true
            };

            _context.NotificationSettings.Add(settings);
            await _context.SaveChangesAsync();
        }

        return Ok(new NotificationSettingsDto
        {
            OrderUpdates = settings.OrderUpdates,
            Promotions = settings.Promotions,
            NewProducts = settings.NewProducts
        });
    }

    [HttpPut("settings")]
    public async Task<ActionResult> UpdateSettings(NotificationSettingsDto dto)
    {
        var userId = GetUserId();

        var settings = await _context.NotificationSettings
            .FirstOrDefaultAsync(ns => ns.UserId == userId);

        if (settings == null)
        {
            settings = new Core.Entities.NotificationSettings
            {
                UserId = userId
            };
            _context.NotificationSettings.Add(settings);
        }

        settings.OrderUpdates = dto.OrderUpdates;
        settings.Promotions = dto.Promotions;
        settings.NewProducts = dto.NewProducts;

        await _context.SaveChangesAsync();

        return Ok(new { Message = "Settings updated successfully" });
    }
}
