using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class NotificationControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<INotificationService> _mockNotificationService;
    private readonly NotificationController _controller;

    public NotificationControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockNotificationService = new Mock<INotificationService>();
        var logger = ControllerTestHelpers.CreateMockLogger<NotificationController>();

        _controller = new NotificationController(
            _mockUnitOfWork.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockNotificationService.Object
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

    [Fact]
    public async Task SendTestNotification_WhenCalled_SendsNotification()
    {
        // Arrange
        var request = new SendNotificationRequest
        {
            Token = "target-token",
            Title = "Test",
            Body = "Body",
            Data = new { foo = "bar" }
        };

        // Act
        var result = await _controller.SendTestNotification(request);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockNotificationService.Verify(x => x.SendNotificationAsync(
            request.Token,
            request.Title,
            request.Body,
            request.Data
        ), Times.Once);
    }
}
