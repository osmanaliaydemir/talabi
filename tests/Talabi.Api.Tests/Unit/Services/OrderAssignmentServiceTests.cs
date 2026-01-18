using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Moq;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Services;
using Xunit;

namespace Talabi.Api.Tests.Unit.Services;

public class OrderAssignmentServiceTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<IMapService> _mockMapService;
    private readonly OrderAssignmentService _service;

    public OrderAssignmentServiceTests()
    {
        _mockUnitOfWork = new Mock<IUnitOfWork>();
        var mockLogger = new Mock<ILogger<OrderAssignmentService>>();
        var mockNotificationService = new Mock<INotificationService>();
        var mockSignalRNotificationService = new Mock<ISignalRNotificationService>();
        var mockLocalizationService = new Mock<ILocalizationService>();
        var mockHttpContextAccessor = new Mock<IHttpContextAccessor>();
        var mockWalletService = new Mock<IWalletService>();
        _mockMapService = new Mock<IMapService>();

        _service = new OrderAssignmentService(
            _mockUnitOfWork.Object,
            mockLogger.Object,
            mockNotificationService.Object,
            mockSignalRNotificationService.Object,
            mockLocalizationService.Object,
            mockHttpContextAccessor.Object,
            mockWalletService.Object,
            _mockMapService.Object
        );
    }

    [Theory]
    [InlineData(1.5, 15.00)] // 0-2km: Base fee only
    [InlineData(3.0, 15.00 + 5.00)] // 2-5km: (3-2)*5 = 5 extra
    [InlineData(7.0, 15.00 + 15.00 + 16.00)] // 5-10km: 15 (for 2-5) + (7-5)*8 = 15+16=31 extra
    [InlineData(12.0, 15.00 + 15.00 + 40.00 + 20.00)] // 10km+: 15+40+(12-10)*10 = 75 extra
    public async Task CalculateDeliveryFee_AppliesTieredDistanceFees(double roadDistance, double expectedTotal)
    {
        // Arrange
        var vendor = new Vendor { Id = Guid.NewGuid(), Latitude = 41.0, Longitude = 29.0 };
        var deliveryAddress = new UserAddress
            { Latitude = 41.1, Longitude = 29.1 }; // Geolocation logic is mocked anyway
        var order = new Order { VendorId = vendor.Id, DeliveryAddress = deliveryAddress };
        var courier = new Courier { VehicleType = CourierVehicleType.Bicycle }; // No vehicle bonus for bicycle

        _mockUnitOfWork.Setup(u => u.Vendors.GetByIdAsync(vendor.Id, It.IsAny<CancellationToken>()))
            .ReturnsAsync(vendor);
        _mockMapService.Setup(m =>
                m.GetRoadDistanceAsync(It.IsAny<double>(), It.IsAny<double>(), It.IsAny<double>(), It.IsAny<double>()))
            .ReturnsAsync(roadDistance);

        // Act
        var result = await _service.CalculateDeliveryFee(order, courier);

        // Assert
        // expectedTotal = baseFee (15) + distanceBonus
        // Note: Time bonus is based on DateTime.Now, might need to be careful if test runs in evening.
        // For simplicity, let's assume it's not and check if result is close (ignoring time bonus)
        var currentHour = DateTime.Now.Hour;
        var timeBonus = (currentHour >= 18 && currentHour <= 22) ? 15.00m * 0.20m : 0;

        result.Should().Be((decimal)expectedTotal + timeBonus);
    }
}
