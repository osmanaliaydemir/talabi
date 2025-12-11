using AutoMapper;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using MockQueryable.Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

/// <summary>
/// MapController için unit testler
/// </summary>
public class MapControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly ILogger<MapController> _logger;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<IMapper> _mockMapper;
    private readonly IConfiguration _configuration;
    private readonly MapController _controller;

    public MapControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _logger = ControllerTestHelpers.CreateMockLogger<MapController>();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockMapper = new Mock<IMapper>();
        _configuration = ControllerTestHelpers.CreateMockConfiguration();

        _controller = new MapController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object,
            _configuration
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public void GetApiKey_WhenApiKeyExists_ReturnsOkWithApiKey()
    {
        // Arrange
        var config = ControllerTestHelpers.CreateMockConfiguration(new Dictionary<string, string>
        {
            { "GoogleMaps:ApiKey", "test-api-key-12345" }
        });

        var controller = new MapController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object,
            config
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };

        // Act
        var result = controller.GetApiKey();

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Should().BeOfType<ActionResult<ApiResponse<object>>>().Subject;
        var actionResult = okResult.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = actionResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();

        // Use reflection to get ApiKey property
        var dataType = apiResponse.Data?.GetType();
        if (dataType != null)
        {
            var apiKeyProperty = dataType.GetProperty("ApiKey");
            if (apiKeyProperty != null)
            {
                var apiKey = apiKeyProperty.GetValue(apiResponse.Data)?.ToString();
                apiKey.Should().Be("test-api-key-12345");
            }
        }
    }

    [Fact]
    public void GetApiKey_WhenApiKeyNotConfigured_ReturnsNotFound()
    {
        // Arrange
        var config = ControllerTestHelpers.CreateMockConfiguration(new Dictionary<string, string>
        {
            { "GoogleMaps:ApiKey", "" }
        });

        var controller = new MapController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object,
            config
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };

        // Act
        var result = controller.GetApiKey();

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Should().BeOfType<ActionResult<ApiResponse<object>>>().Subject;
        var actionResult = okResult.Result.Should().BeOfType<NotFoundObjectResult>().Subject;
        var apiResponse = actionResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;

        apiResponse.Success.Should().BeFalse();
        apiResponse.ErrorCode.Should().Be("API_KEY_NOT_CONFIGURED");
    }

    [Fact]
    public void GetApiKey_WhenConfigurationIsNull_ReturnsInternalServerError()
    {
        // Arrange
        var controller = new MapController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object,
            null! // null configuration
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };

        // Act
        var result = controller.GetApiKey();

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Should().BeOfType<ActionResult<ApiResponse<object>>>().Subject;
        var actionResult = okResult.Result.Should().BeOfType<ObjectResult>().Subject;
        actionResult.StatusCode.Should().Be(500);

        var apiResponse = actionResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.Success.Should().BeFalse();
        apiResponse.ErrorCode.Should().Be("INTERNAL_SERVER_ERROR");
    }
    [Fact]
    public async Task GetVendorsForMap_WhenCalled_ReturnsVendorsWithLocation()
    {
        // Arrange
        var vendors = new List<Vendor>
        {
            new Vendor { Id = Guid.NewGuid(), Name = "Vendor 1", Latitude = 41.0082, Longitude = 28.9784 },
            new Vendor { Id = Guid.NewGuid(), Name = "Vendor 2", Latitude = 41.0122, Longitude = 28.9764 }
        };

        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.Query()).Returns(vendors.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);

        _mockMapper.Setup(x => x.Map<VendorMapDto>(It.IsAny<Vendor>()))
            .Returns((Vendor v) => new VendorMapDto { Id = v.Id, Name = v.Name, Latitude = v.Latitude ?? 0, Longitude = v.Longitude ?? 0 });

        // Act
        var result = await _controller.GetVendorsForMap(null, null);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<VendorMapDto>>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().HaveCount(2);
    }

    [Fact]
    public async Task GetVendorsForMap_WhenUserLocationProvided_ReturnsSortedVendorsWithDistance()
    {
        // Arrange
        var userLat = 41.0000;
        var userLon = 28.0000;

        // Vendor 1 is closer, Vendor 2 is farther (roughly)
        var vendors = new List<Vendor>
        {
            new Vendor { Id = Guid.NewGuid(), Name = "Far Vendor", Latitude = 42.0000, Longitude = 29.0000 },
            new Vendor { Id = Guid.NewGuid(), Name = "Near Vendor", Latitude = 41.0100, Longitude = 28.0100 }
        };

        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.Query()).Returns(vendors.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);

        _mockMapper.Setup(x => x.Map<VendorMapDto>(It.IsAny<Vendor>()))
            .Returns((Vendor v) => new VendorMapDto { Id = v.Id, Name = v.Name, Latitude = v.Latitude ?? 0, Longitude = v.Longitude ?? 0 });

        // Act
        var result = await _controller.GetVendorsForMap(userLat, userLon);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<VendorMapDto>>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data!.Should().HaveCount(2);
        apiResponse.Data![0].Name.Should().Be("Near Vendor"); // Should be first
        apiResponse.Data![1].Name.Should().Be("Far Vendor");
        apiResponse.Data![0].DistanceInKm.Should().BeGreaterThan(0);
    }

    [Fact]
    public async Task GetDeliveryTracking_WhenOrderExists_ReturnsTrackingInfo()
    {
        // Arrange
        var userId = "user123";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);
        var orderId = Guid.NewGuid();

        var order = new Order
        {
            Id = orderId,
            CustomerId = userId,
            Status = OrderStatus.OutForDelivery,
            Vendor = new Vendor { Latitude = 41.0, Longitude = 29.0, Address = "Vendor Addr" },
            DeliveryAddress = new UserAddress { Latitude = 41.1, Longitude = 29.1, FullAddress = "Delivery Addr" }
        };

        var mockOrderRepo = new Mock<IRepository<Order>>();
        mockOrderRepo.Setup(x => x.Query()).Returns(new List<Order> { order }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Orders).Returns(mockOrderRepo.Object);

        // Setup OrderCourier query (empty or valid)
        var mockCourierRepo = new Mock<IRepository<OrderCourier>>();
        mockCourierRepo.Setup(x => x.Query()).Returns(new List<OrderCourier>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderCouriers).Returns(mockCourierRepo.Object);

        // Act
        var result = await _controller.GetDeliveryTracking(orderId);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<DeliveryTrackingDto>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data!.OrderId.Should().Be(orderId);
        apiResponse.Data!.VendorAddress.Should().Be("Vendor Addr");
    }
}

