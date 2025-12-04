using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Bildirim işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class NotificationController : ControllerBase
{
    private readonly INotificationService _notificationService;

    /// <summary>
    /// NotificationController constructor
    /// </summary>
    public NotificationController(INotificationService notificationService)
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
    public async Task<ActionResult<ApiResponse<object>>> RegisterDevice([FromBody] RegisterDeviceRequest request)
    {
        // If user is authenticated, use their ID; otherwise use the token as a guest identifier
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? $"guest_{request.Token.GetHashCode()}";

        await _notificationService.RegisterDeviceTokenAsync(userId, request.Token, request.DeviceType);
        return Ok(new ApiResponse<object>(new { }, "Cihaz başarıyla kaydedildi"));
    }

    /// <summary>
    /// Test bildirimi gönderir (Sadece Admin)
    /// </summary>
    /// <param name="request">Bildirim bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    /// <summary>
    /// Test bildirimi gönderir (Sadece Admin)
    /// </summary>
    /// <param name="request">Bildirim bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("send-test")]
    [Authorize(Roles = "Admin")] // Only admin can send test notifications
    public async Task<ActionResult<ApiResponse<object>>> SendTestNotification([FromBody] SendNotificationRequest request)
    {
        await _notificationService.SendNotificationAsync(request.Token, request.Title, request.Body, request.Data ?? new { });
        return Ok(new ApiResponse<object>(new { }, "Bildirim gönderildi"));
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
