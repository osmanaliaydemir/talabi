using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Identity;
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

public class CustomerNotificationsControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<UserManager<AppUser>> _mockUserManager;
    private readonly CustomerNotificationsController _controller;

    public CustomerNotificationsControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();

        var userStore = new Mock<IUserStore<AppUser>>();
        _mockUserManager = new Mock<UserManager<AppUser>>(userStore.Object, null!, null!, null!, null!, null!, null!, null!, null!);

        var logger = ControllerTestHelpers.CreateMockLogger<CustomerNotificationsController>();

        _controller = new CustomerNotificationsController(
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

    [Fact]
    public async Task GetNotifications_WhenCustomerExists_ReturnsNotifications()
    {
        // Arrange
        var userId = "user-1";
        var customerId = Guid.NewGuid();
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var customer = new Customer { Id = customerId, UserId = userId };
        var customers = new List<Customer> { customer };

        var mockCustomerRepo = new Mock<IRepository<Customer>>();
        mockCustomerRepo.Setup(x => x.Query()).Returns(customers.BuildMock());
        _mockUnitOfWork.Setup(x => x.Customers).Returns(mockCustomerRepo.Object);

        // Notifications
        var notif1 = new CustomerNotification { Id = Guid.NewGuid(), CustomerId = customerId, Message = "Test", IsRead = false };
        var notifications = new List<CustomerNotification> { notif1 };

        var mockNotifRepo = new Mock<IRepository<CustomerNotification>>();
        mockNotifRepo.Setup(x => x.Query()).Returns(notifications.BuildMock());
        _mockUnitOfWork.Setup(x => x.CustomerNotifications).Returns(mockNotifRepo.Object);

        // Act
        var result = await _controller.GetNotifications();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<CustomerNotificationResponseDto>>().Subject;

        apiResponse.Data!.Items.Should().Contain(n => n.Message == "Test");
        apiResponse.Data!.UnreadCount.Should().Be(1);
    }

    [Fact]
    public async Task MarkAsRead_WhenNotificationExists_MarksAsRead()
    {
        // Arrange
        var userId = "user-1";
        var customerId = Guid.NewGuid();
        var notifId = Guid.NewGuid();
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var customer = new Customer { Id = customerId, UserId = userId };
        var customers = new List<Customer> { customer };

        var mockCustomerRepo = new Mock<IRepository<Customer>>();
        mockCustomerRepo.Setup(x => x.Query()).Returns(customers.BuildMock());
        _mockUnitOfWork.Setup(x => x.Customers).Returns(mockCustomerRepo.Object);

        var notif = new CustomerNotification { Id = notifId, CustomerId = customerId, IsRead = false };
        var notifications = new List<CustomerNotification> { notif };

        var mockNotifRepo = new Mock<IRepository<CustomerNotification>>();
        mockNotifRepo.Setup(x => x.Query()).Returns(notifications.BuildMock());
        _mockUnitOfWork.Setup(x => x.CustomerNotifications).Returns(mockNotifRepo.Object);

        // Act
        var result = await _controller.MarkAsRead(notifId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.CustomerNotifications.Update(It.Is<CustomerNotification>(n => n.IsRead == true)), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task MarkAllAsRead_WhenUnreadExists_MarksAllAsRead()
    {
        // Arrange
        var userId = "user-1";
        var customerId = Guid.NewGuid();
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var customer = new Customer { Id = customerId, UserId = userId };
        var customers = new List<Customer> { customer };

        var mockCustomerRepo = new Mock<IRepository<Customer>>();
        mockCustomerRepo.Setup(x => x.Query()).Returns(customers.BuildMock());
        _mockUnitOfWork.Setup(x => x.Customers).Returns(mockCustomerRepo.Object);

        var notif1 = new CustomerNotification { Id = Guid.NewGuid(), CustomerId = customerId, IsRead = false };
        var notif2 = new CustomerNotification { Id = Guid.NewGuid(), CustomerId = customerId, IsRead = false };
        var notifications = new List<CustomerNotification> { notif1, notif2 };

        var mockNotifRepo = new Mock<IRepository<CustomerNotification>>();
        mockNotifRepo.Setup(x => x.Query()).Returns(notifications.BuildMock());
        _mockUnitOfWork.Setup(x => x.CustomerNotifications).Returns(mockNotifRepo.Object);

        // Act
        var result = await _controller.MarkAllAsRead();

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.CustomerNotifications.Update(It.Is<CustomerNotification>(n => n.IsRead == true)), Times.Exactly(2));
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }
}
