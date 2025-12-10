using AutoMapper;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using MockQueryable.Moq;
using MockQueryable;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Options;
using Xunit;
using System.Threading;
using System.Linq;

namespace Talabi.Api.Tests.Unit.Controllers;

/// <summary>
/// ProductsController için unit testler
/// </summary>
public class ProductsControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly ILogger<ProductsController> _logger;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<IMapper> _mockMapper;
    private readonly Mock<ICacheService> _mockCacheService;
    private readonly Mock<IOptions<CacheOptions>> _mockCacheOptions;
    private readonly ProductsController _controller;

    public ProductsControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _logger = ControllerTestHelpers.CreateMockLogger<ProductsController>();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockMapper = new Mock<IMapper>();
        _mockCacheService = new Mock<ICacheService>();
        _mockCacheOptions = new Mock<IOptions<CacheOptions>>();
        
        // Setup default cache options
        _mockCacheOptions.Setup(x => x.Value).Returns(new CacheOptions());

        _controller = new ProductsController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object,
            _mockCacheService.Object,
            _mockCacheOptions.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetProduct_WhenProductExists_ReturnsOk()
    {
        // Arrange
        var productId = Guid.NewGuid();
        var vendorId = Guid.NewGuid();
        var product = new Product
        {
            Id = productId,
            Name = "Test Product",
            Price = 100.0m,
            VendorId = vendorId,
            Vendor = new Vendor
            {
                Id = vendorId,
                Name = "Test Vendor",
                IsActive = true
            }
        };

        var productDto = new ProductDto
        {
            Id = productId,
            Name = "Test Product",
            Price = 100.0m
        };

        var products = new List<Product> { product };
        var mockQueryable = products.AsEnumerable().BuildMock();

        var mockRepository = new Mock<IRepository<Product>>();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);

        _mockUnitOfWork.Setup(x => x.Products).Returns(mockRepository.Object);
        _mockMapper.Setup(x => x.Map<ProductDto>(It.IsAny<Product>())).Returns(productDto);

        // Act
        var result = await _controller.GetProduct(productId);

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<ProductDto>>().Subject;
        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();
        apiResponse.Data!.Name.Should().Be("Test Product");
    }

    [Fact]
    public async Task GetProduct_WhenProductNotFound_ReturnsNotFound()
    {
        // Arrange
        var productId = Guid.NewGuid();
        var products = new List<Product>(); // Empty list
        var mockQueryable = products.AsEnumerable().BuildMock();

        var mockRepository = new Mock<IRepository<Product>>();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);

        _mockUnitOfWork.Setup(x => x.Products).Returns(mockRepository.Object);

        // Act
        var result = await _controller.GetProduct(productId);

        // Assert
        result.Should().NotBeNull();
        var notFoundResult = result.Result.Should().BeOfType<NotFoundObjectResult>().Subject;
        var apiResponse = notFoundResult.Value.Should().BeOfType<ApiResponse<ProductDto>>().Subject;
        apiResponse.Success.Should().BeFalse();
    }

    [Fact]
    public async Task GetProduct_WhenProductHasVendor_ReturnsOkWithVendorInfo()
    {
        // Arrange
        var productId = Guid.NewGuid();
        var vendorId = Guid.NewGuid();
        var product = new Product
        {
            Id = productId,
            Name = "Test Product",
            Price = 100.0m,
            VendorId = vendorId,
            Vendor = new Vendor
            {
                Id = vendorId,
                Name = "Test Vendor",
                IsActive = true
            }
        };

        var productDto = new ProductDto
        {
            Id = productId,
            Name = "Test Product",
            Price = 100.0m
        };

        var products = new List<Product> { product };
        var mockQueryable = products.AsEnumerable().BuildMock();

        var mockRepository = new Mock<IRepository<Product>>();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);

        _mockUnitOfWork.Setup(x => x.Products).Returns(mockRepository.Object);
        _mockMapper.Setup(x => x.Map<ProductDto>(It.IsAny<Product>())).Returns(productDto);

        // Act
        var result = await _controller.GetProduct(productId);

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<ProductDto>>().Subject;
        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();
    }
}

