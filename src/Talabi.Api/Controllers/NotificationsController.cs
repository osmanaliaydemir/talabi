using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Bildirim ayarları için controller
/// </summary>
[Route("api/notifications")]
[ApiController]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    /// <summary>
    /// NotificationsController constructor
    /// </summary>
    public NotificationsController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    /// <summary>
    /// Kullanıcının bildirim ayarlarını getirir
    /// </summary>
    /// <returns>Bildirim ayarları</returns>
    [HttpGet("settings")]
    public async Task<ActionResult<ApiResponse<NotificationSettingsDto>>> GetSettings()
    {
        var userId = GetUserId();

        var settings = await _unitOfWork.NotificationSettings.Query()
            .FirstOrDefaultAsync(ns => ns.UserId == userId);

        if (settings == null)
        {
            // Create default settings
            settings = new NotificationSettings
            {
                UserId = userId,
                OrderUpdates = true,
                Promotions = true,
                NewProducts = true
            };

            await _unitOfWork.NotificationSettings.AddAsync(settings);
            await _unitOfWork.SaveChangesAsync();
        }

        var dto = new NotificationSettingsDto
        {
            OrderUpdates = settings.OrderUpdates,
            Promotions = settings.Promotions,
            NewProducts = settings.NewProducts
        };

        return Ok(new ApiResponse<NotificationSettingsDto>(dto, "Bildirim ayarları başarıyla getirildi"));
    }

    /// <summary>
    /// Kullanıcının bildirim ayarlarını günceller
    /// </summary>
    /// <param name="dto">Güncellenecek bildirim ayarları</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("settings")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateSettings(NotificationSettingsDto dto)
    {
        var userId = GetUserId();

        var settings = await _unitOfWork.NotificationSettings.Query()
            .FirstOrDefaultAsync(ns => ns.UserId == userId);

        if (settings == null)
        {
            settings = new NotificationSettings
            {
                UserId = userId
            };
            await _unitOfWork.NotificationSettings.AddAsync(settings);
        }

        settings.OrderUpdates = dto.OrderUpdates;
        settings.Promotions = dto.Promotions;
        settings.NewProducts = dto.NewProducts;

        _unitOfWork.NotificationSettings.Update(settings);
        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Bildirim ayarları başarıyla güncellendi"));
    }
}
