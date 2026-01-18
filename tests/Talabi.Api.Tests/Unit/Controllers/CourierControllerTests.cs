using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using FluentAssertions;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using MockQueryable.Moq;
using Moq;
using Talabi.Api.Controllers.Couriers;
using CourierOrdersController = Talabi.Api.Controllers.Couriers.OrdersController;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Xunit;
using Microsoft.AspNetCore.SignalR;
using Talabi.Api.Hubs;

namespace Talabi.Api.Tests.Unit.Controllers;

public class CourierControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<UserManager<AppUser>> _mockUserManager;
    private readonly Mock<IMapper> _mockMapper;
    private readonly Mock<IHubContext<NotificationHub>> _mockHubContext;
    private readonly Mock<IOrderAssignmentService> _mockAssignmentService;
    private readonly Mock<IRepository<SystemSetting>> _mockSystemSettingRepo;
    private readonly Mock<IRepository<WalletTransaction>> _mockWalletTransactionRepo;

    private readonly AccountController _accountController;
    private readonly StatisticsController _statisticsController;
    private readonly CourierOrdersController _ordersController;
    private readonly Talabi.Api.Controllers.AdminCourierController _adminCourierController;

    public CourierControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockMapper = new Mock<IMapper>();
        _mockHubContext = new Mock<IHubContext<NotificationHub>>();
        _mockAssignmentService = new Mock<IOrderAssignmentService>();
        _mockSystemSettingRepo = new Mock<IRepository<SystemSetting>>();
        _mockWalletTransactionRepo = new Mock<IRepository<WalletTransaction>>();

        var userStore = new Mock<IUserStore<AppUser>>();
        _mockUserManager =
            new Mock<UserManager<AppUser>>(userStore.Object, null!, null!, null!, null!, null!, null!, null!, null!);

        var accountLogger = ControllerTestHelpers.CreateMockLogger<AccountController>();
        var statisticsLogger = ControllerTestHelpers.CreateMockLogger<StatisticsController>();
        var ordersLogger = ControllerTestHelpers.CreateMockLogger<CourierOrdersController>();
        var adminLogger = ControllerTestHelpers.CreateMockLogger<Talabi.Api.Controllers.AdminCourierController>();

        // Default: empty queries for enrichment dependencies
        _mockSystemSettingRepo.Setup(x => x.Query()).Returns(new List<SystemSetting>().AsQueryable().BuildMock());
        _mockWalletTransactionRepo.Setup(x => x.Query()).Returns(new List<WalletTransaction>().AsQueryable().BuildMock());

        _accountController = new AccountController(
            _mockUnitOfWork.Object,
            _mockUserManager.Object,
            accountLogger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object,
            _mockHubContext.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };

        _statisticsController = new StatisticsController(
            _mockUnitOfWork.Object,
            statisticsLogger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };

        _ordersController = new CourierOrdersController(
            _mockUnitOfWork.Object,
            ordersLogger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object,
            _mockAssignmentService.Object,
            _mockSystemSettingRepo.Object,
            _mockWalletTransactionRepo.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };

        _adminCourierController = new Talabi.Api.Controllers.AdminCourierController(
            _mockUnitOfWork.Object,
            adminLogger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockAssignmentService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetProfile_WhenCourierExists_ReturnsProfile()
    {
        // Arrange
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courier = new Courier
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = "Test Courier"
        };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        _mockMapper.Setup(x => x.Map<CourierProfileDto>(It.IsAny<Courier>()))
            .Returns(new CourierProfileDto { Name = "Test Courier" });

        // Act
        var result = await _accountController.GetProfile();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<CourierProfileDto>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data!.Name.Should().Be("Test Courier");
    }

    /*
    [Fact]
    public async Task GetProfile_WhenCourierDoesNotExist_CreatesAndReturnsProfile()
    {
        // Arrange
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var user = new AppUser { Id = userId, FullName = "New Courier" };

        var mockRepo = new Mock<IRepository<Courier>>();
        // Empty list initially
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier>().AsQueryable().BuildMock());
        // Verify Add is called
        mockRepo.Setup(x => x.AddAsync(It.IsAny<Courier>(), It.IsAny<System.Threading.CancellationToken>()))
            .ReturnsAsync(new Courier());

        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);
        _mockUnitOfWork.Setup(x => x.SaveChangesAsync()).Returns(Task.CompletedTask);

        _mockUserManager.Setup(x => x.FindByIdAsync(userId)).ReturnsAsync(user);

        _mockMapper.Setup(x => x.Map<CourierProfileDto>(It.IsAny<Courier>()))
            .Returns(new CourierProfileDto { Name = "New Courier" });

        // Act
        var result = await _controller.GetProfile();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<CourierProfileDto>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Name.Should().Be("New Courier");
        mockRepo.Verify(x => x.AddAsync(It.IsAny<Courier>(), It.IsAny<System.Threading.CancellationToken>()), Times.Once);
    }
    */
    [Fact]
    public async Task UpdateStatus_WhenValidStatus_UpdatesStatus()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courier = new Courier
        {
            Id = courierId,
            UserId = userId,
            Status = CourierStatus.Offline,
            IsActive = true,
            IsWithinWorkingHours = true
        };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        var dto = new UpdateCourierStatusDto { Status = "Available" };

        // Act
        var result = await _accountController.UpdateStatus(dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        courier.Status.Should().Be(CourierStatus.Available);
        _mockUnitOfWork.Verify(x => x.Couriers.Update(courier), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateStatus_WhenGoingOfflineWithActiveOrders_ReturnsBadRequest()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courier = new Courier
        {
            Id = courierId,
            UserId = userId,
            Status = CourierStatus.Available,
            CurrentActiveOrders = 1 // Has active orders
        };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        var dto = new UpdateCourierStatusDto { Status = "Offline" };

        // Act
        var result = await _accountController.UpdateStatus(dto);

        // Assert
        var badRequestResult = result.Result.Should().BeOfType<BadRequestObjectResult>().Subject;
        var apiResponse = badRequestResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.ErrorCode.Should().Be("CANNOT_GO_OFFLINE_WITH_ACTIVE_ORDERS");
    }

    [Fact]
    public async Task UpdateLocation_WhenValidCoordinates_UpdatesLocation()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courier = new Courier
        {
            Id = courierId,
            UserId = userId
        };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        var dto = new Talabi.Core.DTOs.Courier.UpdateCourierLocationDto { Latitude = 41.0, Longitude = 29.0 };

        // Act
        var result = await _accountController.UpdateLocation(dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        courier.CurrentLatitude.Should().Be(41.0);
        courier.CurrentLongitude.Should().Be(29.0);
        _mockUnitOfWork.Verify(x => x.Couriers.Update(courier), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task GetStatistics_ReturnsCorrectStats()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courier = new Courier
        {
            Id = courierId,
            UserId = userId,
            TotalDeliveries = 10,
            TotalEarnings = 1000,
            CurrentDayEarnings = 100,
            AverageRating = 4.5,
            TotalRatings = 5,
            CurrentActiveOrders = 1
        };

        var mockCourierRepo = new Mock<IRepository<Courier>>();
        mockCourierRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockCourierRepo.Object);

        // Mock OrderCouriers for calculate today/week/month stats
        var today = DateTime.Today;
        var orderCouriers = new List<OrderCourier>
        {
            new OrderCourier
            {
                CourierId = courierId, DeliveredAt = DateTime.Now, Order = new Order { Status = OrderStatus.Delivered }
            }, // Today
            new OrderCourier
            {
                CourierId = courierId, DeliveredAt = DateTime.Now.AddDays(-1),
                Order = new Order { Status = OrderStatus.Delivered }
            } // This week
        };

        var mockOCRepo = new Mock<IRepository<OrderCourier>>();
        mockOCRepo.Setup(x => x.Query()).Returns(orderCouriers.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderCouriers).Returns(mockOCRepo.Object);

        // Act
        var result = await _statisticsController.GetStatistics();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<CourierStatisticsDto>>().Subject;

        apiResponse.Data!.TotalDeliveries.Should().Be(10);
        apiResponse.Data.TodayDeliveries.Should().Be(1);
        apiResponse.Data.WeekDeliveries.Should().Be(2); // Today included in week
        apiResponse.Data.ActiveOrders.Should().Be(1);
    }

    [Fact]
    public async Task CheckAvailability_WhenAvailable_ReturnsTrue()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courier = new Courier
        {
            Id = courierId,
            UserId = userId,
            Status = CourierStatus.Available,
            IsActive = true,
            CurrentActiveOrders = 0,
            MaxActiveOrders = 3
        };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        // Act
        var result = await _accountController.CheckAvailability();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        // The endpoint returns ApiResponse<object>, so we need to inspect the object properties dynamically or knowing the structure
        var data = okResult.Value!.GetType().GetProperty("Data")?.GetValue(okResult.Value);
        // Using reflection because return type is object
        var isAvailableProp = data!.GetType().GetProperty("IsAvailable");
        isAvailableProp.Should().NotBeNull();
        isAvailableProp!.GetValue(data).Should().Be(true);
    }

    [Fact]
    public async Task AdminGetCouriers_WhenFilteredByIsActive_ReturnsOnlyActiveCouriers()
    {
        // Arrange
        var couriers = new List<Courier>
        {
            new Courier
            {
                Id = Guid.NewGuid(),
                UserId = "u1",
                Name = "Active",
                IsActive = true,
                Status = CourierStatus.Available,
                CurrentLatitude = 41.0,
                CurrentLongitude = 29.0
            },
            new Courier
            {
                Id = Guid.NewGuid(),
                UserId = "u2",
                Name = "Inactive",
                IsActive = false,
                Status = CourierStatus.Offline,
                CurrentLatitude = 41.1,
                CurrentLongitude = 29.1
            }
        };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(couriers.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        // Act
        var result = await _adminCourierController.GetCouriers(status: null, isActive: true);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<CourierProfileDto>>>().Subject;

        apiResponse.Data!.Should().HaveCount(1);
        apiResponse.Data!.First().Name.Should().Be("Active");
    }

    [Fact]
    public async Task GetActiveOrders_ReturnsActiveOrders()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courier = new Courier { Id = courierId, UserId = userId };
        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        var orders = new List<Order> { new Order { Id = Guid.NewGuid() } };
        _mockAssignmentService.Setup(x => x.GetActiveOrdersForCourierAsync(courierId))
            .ReturnsAsync(orders);

        _mockMapper.Setup(x => x.Map<CourierOrderDto>(It.IsAny<Order>()))
            .Returns(new CourierOrderDto { Id = orders[0].Id });

        // Act
        var result = await _ordersController.GetActiveOrders();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<CourierOrderDto>>>().Subject;
        apiResponse.Data!.Should().HaveCount(1);
    }

    [Fact]
    public async Task AcceptOrder_WhenSuccessful_ReturnsOk()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var orderId = Guid.NewGuid();
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courier = new Courier { Id = courierId, UserId = userId };
        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        _mockAssignmentService.Setup(x => x.AcceptOrderAsync(orderId, courierId)).ReturnsAsync(true);

        // Act
        var result = await _ordersController.AcceptOrder(orderId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
    }

    [Fact]
    public async Task RejectOrder_WhenSuccessful_ReturnsOk()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var orderId = Guid.NewGuid();
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courier = new Courier { Id = courierId, UserId = userId };
        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        _mockAssignmentService.Setup(x => x.RejectOrderAsync(orderId, courierId, It.IsAny<string>())).ReturnsAsync(true);

        var dto = new Talabi.Core.DTOs.Courier.RejectOrderDto { Reason = "Traffic is too heavy right now" };

        // Act
        var result = await _ordersController.RejectOrder(orderId, dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
    }

    [Fact]
    public async Task PickUpOrder_WhenSuccessful_ReturnsOk()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var orderId = Guid.NewGuid();
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courier = new Courier { Id = courierId, UserId = userId };
        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        _mockAssignmentService.Setup(x => x.PickUpOrderAsync(orderId, courierId)).ReturnsAsync(true);

        // Act
        var result = await _ordersController.PickUpOrder(orderId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
    }

    [Fact]
    public async Task DeliverOrder_WhenSuccessful_ReturnsOk()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var orderId = Guid.NewGuid();
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var courier = new Courier { Id = courierId, UserId = userId };
        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(new List<Courier> { courier }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        _mockAssignmentService.Setup(x => x.DeliverOrderAsync(orderId, courierId)).ReturnsAsync(true);

        // Act
        var result = await _ordersController.DeliverOrder(orderId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
    }
}
