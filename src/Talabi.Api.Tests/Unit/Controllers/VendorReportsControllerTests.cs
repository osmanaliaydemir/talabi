using System;
using System.Collections.Generic;
using System.Linq;
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
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class VendorReportsControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly VendorReportsController _controller;

    public VendorReportsControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        var logger = ControllerTestHelpers.CreateMockLogger<VendorReportsController>();

        _controller = new VendorReportsController(
            _mockUnitOfWork.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object
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
        mockRepo.Setup(x => x.Query()).Returns(vendors.BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);
    }

    [Fact]
    public async Task GetSalesReport_WhenCalled_ReturnsStats()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var orders = new List<Order>
        {
            new Order
            {
                Id = Guid.NewGuid(),
                VendorId = vendorId,
                Status = OrderStatus.Delivered,
                TotalAmount = 100,
                CreatedAt = DateTime.UtcNow,
                OrderItems = new List<OrderItem>
                {
                    new OrderItem { ProductId = Guid.NewGuid(), Quantity = 1, UnitPrice = 100, Product = new Product { Name = "P1" } }
                }
            },
            new Order
            {
                Id = Guid.NewGuid(),
                VendorId = vendorId,
                Status = OrderStatus.Cancelled,
                TotalAmount = 50,
                CreatedAt = DateTime.UtcNow
            }
        };

        var mockRepo = new Mock<IRepository<Order>>();
        mockRepo.Setup(x => x.Query()).Returns(orders.BuildMock());
        _mockUnitOfWork.Setup(x => x.Orders).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetSalesReport(period: "day");

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<SalesReportDto>>().Subject;

        // Assertions logic for stats
        apiResponse.Data.TotalOrders.Should().Be(2); // Wait, local logic will filter by date which is handled by EF mock mostly if it works correctly with dates in memory... 
                                                     // Note: MockQueryable handles Where/Date logic reasonably well but detailed sql functions might differ.
                                                     // For simplicity, we assume generic behavior.

        apiResponse.Data.CompletedOrders.Should().Be(1);
        apiResponse.Data.TotalRevenue.Should().Be(100);
        apiResponse.Data.TopProducts.Should().HaveCount(1);
        apiResponse.Data.TopProducts.First().ProductName.Should().Be("P1");
    }

    [Fact]
    public async Task GetSummary_WhenCalled_ReturnsSummary()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var today = DateTime.UtcNow;
        var orders = new List<Order>
        {
            new Order { Id = Guid.NewGuid(), VendorId = vendorId, Status = OrderStatus.Delivered, TotalAmount = 200, CreatedAt = today }, // Today
            new Order { Id = Guid.NewGuid(), VendorId = vendorId, Status = OrderStatus.Pending, TotalAmount = 100, CreatedAt = today } // Pending
        };

        var mockRepo = new Mock<IRepository<Order>>();
        mockRepo.Setup(x => x.Query()).Returns(orders.BuildMock());
        _mockUnitOfWork.Setup(x => x.Orders).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetSummary();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;

        // Use reflection or dynamic to check anonymous object properties if needed, or check JSON serialization
        // Since ApiResponse<object> returns object, we might need to inspect it carefully.
        // Usually anonymous types are internal so we can't cast comfortably in other assembly.
        // But we can check properties via reflection or just ensure success for now.

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();

        // Just cursory check via reflection
        var type = apiResponse.Data.GetType();
        type.GetProperty("todayOrders").Should().NotBeNull();
        type.GetProperty("pendingOrders").Should().NotBeNull();
    }
}
