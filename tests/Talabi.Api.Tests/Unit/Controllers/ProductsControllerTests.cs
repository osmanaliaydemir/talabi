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

        var mockOrderItemsRepo = new Mock<IRepository<OrderItem>>();
        mockOrderItemsRepo.Setup(x => x.Query()).Returns(new List<OrderItem>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderItems).Returns(mockOrderItemsRepo.Object);

        var mockReviewsRepo = new Mock<IRepository<Review>>();
        mockReviewsRepo.Setup(x => x.Query()).Returns(new List<Review>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Reviews).Returns(mockReviewsRepo.Object);

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

        var mockOrderItemsRepo = new Mock<IRepository<OrderItem>>();
        mockOrderItemsRepo.Setup(x => x.Query()).Returns(new List<OrderItem>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderItems).Returns(mockOrderItemsRepo.Object);

        var mockReviewsRepo = new Mock<IRepository<Review>>();
        mockReviewsRepo.Setup(x => x.Query()).Returns(new List<Review>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Reviews).Returns(mockReviewsRepo.Object);

        // Act
        var result = await _controller.GetProduct(productId);

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<ProductDto>>().Subject;
        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();
    }

    [Fact]
    public async Task Search_WhenCalled_ReturnsPagedProducts()
    {
        // Arrange
        var request = new ProductSearchRequestDto
        {
            Query = "Test",
            Page = 1,
            PageSize = 10,
            UserLatitude = 41.0,
            UserLongitude = 29.0
        };

        var vendorInRadius = new Vendor { Id = Guid.NewGuid(), IsActive = true, Latitude = 41.0, Longitude = 29.0, DeliveryRadiusInKm = 50 };
        var products = new List<Product>
        {
            new Product
            {
                Id = Guid.NewGuid(), Name = "Test Product 1", Price = 10, VendorId = vendorInRadius.Id, Vendor = vendorInRadius, IsAvailable = true
            },
            new Product
            {
                Id = Guid.NewGuid(), Name = "Other Product", Price = 20, VendorId = vendorInRadius.Id, Vendor = vendorInRadius, IsAvailable = true
            }
        };

        var mockRepo = new Mock<IRepository<Product>>();
        mockRepo.Setup(x => x.Query()).Returns(products.BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockRepo.Object);

        var mockVendorRepo = new Mock<IRepository<Vendor>>();
        mockVendorRepo.Setup(x => x.Query()).Returns(new List<Vendor> { vendorInRadius }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockVendorRepo.Object);

        var mockOrderItemsRepo = new Mock<IRepository<OrderItem>>();
        mockOrderItemsRepo.Setup(x => x.Query()).Returns(new List<OrderItem>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderItems).Returns(mockOrderItemsRepo.Object);

        var mockReviewsRepo = new Mock<IRepository<Review>>();
        mockReviewsRepo.Setup(x => x.Query()).Returns(new List<Review>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Reviews).Returns(mockReviewsRepo.Object);

        // Act
        var result = await _controller.Search(request);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;

        apiResponse.Data!.Items.Should().Contain(p => p.Name == "Test Product 1");
        apiResponse.Data!.Items.Should().NotContain(p => p.Name == "Other Product");
    }

    [Fact]
    public async Task GetCategories_WhenCalled_ReturnsCategoriesFromCacheOrDb()
    {
        // Arrange
        var vendorInRadius = new Vendor { Id = Guid.NewGuid(), IsActive = true, Latitude = 41.0, Longitude = 29.0, DeliveryRadiusInKm = 50 };
        var categoryId = Guid.NewGuid();
        var categories = new List<Category>
        {
            new Category { Id = categoryId, Name = "Electronics", DisplayOrder = 1, Translations = new List<CategoryTranslation>() }
        };

        var mockRepo = new Mock<IRepository<Category>>();
        mockRepo.Setup(x => x.Query()).Returns(categories.BuildMock());
        _mockUnitOfWork.Setup(x => x.Categories).Returns(mockRepo.Object);

        // Categories endpoint depends on products-in-radius and vendor-in-radius
        var mockVendorRepo = new Mock<IRepository<Vendor>>();
        mockVendorRepo.Setup(x => x.Query()).Returns(new List<Vendor> { vendorInRadius }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockVendorRepo.Object);

        var products = new List<Product>
        {
            new Product { Id = Guid.NewGuid(), VendorId = vendorInRadius.Id, IsAvailable = true, CategoryId = categoryId }
        };
        var mockProductRepo = new Mock<IRepository<Product>>();
        mockProductRepo.Setup(x => x.Query()).Returns(products.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockProductRepo.Object);

        // Mock Cache to execute callback
        _mockCacheService.Setup(x =>
                x.GetOrSetAsync(It.IsAny<string>(), It.IsAny<Func<Task<PagedResultDto<CategoryDto>?>>>(),
                    It.IsAny<int>()))
            .Returns<string, Func<Task<PagedResultDto<CategoryDto>?>>, int>((key, func, ttl) => func());

        // Act
        var result = await _controller.GetCategories(userLatitude: 41.0, userLongitude: 29.0);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<CategoryDto>>>().Subject;

        apiResponse.Data!.Items.Should().Contain(c => c.Name == "Electronics");
    }

    [Fact]
    public async Task Autocomplete_WhenQueryProvided_ReturnsMatchingProducts()
    {
        // Arrange
        var query = "Phone";
        var products = new List<Product>
        {
            new Product { Id = Guid.NewGuid(), Name = "Smart Phone", Vendor = new Vendor { IsActive = true } },
            new Product { Id = Guid.NewGuid(), Name = "Laptop", Vendor = new Vendor { IsActive = true } }
        };

        var mockRepo = new Mock<IRepository<Product>>();
        mockRepo.Setup(x => x.Query()).Returns(products.BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockRepo.Object);

        // Act
        var result = await _controller.Autocomplete(query);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<AutocompleteResultDto>>>().Subject;

        apiResponse.Data.Should().HaveCount(1);
        apiResponse.Data!.First().Name.Should().Be("Smart Phone");
    }

    [Fact]
    public async Task GetPopularProducts_WhenCalled_ReturnsProductsOrderedBySales()
    {
        // Arrange
        var vendorInRadius = new Vendor { Id = Guid.NewGuid(), IsActive = true, Latitude = 41.0, Longitude = 29.0, DeliveryRadiusInKm = 50 };
        var prod1 = new Product { Id = Guid.NewGuid(), Name = "Popular", VendorId = vendorInRadius.Id, Vendor = vendorInRadius, IsAvailable = true };
        var prod2 = new Product { Id = Guid.NewGuid(), Name = "Unpopular", VendorId = vendorInRadius.Id, Vendor = vendorInRadius, IsAvailable = true };
        var products = new List<Product> { prod1, prod2 };

        var mockProductRepo = new Mock<IRepository<Product>>();
        mockProductRepo.Setup(x => x.Query()).Returns(products.BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockProductRepo.Object);

        var mockVendorRepo = new Mock<IRepository<Vendor>>();
        mockVendorRepo.Setup(x => x.Query()).Returns(new List<Vendor> { vendorInRadius }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockVendorRepo.Object);

        // Mock OrderItems to simulate sales
        var orderItems = new List<OrderItem>
        {
            new OrderItem { ProductId = prod1.Id },
            new OrderItem { ProductId = prod1.Id }, // 2 sales
            new OrderItem { ProductId = prod2.Id } // 1 sale
        };
        var mockOrderItemRepo = new Mock<IRepository<OrderItem>>();
        mockOrderItemRepo.Setup(x => x.Query()).Returns(orderItems.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderItems).Returns(mockOrderItemRepo.Object);

        var mockReviewsRepo = new Mock<IRepository<Review>>();
        mockReviewsRepo.Setup(x => x.Query()).Returns(new List<Review>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Reviews).Returns(mockReviewsRepo.Object);

        // Mock Cache to execute callback
        _mockCacheService.Setup(x =>
                x.GetOrSetAsync(It.IsAny<string>(), It.IsAny<Func<Task<PagedResultDto<ProductDto>?>>>(),
                    It.IsAny<int>()))
            .Returns<string, Func<Task<PagedResultDto<ProductDto>?>>, int>((key, func, ttl) => func());

        // Act
        var result = await _controller.GetPopularProducts(userLatitude: 41.0, userLongitude: 29.0);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;

        // Should be ordered by sales count descending
        apiResponse.Data!.Items.First().Name.Should().Be("Popular");
    }

    [Fact]
    public async Task GetSimilarProducts_WhenCategoryMatches_ReturnsSameCategoryProducts()
    {
        // Arrange
        var categoryId = Guid.NewGuid();
        var currentProdId = Guid.NewGuid();
        var otherProdId = Guid.NewGuid();

        var currentProd = new Product
        {
            Id = currentProdId, CategoryId = categoryId, IsAvailable = true, Vendor = new Vendor { IsActive = true }
        };
        var otherProd = new Product
        {
            Id = otherProdId, CategoryId = categoryId, IsAvailable = true, Vendor = new Vendor { IsActive = true },
            Name = "Similar One"
        };

        var products = new List<Product> { currentProd, otherProd };

        var mockProductRepo = new Mock<IRepository<Product>>();
        mockProductRepo.Setup(x => x.Query()).Returns(products.BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockProductRepo.Object);

        var mockOrderItemsRepo = new Mock<IRepository<OrderItem>>();
        mockOrderItemsRepo.Setup(x => x.Query()).Returns(new List<OrderItem>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderItems).Returns(mockOrderItemsRepo.Object);

        var mockReviewsRepo = new Mock<IRepository<Review>>();
        mockReviewsRepo.Setup(x => x.Query()).Returns(new List<Review>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Reviews).Returns(mockReviewsRepo.Object);

        // Act
        var result = await _controller.GetSimilarProducts(currentProdId);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;

        apiResponse.Data!.Items.Should().Contain(p => p.Name == "Similar One");
        apiResponse.Data.Items.Should().NotContain(p => p.Id == currentProdId); // Should exclude current
    }
}
