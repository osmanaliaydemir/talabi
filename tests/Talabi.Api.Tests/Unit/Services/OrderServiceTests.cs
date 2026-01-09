using System.Globalization;
using FluentAssertions;
using MockQueryable.Moq;
using Moq;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Models;
using Talabi.Infrastructure.Services;
using Xunit;

namespace Talabi.Api.Tests.Unit.Services;

public class OrderServiceTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<IMapService> _mockMapService;
    private readonly OrderService _service;
    private readonly CultureInfo _culture = new("tr-TR");

    public OrderServiceTests()
    {
        _mockUnitOfWork = new Mock<IUnitOfWork>();
        var mockLocalizationService = new Mock<ILocalizationService>();
        var mockNotificationService = new Mock<INotificationService>();
        var mockRuleValidatorService = new Mock<IRuleValidatorService>();
        var mockSystemSettingsService = new Mock<ISystemSettingsService>();
        _mockMapService = new Mock<IMapService>();

        _service = new OrderService(
            _mockUnitOfWork.Object,
            mockLocalizationService.Object,
            mockNotificationService.Object,
            mockRuleValidatorService.Object,
            mockSystemSettingsService.Object,
            _mockMapService.Object
        );

        mockLocalizationService.Setup(l =>
                l.GetLocalizedString(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CultureInfo>(),
                    It.IsAny<object[]>()))
            .Returns("Localized Error");

        // Mock empty orders list for IsFirstOrder check
        var orders = new List<Order>().AsQueryable().BuildMock();
        _mockUnitOfWork.Setup(u => u.Orders.Query()).Returns(orders);

        // Mock empty order items for unique ID generation
        var orderItems = new List<OrderItem>().AsQueryable().BuildMock();
        _mockUnitOfWork.Setup(u => u.OrderItems.Query()).Returns(orderItems);

        // Mock RuleValidator
        string? reason = null;
        mockRuleValidatorService.Setup(r =>
                r.ValidateCampaign(It.IsAny<Campaign>(), It.IsAny<RuleValidationContext>(), out reason))
            .Returns(true);
        mockRuleValidatorService.Setup(r =>
                r.ValidateCoupon(It.IsAny<Coupon>(), It.IsAny<RuleValidationContext>(), out reason))
            .Returns(true);
    }

    [Fact]
    public async Task CreateOrderAsync_ThrowsException_WhenDistanceExceedsRadius()
    {
        // Arrange
        var vendorId = Guid.NewGuid();
        var userId = "user-1";
        var addressId = Guid.NewGuid();

        var vendor = new Vendor { Id = vendorId, DeliveryRadiusInKm = 5, Latitude = 41.0, Longitude = 29.0 };
        var userAddress = new UserAddress
            { Id = addressId, UserId = userId, Latitude = 41.1, Longitude = 29.2 }; // Roughly 20km away

        _mockUnitOfWork.Setup(u => u.Vendors.GetByIdAsync(vendorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(vendor);

        _mockUnitOfWork.Setup(u => u.UserAddresses.GetByIdAsync(addressId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(userAddress);

        // Mock product
        var product = new Product { Id = Guid.NewGuid(), Price = 100, VendorId = vendorId };
        _mockUnitOfWork.Setup(u => u.Products.GetByIdAsync(product.Id, It.IsAny<CancellationToken>()))
            .ReturnsAsync(product);

        _mockMapService.Setup(m =>
                m.GetRoadDistanceAsync(It.IsAny<double>(), It.IsAny<double>(), It.IsAny<double>(), It.IsAny<double>()))
            .ReturnsAsync(7.5); // Road distance is 7.5km, radius is 5km

        var dto = new CreateOrderDto
        {
            VendorId = vendorId,
            DeliveryAddressId = addressId,
            Items = new List<OrderItemDto> { new() { ProductId = product.Id, Quantity = 1 } }
        };

        // Act
        Func<Task> act = async () => await _service.CreateOrderAsync(dto, userId, _culture);

        // Assert
        await act.Should().ThrowAsync<InvalidOperationException>().WithMessage("Localized Error");
    }

    [Fact]
    public async Task CreateOrderAsync_ThrowsException_WhenMinimumOrderAmountNotMet_ForDistance()
    {
        // Arrange
        var vendorId = Guid.NewGuid();
        var userId = "user-1";
        var addressId = Guid.NewGuid();

        var vendor = new Vendor
            { Id = vendorId, DeliveryRadiusInKm = 10, Latitude = 41.0, Longitude = 29.0, MinimumOrderAmount = 50 };
        var userAddress = new UserAddress { Id = addressId, UserId = userId, Latitude = 41.05, Longitude = 29.05 };

        _mockUnitOfWork.Setup(u => u.Vendors.GetByIdAsync(vendorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(vendor);

        _mockUnitOfWork.Setup(u => u.UserAddresses.GetByIdAsync(addressId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(userAddress);

        _mockMapService.Setup(m =>
                m.GetRoadDistanceAsync(It.IsAny<double>(), It.IsAny<double>(), It.IsAny<double>(), It.IsAny<double>()))
            .ReturnsAsync(6.0); // 6km distance requires min ₺300 (based on logic in OrderService)

        // Mock product to calculate total
        var product = new Product { Id = Guid.NewGuid(), Price = 100, VendorId = vendorId };
        _mockUnitOfWork.Setup(u => u.Products.GetByIdAsync(product.Id, It.IsAny<CancellationToken>()))
            .ReturnsAsync(product);

        var dto = new CreateOrderDto
        {
            VendorId = vendorId,
            DeliveryAddressId = addressId,
            Items = new List<OrderItemDto>
                { new() { ProductId = product.Id, Quantity = 1 } } // Total 100, but 6km needs 300
        };

        // Act
        Func<Task> act = async () => await _service.CreateOrderAsync(dto, userId, _culture);

        // Assert
        await act.Should().ThrowAsync<InvalidOperationException>().WithMessage("Localized Error");
    }

    [Fact]
    public async Task CalculateOrderAsync_UsesRoadDistance_WhenAvailable()
    {
        // Arrange
        var vendorId = Guid.NewGuid();
        var addressId = Guid.NewGuid();

        var vendor = new Vendor { Id = vendorId, Latitude = 41.0, Longitude = 29.0, DeliveryRadiusInKm = 20 };
        var userAddress = new UserAddress { Id = addressId, Latitude = 41.05, Longitude = 29.05 };

        _mockUnitOfWork.Setup(u => u.Vendors.GetByIdAsync(vendorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(vendor);

        _mockUnitOfWork.Setup(u => u.UserAddresses.GetByIdAsync(addressId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(userAddress);

        _mockMapService.Setup(m =>
                m.GetRoadDistanceAsync(It.IsAny<double>(), It.IsAny<double>(), It.IsAny<double>(), It.IsAny<double>()))
            .ReturnsAsync(12.0); // Road distance

        // Mock product
        var product = new Product { Id = Guid.NewGuid(), Price = 500, VendorId = vendorId }; // 500 > 300 min amount
        _mockUnitOfWork.Setup(u => u.Products.GetByIdAsync(product.Id, It.IsAny<CancellationToken>()))
            .ReturnsAsync(product);

        var request = new CalculateOrderDto
        {
            VendorId = vendorId,
            DeliveryAddressId = addressId,
            Items = new List<OrderItemDto> { new() { ProductId = product.Id, Quantity = 1 } }
        };

        // Act
        var result = await _service.CalculateOrderAsync(request, "user-1", _culture);

        // Assert
        result.Should().NotBeNull();
        _mockMapService.Verify(
            m => m.GetRoadDistanceAsync(It.IsAny<double>(), It.IsAny<double>(), It.IsAny<double>(), It.IsAny<double>()),
            Times.Once);
    }
}
