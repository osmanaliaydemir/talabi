using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MockQueryable.Moq;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Core.Options;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class VendorsControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<ICacheService> _mockCacheService;
    private readonly Mock<IOptions<CacheOptions>> _mockCacheOptions;
    private readonly Mock<ILogger<VendorsController>> _logger;
    private readonly VendorsController _controller;

    public VendorsControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockCacheService = new Mock<ICacheService>();

        // Setup default CacheOptions
        var defaultCacheOptions = new CacheOptions { CitiesKeyPrefix = "test_cities", CitiesCacheTTLMinutes = 60 };
        _mockCacheOptions = new Mock<IOptions<CacheOptions>>();
        _mockCacheOptions.Setup(x => x.Value).Returns(defaultCacheOptions);

        _logger = new Mock<ILogger<VendorsController>>();

        _controller = new VendorsController(
            _mockUnitOfWork.Object,
            _logger.Object,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockCacheService.Object,
            _mockCacheOptions.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetVendors_WhenCalled_ReturnsPagedVendors()
    {
        // Arrange
        var vendors = new List<Vendor>
        {
            new Vendor { Id = Guid.NewGuid(), Name = "Vendor A", IsActive = true, Type = VendorType.Restaurant, Latitude = 41.0, Longitude = 29.0, DeliveryRadiusInKm = 50 },
            new Vendor { Id = Guid.NewGuid(), Name = "Vendor B", IsActive = true, Type = VendorType.Market, Latitude = 41.01, Longitude = 29.01, DeliveryRadiusInKm = 50 }
        };

        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.Query()).Returns(vendors.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetVendors(userLatitude: 41.0, userLongitude: 29.0);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<VendorDto>>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data!.Items.Should().HaveCount(2);
        apiResponse.Data!.TotalCount.Should().Be(2);
    }

    [Fact]
    public async Task GetVendors_WhenFilteredByType_ReturnsFilteredVendors()
    {
        // Arrange
        var vendors = new List<Vendor>
        {
            new Vendor { Id = Guid.NewGuid(), Name = "Vendor A", IsActive = true, Type = VendorType.Restaurant, Latitude = 41.0, Longitude = 29.0, DeliveryRadiusInKm = 50 },
            new Vendor { Id = Guid.NewGuid(), Name = "Vendor B", IsActive = true, Type = VendorType.Market, Latitude = 41.01, Longitude = 29.01, DeliveryRadiusInKm = 50 }
        };

        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.Query()).Returns(vendors.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetVendors(vendorType: VendorType.Restaurant, userLatitude: 41.0, userLongitude: 29.0);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<VendorDto>>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data!.Items.Should().HaveCount(1);
        apiResponse.Data!.Items.First().Type.Should().Be(VendorType.Restaurant);
    }

    [Fact]
    public async Task GetProductsByVendor_WhenVendorExists_ReturnsProducts()
    {
        // Arrange
        var vendorId = Guid.NewGuid();
        var vendor = new Vendor { Id = vendorId, Name = "Test Vendor", IsActive = true };
        var products = new List<Product>
        {
            new Product { Id = Guid.NewGuid(), VendorId = vendorId, Name = "Product 1", Price = 10 },
            new Product { Id = Guid.NewGuid(), VendorId = vendorId, Name = "Product 2", Price = 20 }
        };

        var mockVendorRepo = new Mock<IRepository<Vendor>>();
        mockVendorRepo.Setup(x => x.Query()).Returns(new List<Vendor> { vendor }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockVendorRepo.Object);

        var mockProductRepo = new Mock<IRepository<Product>>();
        mockProductRepo.Setup(x => x.Query()).Returns(products.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockProductRepo.Object);

        // Mock OrderItems and Reviews for ProductDto projection
        var mockOrderItemsRepo = new Mock<IRepository<OrderItem>>();
        mockOrderItemsRepo.Setup(x => x.Query()).Returns(new List<OrderItem>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderItems).Returns(mockOrderItemsRepo.Object);

        var mockReviewsRepo = new Mock<IRepository<Review>>();
        mockReviewsRepo.Setup(x => x.Query()).Returns(new List<Review>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Reviews).Returns(mockReviewsRepo.Object);

        // Act
        var result = await _controller.GetProductsByVendor(vendorId);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data!.Items.Should().HaveCount(2);
    }

    [Fact]
    public async Task CreateVendor_WhenAuthorized_CreatesVendor()
    {
        // Arrange
        _mockUserContextService.Setup(x => x.GetUserId()).Returns("user123");
        var dto = new CreateVendorDto { Name = "New Vendor", Address = "123 St." };

        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.AddAsync(It.IsAny<Vendor>(), It.IsAny<System.Threading.CancellationToken>()))
            .ReturnsAsync(new Vendor { Id = Guid.NewGuid(), Name = dto.Name, OwnerId = "user123" });

        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);
        _mockUnitOfWork.Setup(x => x.SaveChangesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(1);

        // Act
        var result = await _controller.CreateVendor(dto);

        // Assert
        var createdResult = result.Result.Should().BeOfType<CreatedAtActionResult>().Subject;
        var apiResponse = createdResult.Value.Should().BeOfType<ApiResponse<VendorDto>>().Subject;

        apiResponse.Data!.Name.Should().Be("New Vendor");
        mockRepo.Verify(x => x.AddAsync(It.IsAny<Vendor>(), It.IsAny<System.Threading.CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task Search_WhenQueryProvided_ReturnsMatchingVendors()
    {
        // Arrange
        var vendors = new List<Vendor>
        {
            new Vendor
            {
                Id = Guid.NewGuid(), Name = "Pizza Place", IsActive = true, Address = "Pizza St",
                Orders = new List<Order>(),
                Latitude = 41.0, Longitude = 29.0, DeliveryRadiusInKm = 50
            },
            new Vendor
            {
                Id = Guid.NewGuid(), Name = "Burger Joint", IsActive = true, Address = "Second St",
                Orders = new List<Order>(),
                Latitude = 41.01, Longitude = 29.01, DeliveryRadiusInKm = 50
            }
        };

        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.Query()).Returns(vendors.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);

        var request = new VendorSearchRequestDto { Query = "Pizza", UserLatitude = 41.0, UserLongitude = 29.0 };

        // Act
        var result = await _controller.Search(request);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<VendorDto>>>().Subject;

        apiResponse.Data!.Items.Should().HaveCount(1);
        apiResponse.Data!.Items.First().Name.Should().Be("Pizza Place");
    }

    [Fact]
    public async Task GetCities_ReturnsUniqueCities()
    {
        // Arrange
        var vendors = new List<Vendor>
        {
            new Vendor { Id = Guid.NewGuid(), City = "Istanbul", IsActive = true },
            new Vendor { Id = Guid.NewGuid(), City = "Ankara", IsActive = true },
            new Vendor { Id = Guid.NewGuid(), City = "Istanbul", IsActive = true } // Duplicate
        };

        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.Query()).Returns(vendors.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);

        // Mock CacheService to execute the factory
        _mockCacheService.Setup(x =>
                x.GetOrSetAsync(It.IsAny<string>(), It.IsAny<Func<Task<List<string>?>>>(), It.IsAny<int>()))
            .Returns<string, Func<Task<List<string>?>>, int>(async (key, factory, ttl) => await factory());

        // Act
        var result = await _controller.GetCities();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<string>>>().Subject;

        apiResponse.Data!.Items.Should().HaveCount(2);
        apiResponse.Data.Items.Should().Contain("Istanbul");
        apiResponse.Data.Items.Should().Contain("Ankara");
    }

    [Fact]
    public async Task Autocomplete_WhenQueryProvided_ReturnsSuggestions()
    {
        // Arrange
        var vendors = new List<Vendor>
        {
            new Vendor { Id = Guid.NewGuid(), Name = "Starbucks", IsActive = true },
            new Vendor { Id = Guid.NewGuid(), Name = "Star Market", IsActive = true },
            new Vendor { Id = Guid.NewGuid(), Name = "Other", IsActive = true }
        };

        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.Query()).Returns(vendors.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);

        // Act
        var result = await _controller.Autocomplete("Star");

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<AutocompleteResultDto>>>().Subject;

        apiResponse.Data!.Should().HaveCount(2);
    }
}
