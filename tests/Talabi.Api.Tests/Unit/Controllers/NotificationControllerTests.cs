using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.Interfaces;
using Talabi.Core.Services;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class NotificationControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<INotificationService> _mockNotificationService;
    private readonly AuthController _controller;

    public NotificationControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockNotificationService = new Mock<INotificationService>();
        var logger = ControllerTestHelpers.CreateMockLogger<AuthController>();

        // AuthController has many dependencies; this test only targets RegisterDevice.
        var authService = new Mock<IAuthService>();
        var memoryCache = new Mock<Microsoft.Extensions.Caching.Memory.IMemoryCache>();
        var emailSender = new Mock<Talabi.Core.Services.IEmailSender>();
        var tokenVerifier = new Mock<IExternalAuthTokenVerifier>();
        var verificationSecurity = new Mock<IVerificationCodeSecurityService>();
        var userStore = new Mock<Microsoft.AspNetCore.Identity.IUserStore<Talabi.Core.Entities.AppUser>>();
        var userManager = new Mock<Microsoft.AspNetCore.Identity.UserManager<Talabi.Core.Entities.AppUser>>(
            userStore.Object, null!, null!, null!, null!, null!, null!, null!, null!);

        _controller = new AuthController(
            authService.Object,
            userManager.Object,
            memoryCache.Object,
            emailSender.Object,
            tokenVerifier.Object,
            verificationSecurity.Object,
            _mockNotificationService.Object,
            _mockUnitOfWork.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task RegisterDevice_WhenAuthenticated_RegistersTokenWithUserId()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        var request = new RegisterDeviceRequest { Token = "device-token", DeviceType = "android" };

        // Act
        var result = await _controller.RegisterDevice(request);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockNotificationService.Verify(x => x.RegisterDeviceTokenAsync(
            userId,
            request.Token,
            request.DeviceType
        ), Times.Once);
    }

    [Fact]
    public async Task RegisterDevice_WhenAnonymous_RegistersTokenWithGuestId()
    {
        // Arrange
        _mockUserContextService.Setup(x => x.GetUserId()).Returns((string?)null);
        var request = new RegisterDeviceRequest { Token = "device-token-abc", DeviceType = "ios" };
        var expectedGuestId = $"guest_{request.Token.GetHashCode()}";

        // Act
        var result = await _controller.RegisterDevice(request);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockNotificationService.Verify(x => x.RegisterDeviceTokenAsync(
            expectedGuestId,
            request.Token,
            request.DeviceType
        ), Times.Once);
    }

    // Note: "SendTestNotification" endpoint no longer exists in the API layer.
}
