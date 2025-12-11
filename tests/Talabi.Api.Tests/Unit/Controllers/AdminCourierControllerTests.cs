using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
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

public class AdminCourierControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<IOrderAssignmentService> _mockAssignmentService;
    private readonly ILogger<AdminCourierController> _logger;
    private readonly AdminCourierController _controller;

    public AdminCourierControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockAssignmentService = new Mock<IOrderAssignmentService>();
        _logger = ControllerTestHelpers.CreateMockLogger<AdminCourierController>();

        _controller = new AdminCourierController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockAssignmentService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetCouriers_WhenCalled_ReturnsCouriers()
    {
        // Arrange
        var couriers = new List<Courier>
        {
            new Courier { Id = Guid.NewGuid(), Name = "Courier 1", Status = CourierStatus.Available, IsActive = true },
            new Courier { Id = Guid.NewGuid(), Name = "Courier 2", Status = CourierStatus.Busy, IsActive = true },
            new Courier { Id = Guid.NewGuid(), Name = "Courier 3", Status = CourierStatus.Offline, IsActive = false }
        };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(couriers.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetCouriers(null, null);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<CourierProfileDto>>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data!.Should().HaveCount(3);
    }

    [Fact]
    public async Task GetCouriers_WhenFiltered_ReturnsFilteredCouriers()
    {
        // Arrange
        var couriers = new List<Courier>
        {
            new Courier { Id = Guid.NewGuid(), Name = "Courier 1", Status = CourierStatus.Available, IsActive = true },
            new Courier { Id = Guid.NewGuid(), Name = "Courier 2", Status = CourierStatus.Busy, IsActive = true }
        };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.Query()).Returns(couriers.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetCouriers("Available", true);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<CourierProfileDto>>>().Subject;

        apiResponse.Data!.Should().HaveCount(1);
        apiResponse.Data!.First().Name.Should().Be("Courier 1");
    }

    [Fact]
    public async Task AssignOrder_WhenSuccessful_ReturnsOk()
    {
        // Arrange
        var orderId = Guid.NewGuid();
        var courierId = Guid.NewGuid();

        _mockAssignmentService.Setup(x => x.AssignOrderToCourierAsync(orderId, courierId))
            .ReturnsAsync(true);

        // Act
        var result = await _controller.AssignOrder(orderId, courierId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
    }

    [Fact]
    public async Task AssignOrder_WhenFailed_ReturnsBadRequest()
    {
        // Arrange
        var orderId = Guid.NewGuid();
        var courierId = Guid.NewGuid();

        _mockAssignmentService.Setup(x => x.AssignOrderToCourierAsync(orderId, courierId))
            .ReturnsAsync(false);

        // Act
        var result = await _controller.AssignOrder(orderId, courierId);

        // Assert
        result.Result.Should().BeOfType<BadRequestObjectResult>();
    }

    [Fact]
    public async Task GetPerformance_WhenFound_ReturnsPerformance()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var courier = new Courier { Id = courierId, TotalDeliveries = 10 };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.GetByIdAsync(courierId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(courier);
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        var today = DateTime.Today;
        var orderCouriers = new List<OrderCourier>
        {
            new OrderCourier { CourierId = courierId, Order = new Order { Status = OrderStatus.Delivered }, DeliveredAt = today }
        };

        var mockOrderCourierRepo = new Mock<IRepository<OrderCourier>>();
        mockOrderCourierRepo.Setup(x => x.Query()).Returns(orderCouriers.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderCouriers).Returns(mockOrderCourierRepo.Object);

        var earnings = new List<CourierEarning>
        {
            new CourierEarning { CourierId = courierId, TotalEarning = 100, EarnedAt = today }
        };

        var mockEarningsRepo = new Mock<IRepository<CourierEarning>>();
        mockEarningsRepo.Setup(x => x.Query()).Returns(earnings.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.CourierEarnings).Returns(mockEarningsRepo.Object);

        // Act
        var result = await _controller.GetPerformance(courierId);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<CourierStatisticsDto>>().Subject;

        apiResponse.Data!.TodayDeliveries.Should().Be(1);
        apiResponse.Data!.TodayEarnings.Should().Be(100);
    }

    [Fact]
    public async Task GetPerformance_WhenNotFound_ReturnsNotFound()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.GetByIdAsync(courierId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Courier?)null);
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetPerformance(courierId);

        // Assert
        result.Result.Should().BeOfType<NotFoundObjectResult>();
    }

    [Fact]
    public async Task ActivateCourier_WhenFound_Activates()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var courier = new Courier { Id = courierId, IsActive = false };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.GetByIdAsync(courierId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(courier);
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        // Act
        var result = await _controller.ActivateCourier(courierId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        courier.IsActive.Should().BeTrue();
        _mockUnitOfWork.Verify(x => x.Couriers.Update(courier), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task DeactivateCourier_WhenActiveOrders_ReturnsBadRequest()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var courier = new Courier { Id = courierId, IsActive = true, CurrentActiveOrders = 1 };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.GetByIdAsync(courierId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(courier);
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        // Act
        var result = await _controller.DeactivateCourier(courierId);

        // Assert
        result.Result.Should().BeOfType<BadRequestObjectResult>();
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task DeactivateCourier_WhenNoActiveOrders_Deactivates()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var courier = new Courier { Id = courierId, IsActive = true, CurrentActiveOrders = 0 };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.GetByIdAsync(courierId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(courier);
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        // Act
        var result = await _controller.DeactivateCourier(courierId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        courier.IsActive.Should().BeFalse();
        courier.Status.Should().Be(CourierStatus.Offline);
    }

    [Fact]
    public async Task UpdateCourierStatus_WhenValid_UpdatesStatus()
    {
        // Arrange
        var courierId = Guid.NewGuid();
        var courier = new Courier { Id = courierId, Status = CourierStatus.Available };
        var dto = new UpdateCourierStatusDto { Status = "Busy" };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.GetByIdAsync(courierId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(courier);
        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        // Act
        var result = await _controller.UpdateCourierStatus(courierId, dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        courier.Status.Should().Be(CourierStatus.Busy);
    }

    [Fact]
    public async Task GetOverallStatistics_ReturnsStats()
    {
        // Arrange
        var couriers = new List<Courier>
        {
            new Courier { Id = Guid.NewGuid(), IsActive = true, Status = CourierStatus.Available },
            new Courier { Id = Guid.NewGuid(), IsActive = true, Status = CourierStatus.Busy }
        };

        var mockRepo = new Mock<IRepository<Courier>>();
        mockRepo.Setup(x => x.CountAsync(It.IsAny<System.Linq.Expressions.Expression<Func<Courier, bool>>>(), It.IsAny<CancellationToken>()))
             .ReturnsAsync(2); // Simple mock for total, refining for specific predicates is harder with Moq alone for extensions. 
                               // Ideally we mock the specific CountAsync calls or rely on MockQueryable but CountAsync is tricky.
                               // Usually Repo wrapper handles this.
                               // Let's rely on standard Moq setup if CountAsync is method on repo.
                               // IRepository<T> usually inherits from generic IRepository? Let's check interface definition if possible or assume standard pattern.

        // Checking CountAsync usages in controller:
        // await UnitOfWork.Couriers.CountAsync();
        // await UnitOfWork.Couriers.CountAsync(c => c.IsActive);

        // Since CountAsync is likely an extension method for IQueryable (EF Core) or a method on IRepository.
        // If it's on IRepository, we can mock it.
        // If it's IQueryable extension, MockQueryable handles it if we return queryable.
        // Let's assume MockQueryable handles it from .Query() if the controller uses .Query() then .CountAsync().
        // BUT the controller uses UnitOfWork.Couriers.CountAsync() directly. This implies custom repository method or base repository method.

        // Let's mock CountAsync with flexible arguments.
        // For total count (null predicate)
        mockRepo.Setup(x => x.CountAsync(null, It.IsAny<CancellationToken>()))
             .ReturnsAsync(2);

        // For filtered counts
        mockRepo.Setup(x => x.CountAsync(It.IsNotNull<System.Linq.Expressions.Expression<Func<Courier, bool>>>(), It.IsAny<CancellationToken>()))
             .ReturnsAsync(1);

        _mockUnitOfWork.Setup(x => x.Couriers).Returns(mockRepo.Object);

        // OrderCouriers and Earnings for today
        var orderCouriers = new List<OrderCourier>();
        var mockOrderCourierRepo = new Mock<IRepository<OrderCourier>>();
        mockOrderCourierRepo.Setup(x => x.Query()).Returns(orderCouriers.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderCouriers).Returns(mockOrderCourierRepo.Object);

        var earnings = new List<CourierEarning>();
        var mockEarningsRepo = new Mock<IRepository<CourierEarning>>();
        mockEarningsRepo.Setup(x => x.Query()).Returns(earnings.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.CourierEarnings).Returns(mockEarningsRepo.Object);

        // Act
        var result = await _controller.GetOverallStatistics();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;

        apiResponse.Data.Should().NotBeNull();
    }
}
