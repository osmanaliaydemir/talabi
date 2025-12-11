using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using MockQueryable.Moq;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class VendorNotificationsControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<UserManager<AppUser>> _mockUserManager;
    private readonly VendorNotificationsController _controller;

    public VendorNotificationsControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        var logger = ControllerTestHelpers.CreateMockLogger<VendorNotificationsController>();

        var store = new Mock<IUserStore<AppUser>>();
        _mockUserManager = new Mock<UserManager<AppUser>>(store.Object, null!, null!, null!, null!, null!, null!, null!, null!);

        _controller = new VendorNotificationsController(
            _mockUnitOfWork.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockUserManager.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    private void SetupVendor(string userId, Guid vendorId)
    {
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var vendor = new Vendor { Id = vendorId, OwnerId = userId };
        var vendors = new List<Vendor> { vendor };
        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.Query()).Returns(vendors.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);
    }

    [Fact]
    public async Task GetNotifications_WhenVendorNotFound_ReturnsEmpty()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Vendor>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetNotifications(1, 20);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<VendorNotificationResponseDto>>().Subject;

        apiResponse.Data!.Items.Should().BeEmpty();
        apiResponse.Data!.UnreadCount.Should().Be(0);
    }

    [Fact]
    public async Task GetNotifications_WhenCalled_ReturnsNotifications()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var notifications = new List<VendorNotification>
        {
            new VendorNotification { Id = Guid.NewGuid(), VendorId = vendorId, Title = "Test", Message = "Msg", IsRead = false, CreatedAt = DateTime.UtcNow }
        };

        var mockRepo = new Mock<IRepository<VendorNotification>>();
        mockRepo.Setup(x => x.Query()).Returns(notifications.AsQueryable().BuildMock());
        // For EnsureWelcomeNotificationAsync check
        mockRepo.Setup(x => x.AddAsync(It.IsAny<VendorNotification>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((VendorNotification n, CancellationToken c) => n);

        _mockUnitOfWork.Setup(x => x.VendorNotifications).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetNotifications(1, 20);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<VendorNotificationResponseDto>>().Subject;

        apiResponse.Data!.Items.Should().HaveCount(1);
        apiResponse.Data!.UnreadCount.Should().Be(1);
    }

    [Fact]
    public async Task MarkAsRead_WhenVendorNotFound_ReturnsNotFound()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Vendor>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);

        // Act
        var result = await _controller.MarkAsRead(Guid.NewGuid());

        // Assert
        result.Result.Should().BeOfType<NotFoundObjectResult>();
    }

    [Fact]
    public async Task MarkAsRead_WhenNotificationNotFound_ReturnsNotFound()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);
        var notifId = Guid.NewGuid();

        var mockRepo = new Mock<IRepository<VendorNotification>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<VendorNotification>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.VendorNotifications).Returns(mockRepo.Object);

        // Act
        var result = await _controller.MarkAsRead(notifId);

        // Assert
        var notFoundResult = result.Result.Should().BeOfType<NotFoundObjectResult>().Subject;
        var apiResponse = notFoundResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.ErrorCode.Should().Be("NOTIFICATION_NOT_FOUND");
    }

    [Fact]
    public async Task MarkAsRead_WhenFound_MarksAsRead()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);
        var notifId = Guid.NewGuid();

        var notification = new VendorNotification { Id = notifId, VendorId = vendorId, IsRead = false };
        var notifications = new List<VendorNotification> { notification };

        var mockRepo = new Mock<IRepository<VendorNotification>>();
        mockRepo.Setup(x => x.Query()).Returns(notifications.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.VendorNotifications).Returns(mockRepo.Object);

        // Act
        var result = await _controller.MarkAsRead(notifId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        notification.IsRead.Should().BeTrue();
        _mockUnitOfWork.Verify(x => x.VendorNotifications.Update(notification), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task MarkAllAsRead_WhenCalled_MarksAllAsRead()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var notifications = new List<VendorNotification>
        {
            new VendorNotification { Id = Guid.NewGuid(), VendorId = vendorId, IsRead = false },
            new VendorNotification { Id = Guid.NewGuid(), VendorId = vendorId, IsRead = false }
        };

        var mockRepo = new Mock<IRepository<VendorNotification>>();
        mockRepo.Setup(x => x.Query()).Returns(notifications.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.VendorNotifications).Returns(mockRepo.Object);

        // Act
        var result = await _controller.MarkAllAsRead();

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        notifications.All(n => n.IsRead).Should().BeTrue();

        // Should update each
        _mockUnitOfWork.Verify(x => x.VendorNotifications.Update(It.IsAny<VendorNotification>()), Times.Exactly(2));
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task MarkAllAsRead_WhenNoUnread_ReturnsAlreadyRead()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var notifications = new List<VendorNotification>
        {
            new VendorNotification { Id = Guid.NewGuid(), VendorId = vendorId, IsRead = true }
        };

        var mockRepo = new Mock<IRepository<VendorNotification>>();
        mockRepo.Setup(x => x.Query()).Returns(notifications.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.VendorNotifications).Returns(mockRepo.Object);

        // Act
        var result = await _controller.MarkAllAsRead();

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        _mockUnitOfWork.Verify(x => x.VendorNotifications.Update(It.IsAny<VendorNotification>()), Times.Never);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Never);
    }
}
