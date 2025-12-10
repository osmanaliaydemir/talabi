using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Bildirim işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class NotificationController : BaseController
{
    private readonly INotificationService _notificationService;
    private const string ResourceName = "NotificationResources";

    /// <summary>
    /// NotificationController constructor
    /// </summary>
    public NotificationController(
        IUnitOfWork unitOfWork,
        ILogger<NotificationController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        INotificationService notificationService)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _notificationService = notificationService;
    }

    /// <summary>
    /// Cihaz token'ını kaydeder
    /// </summary>
    /// <param name="request">Cihaz kayıt bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("register-device")]
    [AllowAnonymous] // Allow device registration without authentication
    public async Task<ActionResult<ApiResponse<object>>> RegisterDevice(
        [FromBody] RegisterDeviceRequest request)
    {
        // If user is authenticated, use their ID; otherwise use the token as a guest identifier
        var userId = UserContext.GetUserId() ?? $"guest_{request.Token.GetHashCode()}";

        await _notificationService.RegisterDeviceTokenAsync(userId, request.Token, request.DeviceType);
        return Ok(new ApiResponse<object>(
            new { }, 
            LocalizationService.GetLocalizedString(ResourceName, "DeviceRegisteredSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Test bildirimi gönderir (Sadece Admin)
    /// </summary>
    /// <param name="request">Bildirim bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("send-test")]
    [Authorize(Roles = "Admin")] // Only admin can send test notifications
    public async Task<ActionResult<ApiResponse<object>>> SendTestNotification(
        [FromBody] SendNotificationRequest request)
    {
        await _notificationService.SendNotificationAsync(request.Token, request.Title, request.Body, request.Data ?? new { });
        return Ok(new ApiResponse<object>(
            new { }, 
            LocalizationService.GetLocalizedString(ResourceName, "NotificationSent", CurrentCulture)));
    }
}

/// <summary>
/// Cihaz kayıt isteği DTO'su
/// </summary>
public class RegisterDeviceRequest
{
    public string Token { get; set; } = string.Empty;
    public string DeviceType { get; set; } = string.Empty;
}

/// <summary>
/// Test bildirim isteği DTO'su
/// </summary>
public class SendNotificationRequest
{
    public string Token { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Body { get; set; } = string.Empty;
    public object? Data { get; set; }
}
