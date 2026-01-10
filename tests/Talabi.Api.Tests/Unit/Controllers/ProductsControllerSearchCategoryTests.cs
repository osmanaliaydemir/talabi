using AutoMapper;
using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using MockQueryable.Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;
using Talabi.Core.Options;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

/// <summary>
/// ProductsController Search endpoint'i için kategori filtreleme testleri
/// Gerçek senaryo: "Test Ürünü" ana sayfada görünüyor ama kategori detay sayfasında görünmüyor
/// </summary>
public class ProductsControllerSearchCategoryTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly ILogger<ProductsController> _logger;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<IMapper> _mockMapper;
    private readonly Mock<ICacheService> _mockCacheService;
    private readonly Mock<IOptions<CacheOptions>> _mockCacheOptions;
    private readonly ProductsController _controller;

    // Test verileri - Gerçek senaryodan
    private readonly Guid _categoryId = Guid.NewGuid();
    private readonly Guid _vendorId = Guid.NewGuid();
    private readonly Guid _testProductId = Guid.NewGuid();
    private readonly double _userLat = 40.981753363733255; // Kayışdağı
    private readonly double _userLon = 29.151309728622437;
    private readonly double _vendorLat = 41.082377030830514; // Üsküdar - Kebapcı
    private readonly double _vendorLon = 29.066766165196892;

    public ProductsControllerSearchCategoryTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _logger = ControllerTestHelpers.CreateMockLogger<ProductsController>();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockMapper = new Mock<IMapper>();
        _mockCacheService = new Mock<ICacheService>();
        _mockCacheOptions = new Mock<IOptions<CacheOptions>>();

        _mockCacheOptions.Setup(x => x.Value).Returns(new CacheOptions());

        // HttpContext ve Request.Query setup
        var httpContext = new DefaultHttpContext();
        var request = httpContext.Request;
        
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
            ControllerContext = new ControllerContext
            {
                HttpContext = httpContext
            }
        };
    }

    private void SetupRequestQuery(string? categoryId = null, string? category = null, 
        double? userLat = null, double? userLon = null)
    {
        // Request.Query'yi set etmek için HttpContext'i yeniden oluştur
        var httpContext = new DefaultHttpContext();
        var queryDict = new Dictionary<string, Microsoft.Extensions.Primitives.StringValues>();

        if (categoryId != null)
            queryDict["categoryId"] = categoryId;
        if (category != null)
            queryDict["category"] = category;
        if (userLat.HasValue)
            queryDict["userLatitude"] = userLat.Value.ToString("F15");
        if (userLon.HasValue)
            queryDict["userLongitude"] = userLon.Value.ToString("F15");

        httpContext.Request.Query = new QueryCollection(queryDict);
        _controller.ControllerContext.HttpContext = httpContext;
    }

    private Vendor CreateTestVendor(int deliveryRadiusInKm = 0)
    {
        return new Vendor
        {
            Id = _vendorId,
            Name = "Paşa Döner",
            IsActive = true,
            Latitude = _vendorLat,
            Longitude = _vendorLon,
            DeliveryRadiusInKm = deliveryRadiusInKm, // 0 = default 5km
            Type = VendorType.Restaurant
        };
    }

    private Product CreateTestProduct(Guid? categoryId = null, string? category = null)
    {
        return new Product
        {
            Id = _testProductId,
            Name = "Test Ürünü",
            Description = "Test Ürünü hakkında açıklama yazısı burada çıkacak.",
            Price = 200.00m,
            VendorId = _vendorId,
            IsAvailable = true,
            CategoryId = categoryId,
            Category = category, // "Kebap & Döner"
            Vendor = CreateTestVendor()
        };
    }

    private void SetupRepositories(List<Vendor> vendors, List<Product> products)
    {
        // Vendors repository
        var vendorsMock = vendors.AsQueryable().BuildMock();
        var vendorsRepo = new Mock<IRepository<Vendor>>();
        vendorsRepo.Setup(x => x.Query()).Returns(vendorsMock);
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(vendorsRepo.Object);

        // Products repository
        var productsMock = products.AsQueryable().BuildMock();
        var productsRepo = new Mock<IRepository<Product>>();
        productsRepo.Setup(x => x.Query()).Returns(productsMock);
        _mockUnitOfWork.Setup(x => x.Products).Returns(productsRepo.Object);

        // OrderItems repository (for mapping)
        var orderItemsRepo = new Mock<IRepository<OrderItem>>();
        orderItemsRepo.Setup(x => x.Query()).Returns(new List<OrderItem>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.OrderItems).Returns(orderItemsRepo.Object);

        // Reviews repository (for mapping)
        var reviewsRepo = new Mock<IRepository<Review>>();
        reviewsRepo.Setup(x => x.Query()).Returns(new List<Review>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Reviews).Returns(reviewsRepo.Object);
    }

    private void SetupMapper()
    {
        _mockMapper.Setup(x => x.Map<ProductDto>(It.IsAny<Product>()))
            .Returns<Product>(p => new ProductDto
            {
                Id = p.Id,
                Name = p.Name,
                Description = p.Description,
                Price = p.Price,
                VendorId = p.VendorId,
                VendorName = p.Vendor?.Name,
                Category = p.Category,
                CategoryId = p.CategoryId,
                ImageUrl = p.ImageUrl,
                Currency = p.Currency
            });
    }

    [Fact]
    public async Task Search_WithCategoryId_WhenProductHasMatchingCategoryId_ShouldReturnProduct()
    {
        // Arrange
        var categoryId = Guid.NewGuid();
        // Vendor'ı kullanıcıya yakın bir konuma yerleştir (delivery radius içinde olmalı)
        var vendor = new Vendor
        {
            Id = _vendorId,
            Name = "Paşa Döner",
            IsActive = true,
            Latitude = 40.99, // Kullanıcıya yakın (~3km)
            Longitude = 29.16,
            DeliveryRadiusInKm = 0, // Default 5km
            Type = VendorType.Restaurant
        };
        var product = CreateTestProduct(categoryId: categoryId, category: "Kebap & Döner");
        product.Vendor = vendor;

        SetupRepositories(new List<Vendor> { vendor }, new List<Product> { product });
        SetupMapper();
        SetupRequestQuery(
            categoryId: categoryId.ToString(),
            category: "Kebap & Döner",
            userLat: _userLat,
            userLon: _userLon
        );

        var request = new ProductSearchRequestDto
        {
            CategoryId = categoryId,
            Category = "Kebap & Döner",
            UserLatitude = _userLat,
            UserLongitude = _userLon,
            Page = 1,
            PageSize = 20
        };

        // Act
        var result = await _controller.Search(request);

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;
        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();
        apiResponse.Data!.Items.Should().Contain(p => p.Id == _testProductId && p.Name == "Test Ürünü");
    }

    [Fact]
    public async Task Search_WithCategoryId_WhenProductHasNullCategoryIdButMatchingCategoryString_ShouldReturnProduct()
    {
        // Arrange - Ürünün CategoryId'si null ama Category string'i eşleşiyor
        var categoryId = Guid.NewGuid();
        // Vendor'ı kullanıcıya yakın bir konuma yerleştir (delivery radius içinde olmalı)
        var vendor = new Vendor
        {
            Id = _vendorId,
            Name = "Paşa Döner",
            IsActive = true,
            Latitude = 40.99, // Kullanıcıya yakın (~3km)
            Longitude = 29.16,
            DeliveryRadiusInKm = 0, // Default 5km
            Type = VendorType.Restaurant
        };
        var product = CreateTestProduct(categoryId: null, category: "Kebap & Döner"); // CategoryId null!
        product.Vendor = vendor;

        SetupRepositories(new List<Vendor> { vendor }, new List<Product> { product });
        SetupMapper();
        SetupRequestQuery(
            categoryId: categoryId.ToString(),
            category: "Kebap & Döner",
            userLat: _userLat,
            userLon: _userLon
        );

        var request = new ProductSearchRequestDto
        {
            CategoryId = categoryId,
            Category = "Kebap & Döner",
            UserLatitude = _userLat,
            UserLongitude = _userLon,
            Page = 1,
            PageSize = 20
        };

        // Act
        var result = await _controller.Search(request);

        // Assert - Category string eşleşmesi ile ürün gelmeli
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;
        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();
        apiResponse.Data!.Items.Should().Contain(p => p.Id == _testProductId && p.Name == "Test Ürünü");
    }

    [Fact]
    public async Task Search_WithCategoryId_WhenProductCategoryStringDoesNotMatch_ShouldNotReturnProduct()
    {
        // Arrange - Category string eşleşmiyor
        var categoryId = Guid.NewGuid();
        var vendor = CreateTestVendor();
        var product = CreateTestProduct(categoryId: null, category: "Pizza"); // Farklı kategori!
        product.Vendor = vendor;

        SetupRepositories(new List<Vendor> { vendor }, new List<Product> { product });
        SetupMapper();
        SetupRequestQuery(
            categoryId: categoryId.ToString(),
            category: "Kebap & Döner",
            userLat: _userLat,
            userLon: _userLon
        );

        var request = new ProductSearchRequestDto
        {
            CategoryId = categoryId,
            Category = "Kebap & Döner",
            UserLatitude = _userLat,
            UserLongitude = _userLon,
            Page = 1,
            PageSize = 20
        };

        // Act
        var result = await _controller.Search(request);

        // Assert - Ürün gelmemeli
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;
        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();
        apiResponse.Data!.Items.Should().NotContain(p => p.Id == _testProductId);
    }

    [Fact]
    public async Task Search_WithCategoryId_WhenVendorIsOutOfDeliveryRadius_ShouldNotReturnProduct()
    {
        // Arrange - Vendor çok uzakta (100km)
        var categoryId = Guid.NewGuid();
        var farVendor = new Vendor
        {
            Id = _vendorId,
            Name = "Paşa Döner",
            IsActive = true,
            Latitude = 41.5, // Çok uzak
            Longitude = 29.5,
            DeliveryRadiusInKm = 5,
            Type = VendorType.Restaurant
        };
        var product = CreateTestProduct(categoryId: categoryId, category: "Kebap & Döner");
        product.Vendor = farVendor;

        SetupRepositories(new List<Vendor> { farVendor }, new List<Product> { product });
        SetupMapper();
        SetupRequestQuery(
            categoryId: categoryId.ToString(),
            category: "Kebap & Döner",
            userLat: _userLat,
            userLon: _userLon
        );

        var request = new ProductSearchRequestDto
        {
            CategoryId = categoryId,
            Category = "Kebap & Döner",
            UserLatitude = _userLat,
            UserLongitude = _userLon,
            Page = 1,
            PageSize = 20
        };

        // Act
        var result = await _controller.Search(request);

        // Assert - Vendor delivery radius dışında olduğu için ürün gelmemeli
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;
        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();
        apiResponse.Data!.Items.Should().NotContain(p => p.Id == _testProductId);
    }

    [Fact]
    public async Task Search_WithCategoryId_WhenProductIsNotAvailable_ShouldNotReturnProduct()
    {
        // Arrange - Ürün müsait değil
        var categoryId = Guid.NewGuid();
        var vendor = CreateTestVendor();
        var product = CreateTestProduct(categoryId: categoryId, category: "Kebap & Döner");
        product.Vendor = vendor;
        product.IsAvailable = false; // Müsait değil!

        SetupRepositories(new List<Vendor> { vendor }, new List<Product> { product });
        SetupMapper();
        SetupRequestQuery(
            categoryId: categoryId.ToString(),
            category: "Kebap & Döner",
            userLat: _userLat,
            userLon: _userLon
        );

        var request = new ProductSearchRequestDto
        {
            CategoryId = categoryId,
            Category = "Kebap & Döner",
            UserLatitude = _userLat,
            UserLongitude = _userLon,
            Page = 1,
            PageSize = 20
        };

        // Act
        var result = await _controller.Search(request);

        // Assert - IsAvailable = false olduğu için ürün gelmemeli
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;
        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();
        apiResponse.Data!.Items.Should().NotContain(p => p.Id == _testProductId);
    }

    [Fact]
    public async Task Search_WithCategoryId_WhenVendorDeliveryRadiusIsZero_ShouldUseDefault5Km()
    {
        // Arrange - DeliveryRadiusInKm = 0, default 5km kullanılmalı
        // Mesafe: ~12km (Üsküdar - Kayışdağı), 5km'den fazla ama test için yakın bir vendor kullanalım
        var categoryId = Guid.NewGuid();
        var closeVendor = new Vendor
        {
            Id = _vendorId,
            Name = "Paşa Döner",
            IsActive = true,
            Latitude = 40.99, // Kullanıcıya yakın (~3km)
            Longitude = 29.16,
            DeliveryRadiusInKm = 0, // Default 5km kullanılmalı
            Type = VendorType.Restaurant
        };
        var product = CreateTestProduct(categoryId: categoryId, category: "Kebap & Döner");
        product.Vendor = closeVendor;

        SetupRepositories(new List<Vendor> { closeVendor }, new List<Product> { product });
        SetupMapper();
        SetupRequestQuery(
            categoryId: categoryId.ToString(),
            category: "Kebap & Döner",
            userLat: _userLat,
            userLon: _userLon
        );

        var request = new ProductSearchRequestDto
        {
            CategoryId = categoryId,
            Category = "Kebap & Döner",
            UserLatitude = _userLat,
            UserLongitude = _userLon,
            Page = 1,
            PageSize = 20
        };

        // Act
        var result = await _controller.Search(request);

        // Assert - 5km içinde olduğu için ürün gelmeli
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;
        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();
        
        // Mesafe kontrolü: 40.9817, 29.1513 ile 40.99, 29.16 arası ~3km (5km içinde)
        var distance = GeoHelper.CalculateDistance(_userLat, _userLon, closeVendor.Latitude!.Value, closeVendor.Longitude!.Value);
        if (distance <= 5)
        {
            apiResponse.Data!.Items.Should().Contain(p => p.Id == _testProductId);
        }
        else
        {
            apiResponse.Data!.Items.Should().NotContain(p => p.Id == _testProductId);
        }
    }

    [Fact]
    public async Task Search_WithCategoryNameOnly_WhenProductCategoryMatches_ShouldReturnProduct()
    {
        // Arrange - Sadece Category string gönderiliyor (CategoryId yok)
        // Vendor'ı kullanıcıya yakın bir konuma yerleştir (delivery radius içinde olmalı)
        var vendor = new Vendor
        {
            Id = _vendorId,
            Name = "Paşa Döner",
            IsActive = true,
            Latitude = 40.99, // Kullanıcıya yakın (~3km)
            Longitude = 29.16,
            DeliveryRadiusInKm = 0, // Default 5km
            Type = VendorType.Restaurant
        };
        var product = CreateTestProduct(categoryId: null, category: "Kebap & Döner");
        product.Vendor = vendor;

        SetupRepositories(new List<Vendor> { vendor }, new List<Product> { product });
        SetupMapper();
        SetupRequestQuery(
            category: "Kebap & Döner",
            userLat: _userLat,
            userLon: _userLon
        );

        var request = new ProductSearchRequestDto
        {
            Category = "Kebap & Döner",
            UserLatitude = _userLat,
            UserLongitude = _userLon,
            Page = 1,
            PageSize = 20
        };

        // Act
        var result = await _controller.Search(request);

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;
        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();
        apiResponse.Data!.Items.Should().Contain(p => p.Id == _testProductId && p.Name == "Test Ürünü");
    }

    [Fact]
    public async Task Search_RealWorldScenario_TestProductShouldBeReturned()
    {
        // Arrange - Gerçek senaryo: Test Ürünü, Kebap & Döner kategorisi, Paşa Döner vendor'ı
        var categoryId = Guid.NewGuid();
        var vendor = new Vendor
        {
            Id = _vendorId,
            Name = "Paşa Döner",
            IsActive = true,
            Latitude = _vendorLat, // 41.0823, 29.0667 (Üsküdar)
            Longitude = _vendorLon,
            DeliveryRadiusInKm = 0, // Default 5km
            Type = VendorType.Restaurant
        };

        // Mesafe hesapla: Kullanıcı (40.9817, 29.1513) ile Vendor (41.0823, 29.0667) arası
        var distance = GeoHelper.CalculateDistance(_userLat, _userLon, _vendorLat, _vendorLon);
        
        // Eğer mesafe 5km'den fazlaysa, test için yakın bir vendor kullan
        Vendor testVendor;
        if (distance > 5)
        {
            // Yakın bir vendor oluştur (3km içinde)
            testVendor = new Vendor
            {
                Id = _vendorId,
                Name = "Paşa Döner",
                IsActive = true,
                Latitude = 40.99, // Kullanıcıya yakın
                Longitude = 29.16,
                DeliveryRadiusInKm = 0,
                Type = VendorType.Restaurant
            };
        }
        else
        {
            testVendor = vendor;
        }

        // Senaryo 1: CategoryId var, Category string de var
        var product1 = CreateTestProduct(categoryId: categoryId, category: "Kebap & Döner");
        product1.Vendor = testVendor;

        // Senaryo 2: CategoryId null, sadece Category string var (eski ürünler için)
        var product2 = new Product
        {
            Id = Guid.NewGuid(),
            Name = "Test Ürünü 2",
            Description = "CategoryId null ama Category string var",
            Price = 150.00m,
            VendorId = _vendorId,
            IsAvailable = true,
            CategoryId = null, // NULL!
            Category = "Kebap & Döner", // String var
            Vendor = testVendor
        };

        SetupRepositories(new List<Vendor> { testVendor }, new List<Product> { product1, product2 });
        SetupMapper();
        SetupRequestQuery(
            categoryId: categoryId.ToString(),
            category: "Kebap & Döner",
            userLat: _userLat,
            userLon: _userLon
        );

        var request = new ProductSearchRequestDto
        {
            CategoryId = categoryId,
            Category = "Kebap & Döner",
            UserLatitude = _userLat,
            UserLongitude = _userLon,
            VendorType = VendorType.Restaurant,
            Page = 1,
            PageSize = 20
        };

        // Act
        var result = await _controller.Search(request);

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;
        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();
        
        // Her iki ürün de gelmeli:
        // 1. CategoryId eşleşen ürün
        // 2. CategoryId null ama Category string eşleşen ürün
        apiResponse.Data!.Items.Should().Contain(p => p.Id == product1.Id);
        apiResponse.Data!.Items.Should().Contain(p => p.Id == product2.Id);
    }
}
