using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using AutoMapper;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using MockQueryable.Moq;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class CourierControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<UserManager<AppUser>> _mockUserManager;
    private readonly Mock<IMapper> _mockMapper;
    private readonly CourierController _controller;

    public CourierControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockMapper = new Mock<IMapper>();

        var userStore = new Mock<IUserStore<AppUser>>();
        _mockUserManager = new Mock<UserManager<AppUser>>(userStore.Object, null!, null!, null!, null!, null!, null!, null!, null!);

        var logger = ControllerTestHelpers.CreateMockLogger<CourierController>();

        _controller = new CourierController(
            _mockUnitOfWork.Object,
            _mockUserManager.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object
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
        var result = await _controller.GetProfile();

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
        var result = await _controller.UpdateStatus(dto);

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
        var result = await _controller.UpdateStatus(dto);

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
        var result = await _controller.UpdateLocation(dto);

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
            new OrderCourier { CourierId = courierId, DeliveredAt = DateTime.Now, Order = new Order { Status = OrderStatus.Delivered } }, // Today
            new OrderCourier { CourierId = courierId, DeliveredAt = DateTime.Now.AddDays(-1), Order = new Order { Status = OrderStatus.Delivered } } // This week
        };

        var mockOCRepo = new Mock<IRepository<OrderCourier>>();
        mockOCRepo.Setup(x => x.Query()).Returns(orderCouriers.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderCouriers).Returns(mockOCRepo.Object);

        // Act
        var result = await _controller.GetStatistics();

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
        var result = await _controller.CheckAvailability();

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
    public async Task GetActiveCouriers_ReturnsOnlyActiveCouriersWithLocation()
    {
        // Arrange
        var couriers = new List<Courier>
        {
            new Courier { Id = Guid.NewGuid(), IsActive = true, CurrentLatitude = 1, CurrentLongitude = 1, Name = "Active" },
            new Courier { Id = Guid.NewGuid(), IsActive = false, CurrentLatitude = 2, CurrentLongitude = 2, Name = "Inactive" },
            new Courier { Id = Guid.NewGuid(), IsActive = true, Name = "NoLocation" } // missing lat/long
        };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(couriers.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        _mockMapper.Setup(x => x.Map<Talabi.Core.DTOs.CourierLocationDto>(It.IsAny<Courier>()))
            .Returns((Courier c) => new Talabi.Core.DTOs.CourierLocationDto { CourierName = c.Name });

        // Act
        var result = await _controller.GetActiveCouriers();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<Talabi.Core.DTOs.CourierLocationDto>>>().Subject;

        apiResponse.Data!.Should().HaveCount(1);
        apiResponse.Data!.First().CourierName.Should().Be("Active");
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
        var mockAssignmentService = new Mock<IOrderAssignmentService>();
        mockAssignmentService.Setup(x => x.GetActiveOrdersForCourierAsync(courierId))
            .ReturnsAsync(orders);

        _mockMapper.Setup(x => x.Map<CourierOrderDto>(It.IsAny<Order>()))
            .Returns(new CourierOrderDto { Id = orders[0].Id });

        // Act
        var result = await _controller.GetActiveOrders(mockAssignmentService.Object);

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

        var mockAssignmentService = new Mock<IOrderAssignmentService>();
        mockAssignmentService.Setup(x => x.AcceptOrderAsync(orderId, courierId)).ReturnsAsync(true);

        // Act
        var result = await _controller.AcceptOrder(orderId, mockAssignmentService.Object);

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

        var mockAssignmentService = new Mock<IOrderAssignmentService>();
        mockAssignmentService.Setup(x => x.RejectOrderAsync(orderId, courierId, It.IsAny<string>())).ReturnsAsync(true);

        var dto = new Talabi.Core.DTOs.Courier.RejectOrderDto { Reason = "Traffic is too heavy right now" };

        // Act
        var result = await _controller.RejectOrder(orderId, dto, mockAssignmentService.Object);

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

        var mockAssignmentService = new Mock<IOrderAssignmentService>();
        mockAssignmentService.Setup(x => x.PickUpOrderAsync(orderId, courierId)).ReturnsAsync(true);

        // Act
        var result = await _controller.PickUpOrder(orderId, mockAssignmentService.Object);

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

        var mockAssignmentService = new Mock<IOrderAssignmentService>();
        mockAssignmentService.Setup(x => x.DeliverOrderAsync(orderId, courierId)).ReturnsAsync(true);

        // Act
        var result = await _controller.DeliverOrder(orderId, mockAssignmentService.Object);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
    }
}
