using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
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
public class NotificationsController(
    IUnitOfWork unitOfWork,
    ILogger<NotificationsController> logger,
    ILocalizationService localizationService,
    IUserContextService userContext)
    : BaseController(unitOfWork, logger, localizationService, userContext)
{
    private const string ResourceName = "NotificationResources";

    /// <summary>
    /// Kullanıcının bildirim ayarlarını getirir
    /// </summary>
    /// <returns>Bildirim ayarları</returns>
    [HttpGet("settings")]
    public async Task<ActionResult<ApiResponse<NotificationSettingsDto>>> GetSettings()
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var settings = await UnitOfWork.NotificationSettings.Query()
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

            await UnitOfWork.NotificationSettings.AddAsync(settings);
            await UnitOfWork.SaveChangesAsync();
        }

        var dto = new NotificationSettingsDto
        {
            OrderUpdates = settings.OrderUpdates,
            Promotions = settings.Promotions,
            NewProducts = settings.NewProducts
        };

        return Ok(new ApiResponse<NotificationSettingsDto>(
            dto,
            LocalizationService.GetLocalizedString(ResourceName, "SettingsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kullanıcının bildirim ayarlarını günceller
    /// </summary>
    /// <param name="dto">Güncellenecek bildirim ayarları</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("settings")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateSettings(NotificationSettingsDto dto)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var settings = await UnitOfWork.NotificationSettings.Query()
            .FirstOrDefaultAsync(ns => ns.UserId == userId);

        if (settings == null)
        {
            settings = new NotificationSettings
            {
                UserId = userId
            };
            await UnitOfWork.NotificationSettings.AddAsync(settings);
        }

        settings.OrderUpdates = dto.OrderUpdates;
        settings.Promotions = dto.Promotions;
        settings.NewProducts = dto.NewProducts;

        UnitOfWork.NotificationSettings.Update(settings);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(
            new { },
            LocalizationService.GetLocalizedString(ResourceName, "SettingsUpdatedSuccessfully", CurrentCulture)));
    }
}
