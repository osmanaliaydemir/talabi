using AutoMapper;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using MockQueryable.Moq;
using MockQueryable;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Xunit;
using System.Linq;
using System.Threading;
using System.Globalization;
using Microsoft.AspNetCore.SignalR;
using Talabi.Api.Hubs;

namespace Talabi.Api.Tests.Unit.Controllers;

/// <summary>
/// OrdersController için unit testler
/// </summary>
public class OrdersControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<IOrderService> _mockOrderService;
    private readonly Mock<IOrderAssignmentService> _mockAssignmentService;
    private readonly Mock<IMapper> _mockMapper;
    private readonly ILogger<OrdersController> _logger;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<INotificationService> _mockNotificationService;
    private readonly Mock<IDashboardNotificationService> _mockDashboardNotificationService;
    private readonly Mock<IHubContext<NotificationHub>> _mockHubContext;
    private readonly OrdersController _controller;

    public OrdersControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockOrderService = new Mock<IOrderService>();
        _mockAssignmentService = new Mock<IOrderAssignmentService>();
        _mockMapper = new Mock<IMapper>();
        _logger = ControllerTestHelpers.CreateMockLogger<OrdersController>();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockNotificationService = new Mock<INotificationService>();
        _mockDashboardNotificationService = new Mock<IDashboardNotificationService>();
        _mockHubContext = new Mock<IHubContext<NotificationHub>>();

        _controller = new OrdersController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockAssignmentService.Object,
            _mockOrderService.Object,
            _mockMapper.Object,
            _mockNotificationService.Object,
            _mockDashboardNotificationService.Object,
            _mockHubContext.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task CreateOrder_WhenSuccessful_ReturnsCreated()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var createDto = new CreateOrderDto { VendorId = Guid.NewGuid(), DeliveryAddressId = Guid.NewGuid() };
        var createdOrder = new Order { Id = Guid.NewGuid(), VendorId = createDto.VendorId, CustomerId = userId };
        var orderDto = new OrderDto { Id = createdOrder.Id };

        _mockOrderService.Setup(x => x.CreateOrderAsync(createDto, userId, It.IsAny<CultureInfo>()))
            .ReturnsAsync(createdOrder);

        _mockMapper.Setup(x => x.Map<OrderDto>(createdOrder)).Returns(orderDto);

        // Vendor loading setup
        var vendorRepo = new Mock<IRepository<Vendor>>();
        vendorRepo.Setup(x => x.GetByIdAsync(createdOrder.VendorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Vendor());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(vendorRepo.Object);

        // Act
        var result = await _controller.CreateOrder(createDto);

        // Assert
        var createdResult = result.Result.Should().BeOfType<CreatedAtActionResult>().Subject;
        var apiResponse = createdResult.Value.Should().BeOfType<ApiResponse<OrderDto>>().Subject;

        apiResponse.Data!.Id.Should().Be(createdOrder.Id);

        _mockUnitOfWork.Verify(x => x.BeginTransactionAsync(It.IsAny<CancellationToken>()), Times.Once);
        _mockUnitOfWork.Verify(x => x.CommitTransactionAsync(It.IsAny<CancellationToken>()), Times.Once);
        _mockAssignmentService.Verify(x => x.FindBestCourierAsync(createdOrder), Times.Once);
    }

    [Fact]
    public async Task CreateOrder_WhenServiceFails_RollbacksTransaction()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        _mockOrderService.Setup(x =>
                x.CreateOrderAsync(It.IsAny<CreateOrderDto>(), It.IsAny<string>(), It.IsAny<CultureInfo>()))
            .ThrowsAsync(new Exception("Order creation failed"));

        // Act
        Func<Task> act = async () => await _controller.CreateOrder(new CreateOrderDto());

        // Assert
        await act.Should().ThrowAsync<Exception>().WithMessage("Order creation failed");

        _mockUnitOfWork.Verify(x => x.BeginTransactionAsync(It.IsAny<CancellationToken>()), Times.Once);
        _mockUnitOfWork.Verify(x => x.RollbackTransactionAsync(It.IsAny<CancellationToken>()), Times.Once);
        _mockUnitOfWork.Verify(x => x.CommitTransactionAsync(It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task GetOrder_WhenFound_ReturnsOk()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        var orderId = Guid.NewGuid();
        var order = new Order { Id = orderId, CustomerId = userId };

        var orders = new List<Order> { order };
        var mockRepo = new Mock<IRepository<Order>>();
        mockRepo.Setup(x => x.Query()).Returns(orders.BuildMock());
        _mockUnitOfWork.Setup(x => x.Orders).Returns(mockRepo.Object);

        _mockMapper.Setup(x => x.Map<OrderDto>(order)).Returns(new OrderDto { Id = orderId });

        // Act
        var result = await _controller.GetOrder(orderId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
    }

    [Fact]
    public async Task GetOrder_WhenNotFoundOrNotOwner_ReturnsNotFound()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        var orderId = Guid.NewGuid();

        // Order belongs to another user
        var order = new Order { Id = orderId, CustomerId = "other-user" };

        var orders = new List<Order> { order };
        var mockRepo = new Mock<IRepository<Order>>();
        mockRepo.Setup(x => x.Query()).Returns(orders.BuildMock());
        _mockUnitOfWork.Setup(x => x.Orders).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetOrder(orderId);

        // Assert
        var notFoundResult = result.Result.Should().BeOfType<NotFoundObjectResult>().Subject;
        var apiResponse = notFoundResult.Value.Should().BeOfType<ApiResponse<OrderDto>>().Subject;
        apiResponse.ErrorCode.Should().Be("ORDER_NOT_FOUND");
    }

    [Fact]
    public async Task CancelOrder_WhenCalled_DelegatesToService()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        var orderId = Guid.NewGuid();
        var cancelDto = new CancelOrderDto { Reason = "Change of mind" };

        // Act
        var result = await _controller.CancelOrder(orderId, cancelDto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.BeginTransactionAsync(It.IsAny<CancellationToken>()), Times.Once);
        _mockOrderService.Verify(x => x.CancelOrderAsync(orderId, userId, cancelDto, It.IsAny<CultureInfo>()),
            Times.Once);
        _mockUnitOfWork.Verify(x => x.CommitTransactionAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CancelOrder_WhenConcurrencyException_ReturnsConflict()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        var orderId = Guid.NewGuid();
        var cancelDto = new CancelOrderDto();

        _mockOrderService.Setup(x => x.CancelOrderAsync(It.IsAny<Guid>(), It.IsAny<string>(),
                It.IsAny<CancelOrderDto>(), It.IsAny<CultureInfo>()))
            .ThrowsAsync(new DbUpdateConcurrencyException());

        // Act
        var result = await _controller.CancelOrder(orderId, cancelDto);

        // Assert
        result.Result.Should().BeOfType<ConflictObjectResult>();
        _mockUnitOfWork.Verify(x => x.RollbackTransactionAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CancelOrderItem_WhenSuccessful_CancelsItemAndUpdatesTotal()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        var orderId = Guid.NewGuid();
        var orderItemId = Guid.NewGuid();
        var customerOrderItemId = "item-123";

        var order = new Order
        {
            Id = orderId,
            CustomerId = userId,
            Status = OrderStatus.Pending,
            TotalAmount = 100,
            StatusHistory = new List<OrderStatusHistory>()
        };

        var orderItem = new OrderItem
        {
            Id = orderItemId,
            OrderId = orderId,
            CustomerOrderItemId = customerOrderItemId,
            Order = order,
            Quantity = 2,
            UnitPrice = 25, // Total 50
            IsCancelled = false
        };

        var orderItems = new List<OrderItem>
        {
            orderItem, new OrderItem { Id = Guid.NewGuid(), OrderId = orderId, IsCancelled = false }
        }; // One cancelled, one remaining

        var mockItemRepo = new Mock<IRepository<OrderItem>>();
        // Setup Query to return correct items based on expression is tricky with simple lists
        // MockQueryable handles Where/FirstOrDefault well
        mockItemRepo.Setup(x => x.Query()).Returns(orderItems.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderItems).Returns(mockItemRepo.Object);

        var mockHistoryRepo = new Mock<IRepository<OrderStatusHistory>>();
        mockHistoryRepo
            .Setup(x => x.AddAsync(It.IsAny<OrderStatusHistory>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((OrderStatusHistory h, CancellationToken _) => h);
        _mockUnitOfWork.Setup(x => x.OrderStatusHistories).Returns(mockHistoryRepo.Object);

        var cancelDto = new CancelOrderDto { Reason = "Too expensive" };

        // Act
        var result = await _controller.CancelOrderItem(customerOrderItemId, cancelDto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        orderItem.IsCancelled.Should().BeTrue();
        orderItem.CancelReason.Should().Be(cancelDto.Reason);
        order.TotalAmount.Should().Be(50); // 100 - (2*25) = 50
        order.Status.Should().Be(OrderStatus.Pending); // Still pending as items remain
        mockHistoryRepo.Verify(
            x => x.AddAsync(It.IsAny<OrderStatusHistory>(), It.IsAny<CancellationToken>()),
            Times.Once);
        _mockUnitOfWork.Verify(x => x.CommitTransactionAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CancelOrderItem_WhenAllItemsCancelled_CancelsOrder()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        var orderId = Guid.NewGuid();
        var customerOrderItemId = "item-123";

        var order = new Order
        {
            Id = orderId,
            CustomerId = userId,
            Status = OrderStatus.Pending,
            TotalAmount = 50,
            StatusHistory = new List<OrderStatusHistory>()
        };

        var orderItem = new OrderItem
        {
            Id = Guid.NewGuid(),
            OrderId = orderId,
            CustomerOrderItemId = customerOrderItemId,
            Order = order,
            Quantity = 2,
            UnitPrice = 25,
            IsCancelled = false
        };

        // Only this item exists in DB query for this order
        var orderItems = new List<OrderItem> { orderItem };

        var mockItemRepo = new Mock<IRepository<OrderItem>>();
        mockItemRepo.Setup(x => x.Query()).Returns(orderItems.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderItems).Returns(mockItemRepo.Object);

        var mockOrderRepo = new Mock<IRepository<Order>>();
        _mockUnitOfWork.Setup(x => x.Orders).Returns(mockOrderRepo.Object);

        var mockHistoryRepo = new Mock<IRepository<OrderStatusHistory>>();
        mockHistoryRepo
            .Setup(x => x.AddAsync(It.IsAny<OrderStatusHistory>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((OrderStatusHistory h, CancellationToken _) => h);
        _mockUnitOfWork.Setup(x => x.OrderStatusHistories).Returns(mockHistoryRepo.Object);

        var cancelDto = new CancelOrderDto { Reason = "Product is defective and not working" };

        // Act
        var result = await _controller.CancelOrderItem(customerOrderItemId, cancelDto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        orderItem.IsCancelled.Should().BeTrue();
        order.Status.Should().Be(OrderStatus.Cancelled); // Order cancelled because all items cancelled

        mockHistoryRepo.Verify(
            x => x.AddAsync(It.IsAny<OrderStatusHistory>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }
}
