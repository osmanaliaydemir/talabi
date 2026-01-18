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
using Talabi.Api.Controllers.Vendors;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Xunit;
using Microsoft.AspNetCore.SignalR;
using Talabi.Api.Hubs;

namespace Talabi.Api.Tests.Unit.Controllers;

public class VendorOrdersControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<IOrderAssignmentService> _mockAssignmentService;
    private readonly Mock<INotificationService> _mockNotificationService;
    private readonly Mock<IMapper> _mockMapper;
    private readonly Mock<IHubContext<NotificationHub>> _mockHubContext;
    private readonly OrdersController _controller;

    public VendorOrdersControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockAssignmentService = new Mock<IOrderAssignmentService>();
        _mockNotificationService = new Mock<INotificationService>();
        _mockMapper = new Mock<IMapper>();
        _mockHubContext = new Mock<IHubContext<NotificationHub>>();
        var mockClients = new Mock<IHubClients>();
        var mockClientProxy = new Mock<IClientProxy>();
        mockClients.Setup(x => x.Group(It.IsAny<string>())).Returns(mockClientProxy.Object);
        _mockHubContext.Setup(x => x.Clients).Returns(mockClients.Object);

        var logger = ControllerTestHelpers.CreateMockLogger<OrdersController>();

        _controller = new OrdersController(
            _mockUnitOfWork.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockAssignmentService.Object,
            _mockMapper.Object,
            _mockNotificationService.Object,
            _mockHubContext.Object
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
        var result = await _controller.GetOrders();

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
        var result = await _controller.GetOrder(orderId);

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
        var customers = new List<Customer>
            { new Customer { UserId = "cust-1", Id = Guid.NewGuid() } };
        var mockCustomerRepo = new Mock<IRepository<Customer>>();
        mockCustomerRepo.Setup(x => x.Query()).Returns(customers.BuildMock());
        _mockUnitOfWork.Setup(x => x.Customers).Returns(mockCustomerRepo.Object);

        _mockUnitOfWork.Setup(x => x.CustomerNotifications)
            .Returns(new Mock<IRepository<CustomerNotification>>().Object);
        _mockUnitOfWork.Setup(x => x.OrderStatusHistories).Returns(new Mock<IRepository<OrderStatusHistory>>().Object);

        // Act
        var result = await _controller.AcceptOrder(orderId);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        order.Status.Should().Be(OrderStatus.Preparing);

        _mockUnitOfWork.Verify(x => x.Orders.Update(order), Times.Once);
        _mockUnitOfWork.Verify(
            x => x.OrderStatusHistories.AddAsync(It.IsAny<OrderStatusHistory>(), It.IsAny<CancellationToken>()),
            Times.Once);
        _mockNotificationService.Verify(
            x => x.SendOrderStatusUpdateNotificationAsync("cust-1", orderId, "Preparing", It.IsAny<string>()),
            Times.Once);
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

        _mockUnitOfWork.Setup(x => x.CustomerNotifications)
            .Returns(new Mock<IRepository<CustomerNotification>>().Object);
        _mockUnitOfWork.Setup(x => x.OrderStatusHistories).Returns(new Mock<IRepository<OrderStatusHistory>>().Object);

        // Mock Customers repo as it's needed for notification logic
        var mockCustomerRepo = new Mock<IRepository<Customer>>();
        mockCustomerRepo.Setup(x => x.Query()).Returns(new List<Customer>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Customers).Returns(mockCustomerRepo.Object);

        var rejectDto = new Talabi.Api.Controllers.Vendors.RejectOrderDto { Reason = "Out of stock - sorry" }; // > 10 chars

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

        _mockUnitOfWork.Setup(x => x.CustomerNotifications)
            .Returns(new Mock<IRepository<CustomerNotification>>().Object);
        _mockUnitOfWork.Setup(x => x.OrderStatusHistories).Returns(new Mock<IRepository<OrderStatusHistory>>().Object);

        // Mock Customers repo as it's needed for notification logic
        var mockCustomerRepo = new Mock<IRepository<Customer>>();
        mockCustomerRepo.Setup(x => x.Query()).Returns(new List<Customer>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Customers).Returns(mockCustomerRepo.Object);

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
