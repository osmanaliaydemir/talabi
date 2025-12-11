using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using AutoMapper;
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

public class VendorOrdersControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<IOrderAssignmentService> _mockAssignmentService;
    private readonly Mock<INotificationService> _mockNotificationService;
    private readonly Mock<IMapper> _mockMapper;
    private readonly VendorOrdersController _controller;

    public VendorOrdersControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockAssignmentService = new Mock<IOrderAssignmentService>();
        _mockNotificationService = new Mock<INotificationService>();
        _mockMapper = new Mock<IMapper>();

        var logger = ControllerTestHelpers.CreateMockLogger<VendorOrdersController>();

        _controller = new VendorOrdersController(
            _mockUnitOfWork.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockAssignmentService.Object,
            _mockMapper.Object,
            _mockNotificationService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetVendorOrders_WhenCalled_ReturnsPagedOrders()
    {
        // Arrange
        var vendorId = Guid.NewGuid();
        _mockUserContextService.Setup(x => x.GetVendorIdAsync()).ReturnsAsync(vendorId);

        var orders = new List<Order>
        {
            new Order
            {
                Id = Guid.NewGuid(),
                VendorId = vendorId,
                Status = OrderStatus.Pending,
                CreatedAt = DateTime.UtcNow,
                Customer = new AppUser { FullName = "John Doe", Email = "john@example.com" }
            }
        };

        var mockRepo = new Mock<IRepository<Order>>();
        mockRepo.Setup(x => x.Query()).Returns(orders.BuildMock());
        _mockUnitOfWork.Setup(x => x.Orders).Returns(mockRepo.Object);

        _mockMapper.Setup(x => x.Map<List<VendorOrderItemDto>>(It.IsAny<List<OrderItem>>()))
            .Returns(new List<VendorOrderItemDto>());

        // Act
        var result = await _controller.GetVendorOrders();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<VendorOrderDto>>>().Subject;

        apiResponse.Data!.TotalCount.Should().Be(1);
        apiResponse.Data!.Items.Should().HaveCount(1);
        apiResponse.Data!.Items.First().CustomerName.Should().Be("John Doe");
    }

    [Fact]
    public async Task GetVendorOrder_WhenFound_ReturnsOrder()
    {
        // Arrange
        var vendorId = Guid.NewGuid();
        var orderId = Guid.NewGuid();
        _mockUserContextService.Setup(x => x.GetVendorIdAsync()).ReturnsAsync(vendorId);

        var order = new Order
        {
            Id = orderId,
            VendorId = vendorId,
            Customer = new AppUser { FullName = "Jane Doe", Email = "jane@example.com" },
            OrderItems = new List<OrderItem>()
        };
        var orders = new List<Order> { order };

        var mockRepo = new Mock<IRepository<Order>>();
        mockRepo.Setup(x => x.Query()).Returns(orders.BuildMock());
        _mockUnitOfWork.Setup(x => x.Orders).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetVendorOrder(orderId);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<VendorOrderDto>>().Subject;

        apiResponse.Data!.Id.Should().Be(orderId);
    }

    [Fact]
    public async Task AcceptOrder_WhenPending_AcceptsOrder()
    {
        // Arrange
        var vendorId = Guid.NewGuid();
        var orderId = Guid.NewGuid();
        var userId = "user-1";

        _mockUserContextService.Setup(x => x.GetVendorIdAsync()).ReturnsAsync(vendorId);
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var order = new Order
        {
            Id = orderId,
            VendorId = vendorId,
            Status = OrderStatus.Pending,
            CustomerId = "cust-1",
            CustomerOrderId = "ORD-123"
        };
        var orders = new List<Order> { order };

        var mockRepo = new Mock<IRepository<Order>>();
        mockRepo.Setup(x => x.Query()).Returns(orders.BuildMock());
        _mockUnitOfWork.Setup(x => x.Orders).Returns(mockRepo.Object);

        // Mock for customer notification logic
        var customers = new List<Customer> { new Customer { UserId = "cust-1", Id = Guid.NewGuid() } }; // Match CustomerId from order? 
        // Logic uses order.CustomerId as UserId lookup in AddCustomerNotificationAsync
        var mockCustomerRepo = new Mock<IRepository<Customer>>();
        mockCustomerRepo.Setup(x => x.Query()).Returns(customers.BuildMock());
        _mockUnitOfWork.Setup(x => x.Customers).Returns(mockCustomerRepo.Object);

        _mockUnitOfWork.Setup(x => x.CustomerNotifications).Returns(new Mock<IRepository<CustomerNotification>>().Object);
        _mockUnitOfWork.Setup(x => x.OrderStatusHistories).Returns(new Mock<IRepository<OrderStatusHistory>>().Object);

        // Act
        var result = await _controller.AcceptOrder(orderId);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        order.Status.Should().Be(OrderStatus.Preparing);

        _mockUnitOfWork.Verify(x => x.Orders.Update(order), Times.Once);
        _mockUnitOfWork.Verify(x => x.OrderStatusHistories.AddAsync(It.IsAny<OrderStatusHistory>(), It.IsAny<CancellationToken>()), Times.Once);
        _mockNotificationService.Verify(x => x.SendOrderStatusUpdateNotificationAsync("cust-1", orderId, "Preparing", It.IsAny<string>()), Times.Once);
    }

    [Fact]
    public async Task RejectOrder_WhenReasonProvided_RejectsOrder()
    {
        // Arrange
        var vendorId = Guid.NewGuid();
        var orderId = Guid.NewGuid();

        _mockUserContextService.Setup(x => x.GetVendorIdAsync()).ReturnsAsync(vendorId);

        var order = new Order
        {
            Id = orderId,
            VendorId = vendorId,
            Status = OrderStatus.Pending
        };
        var orders = new List<Order> { order };

        var mockRepo = new Mock<IRepository<Order>>();
        mockRepo.Setup(x => x.Query()).Returns(orders.BuildMock());
        _mockUnitOfWork.Setup(x => x.Orders).Returns(mockRepo.Object);

        _mockUnitOfWork.Setup(x => x.CustomerNotifications).Returns(new Mock<IRepository<CustomerNotification>>().Object);
        _mockUnitOfWork.Setup(x => x.OrderStatusHistories).Returns(new Mock<IRepository<OrderStatusHistory>>().Object);
        // Customer repo needs to be mocked for AddCustomerNotificationAsync, even if customer is null (it handles creating it)
        // But here order doesn't have CustomerId or it's null?
        // RejectOrder code: if (!string.IsNullOrEmpty(order.CustomerId) && order.CustomerId != "anonymous")
        // In this test setup, order has Status=Pending, but I didn't set CustomerId. Default is null?
        // Let's check constructor of Order... CustomerId defaults to string.Empty.
        // So IsNullOrEmpty(string.Empty) is true. So it skips AddCustomerNotificationAsync.
        // BUT it DOES add to OrderStatusHistories.
        // So only OrderStatusHistories is strictly required if CustomerId is empty.
        // But let's mock both to be safe and consistent.

        var rejectDto = new RejectOrderDto { Reason = "Out of stock - sorry" }; // > 10 chars

        // Act
        var result = await _controller.RejectOrder(orderId, rejectDto);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        order.Status.Should().Be(OrderStatus.Cancelled);
        order.CancelReason.Should().Contain(rejectDto.Reason);

        _mockUnitOfWork.Verify(x => x.Orders.Update(order), Times.Once);
    }

    [Fact]
    public async Task UpdateOrderStatus_WhenValidTransition_UpdatesStatus()
    {
        // Arrange
        var vendorId = Guid.NewGuid();
        var orderId = Guid.NewGuid();

        _mockUserContextService.Setup(x => x.GetVendorIdAsync()).ReturnsAsync(vendorId);

        var order = new Order
        {
            Id = orderId,
            VendorId = vendorId,
            Status = OrderStatus.Pending
        };
        var orders = new List<Order> { order };

        var mockRepo = new Mock<IRepository<Order>>();
        mockRepo.Setup(x => x.Query()).Returns(orders.BuildMock());
        _mockUnitOfWork.Setup(x => x.Orders).Returns(mockRepo.Object);

        _mockUnitOfWork.Setup(x => x.CustomerNotifications).Returns(new Mock<IRepository<CustomerNotification>>().Object);
        _mockUnitOfWork.Setup(x => x.OrderStatusHistories).Returns(new Mock<IRepository<OrderStatusHistory>>().Object);

        var updateDto = new UpdateOrderStatusDto { Status = "Preparing" }; // Valid transition from Pending

        // Act
        var result = await _controller.UpdateOrderStatus(orderId, updateDto);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        order.Status.Should().Be(OrderStatus.Preparing);
    }

    [Fact]
    public async Task UpdateOrderStatus_WhenInvalidTransition_ReturnsBadRequest()
    {
        // Arrange
        var vendorId = Guid.NewGuid();
        var orderId = Guid.NewGuid();

        _mockUserContextService.Setup(x => x.GetVendorIdAsync()).ReturnsAsync(vendorId);

        var order = new Order
        {
            Id = orderId,
            VendorId = vendorId,
            Status = OrderStatus.Pending
        };
        var orders = new List<Order> { order };

        var mockRepo = new Mock<IRepository<Order>>();
        mockRepo.Setup(x => x.Query()).Returns(orders.BuildMock());
        _mockUnitOfWork.Setup(x => x.Orders).Returns(mockRepo.Object);

        var updateDto = new UpdateOrderStatusDto { Status = "Delivered" }; // Invalid from Pending

        // Act
        var result = await _controller.UpdateOrderStatus(orderId, updateDto);

        // Assert
        var badRequestResult = result.Result.Should().BeOfType<BadRequestObjectResult>().Subject;
        var apiResponse = badRequestResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.ErrorCode.Should().Be("INVALID_STATUS_TRANSITION");
    }
}
