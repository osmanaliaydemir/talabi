using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using MockQueryable.Moq;
using Moq;
using Talabi.Api.Controllers.Couriers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class CourierNotificationsControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<UserManager<AppUser>> _mockUserManager;
    private readonly NotificationsController _controller;

    public CourierNotificationsControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();

        var userStore = new Mock<IUserStore<AppUser>>();
        _mockUserManager = new Mock<UserManager<AppUser>>(userStore.Object, null!, null!, null!, null!, null!, null!, null!, null!);

        var logger = ControllerTestHelpers.CreateMockLogger<NotificationsController>();

        _controller = new NotificationsController(
            _mockUnitOfWork.Object,
            _mockUserManager.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetNotifications_WhenCourierExists_ReturnsNotifications()
    {
        // Arrange
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courierId = Guid.NewGuid();
        var courier = new Courier { Id = courierId, UserId = userId, Name = "Test Courier" };

        // Mock Couriers
        var mockCourierRepo = new Mock<IRepository<Courier>>();
        mockCourierRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockCourierRepo.Object);

        // Mock Notifications
        var notifications = new List<CourierNotification>
        {
            new CourierNotification { Id = Guid.NewGuid(), CourierId = courierId, Title = "Note 1", IsRead = false, CreatedAt = DateTime.Now },
            new CourierNotification { Id = Guid.NewGuid(), CourierId = courierId, Title = "Note 2", IsRead = true, CreatedAt = DateTime.Now.AddMinutes(-5) }
        };

        var mockNoteRepo = new Mock<IRepository<CourierNotification>>();
        mockNoteRepo.Setup(x => x.Query()).Returns(notifications.AsQueryable().BuildMock());
        // Setup CountAsync for unread count logic if used via predicate or via query count
        // Controller uses: query.CountAsync(n => !n.IsRead)
        // MockQueryable handles this usually.

        _mockUnitOfWork.Setup(x => x.CourierNotifications).Returns(mockNoteRepo.Object);

        // Act
        var result = await _controller.GetNotifications(1, 10);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<CourierNotificationResponseDto>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data!.Items.Should().HaveCount(2);
        apiResponse.Data!.UnreadCount.Should().Be(1);
    }

    [Fact]
    public async Task MarkAsRead_WhenNotificationExists_ReturnsSuccess()
    {
        // Arrange
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courierId = Guid.NewGuid();
        var courier = new Courier { Id = courierId, UserId = userId };

        var mockCourierRepo = new Mock<IRepository<Courier>>();
        mockCourierRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockCourierRepo.Object);

        var noteId = Guid.NewGuid();
        var notification = new CourierNotification { Id = noteId, CourierId = courierId, IsRead = false };
        var notifications = new List<CourierNotification> { notification };

        var mockNoteRepo = new Mock<IRepository<CourierNotification>>();
        mockNoteRepo.Setup(x => x.Query()).Returns(notifications.AsQueryable().BuildMock());
        mockNoteRepo.Setup(x => x.Update(It.IsAny<CourierNotification>()));

        _mockUnitOfWork.Setup(x => x.CourierNotifications).Returns(mockNoteRepo.Object);
        _mockUnitOfWork.Setup(x => x.SaveChangesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(1);

        // Act
        var result = await _controller.MarkAsRead(noteId);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;

        apiResponse.Success.Should().BeTrue();
        notification.IsRead.Should().BeTrue();
        mockNoteRepo.Verify(x => x.Update(It.Is<CourierNotification>(n => n.Id == noteId && n.IsRead)), Times.Once);
    }
}
