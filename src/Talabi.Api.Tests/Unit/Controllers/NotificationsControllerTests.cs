using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using MockQueryable;
using MockQueryable.Moq;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class NotificationsControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly NotificationsController _controller;

    public NotificationsControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        var logger = ControllerTestHelpers.CreateMockLogger<NotificationsController>();

        _controller = new NotificationsController(
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
    public async Task GetSettings_WhenExist_ReturnsSettings()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var settings = new NotificationSettings
        {
            UserId = userId,
            OrderUpdates = true,
            Promotions = false,
            NewProducts = true
        };
        var settingsList = new List<NotificationSettings> { settings };

        var mockRepo = new Mock<IRepository<NotificationSettings>>();
        mockRepo.Setup(x => x.Query()).Returns(settingsList.BuildMock());
        _mockUnitOfWork.Setup(x => x.NotificationSettings).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetSettings();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<NotificationSettingsDto>>().Subject;

        apiResponse.Data.OrderUpdates.Should().BeTrue();
        apiResponse.Data.Promotions.Should().BeFalse();
        apiResponse.Data.NewProducts.Should().BeTrue();
    }

    [Fact]
    public async Task GetSettings_WhenNotExist_CreatesDefault()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var settingsList = new List<NotificationSettings>();

        var mockRepo = new Mock<IRepository<NotificationSettings>>();
        mockRepo.Setup(x => x.Query()).Returns(settingsList.BuildMock());
        _mockUnitOfWork.Setup(x => x.NotificationSettings).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetSettings();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<NotificationSettingsDto>>().Subject;

        // Default: true, true, true
        apiResponse.Data.OrderUpdates.Should().BeTrue();

        _mockUnitOfWork.Verify(x => x.NotificationSettings.AddAsync(It.Is<NotificationSettings>(s => s.UserId == userId), It.IsAny<CancellationToken>()), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateSettings_WhenExist_UpdatesSettings()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var settings = new NotificationSettings { UserId = userId, OrderUpdates = true };
        var settingsList = new List<NotificationSettings> { settings };

        var mockRepo = new Mock<IRepository<NotificationSettings>>();
        mockRepo.Setup(x => x.Query()).Returns(settingsList.BuildMock());
        _mockUnitOfWork.Setup(x => x.NotificationSettings).Returns(mockRepo.Object);

        var dto = new NotificationSettingsDto
        {
            OrderUpdates = false, // Changed
            Promotions = true,
            NewProducts = false
        };

        // Act
        var result = await _controller.UpdateSettings(dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        settings.OrderUpdates.Should().BeFalse();
        settings.Promotions.Should().BeTrue();

        _mockUnitOfWork.Verify(x => x.NotificationSettings.Update(settings), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }
}
