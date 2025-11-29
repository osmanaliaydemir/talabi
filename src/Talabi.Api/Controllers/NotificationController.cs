using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class NotificationController : ControllerBase
    {
        private readonly INotificationService _notificationService;

        public NotificationController(INotificationService notificationService)
        {
            _notificationService = notificationService;
        }

        [HttpPost("register-device")]
        [AllowAnonymous] // Allow device registration without authentication
        public async Task<IActionResult> RegisterDevice([FromBody] RegisterDeviceRequest request)
        {
            // If user is authenticated, use their ID; otherwise use the token as a guest identifier
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? $"guest_{request.Token.GetHashCode()}";

            await _notificationService.RegisterDeviceTokenAsync(userId, request.Token, request.DeviceType);
            return Ok(new { message = "Device registered successfully" });
        }

        [HttpPost("send-test")]
        [Authorize(Roles = "Admin")] // Only admin can send test notifications
        public async Task<IActionResult> SendTestNotification([FromBody] SendNotificationRequest request)
        {
            await _notificationService.SendNotificationAsync(request.Token, request.Title, request.Body, request.Data);
            return Ok(new { message = "Notification sent" });
        }
    }

    public class RegisterDeviceRequest
    {
        public string Token { get; set; }
        public string DeviceType { get; set; }
    }

    public class SendNotificationRequest
    {
        public string Token { get; set; }
        public string Title { get; set; }
        public string Body { get; set; }
        public object Data { get; set; }
    }
}
