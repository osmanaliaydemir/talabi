using System.Linq;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MockQueryable;
using MockQueryable.Moq;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class FavoritesControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly FavoritesController _controller;

    public FavoritesControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        var logger = ControllerTestHelpers.CreateMockLogger<FavoritesController>();

        _controller = new FavoritesController(
            _mockUnitOfWork.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetFavorites_WhenCalled_ReturnsPagedResult()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = "Test Product",
            VendorId = Guid.NewGuid(),
            Price = 100,
            Currency = Talabi.Core.Enums.Currency.USD
        };

        var favorites = new List<FavoriteProduct>
        {
            new FavoriteProduct { Id = Guid.NewGuid(), UserId = userId, ProductId = product.Id, Product = product },
            new FavoriteProduct { Id = Guid.NewGuid(), UserId = userId, ProductId = Guid.NewGuid(), Product = new Product { Id = Guid.NewGuid(), Name = "Other" } }
        };

        var mockRepo = new Mock<IRepository<FavoriteProduct>>();
        var mockQueryable = favorites.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);

        _mockUnitOfWork.Setup(x => x.FavoriteProducts).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetFavorites(1, 10);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<ProductDto>>>().Subject;

        apiResponse.Data.Items.Should().HaveCount(2);
        apiResponse.Data.TotalCount.Should().Be(2);
        apiResponse.Data.Items.Should().Contain(p => p.Name == "Test Product");
    }

    [Fact]
    public async Task AddToFavorites_WhenProductNotFound_ReturnsNotFound()
    {
        // Arrange
        var userId = "user-1";
        var productId = Guid.NewGuid();
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        _mockUnitOfWork.Setup(x => x.Products.GetByIdAsync(productId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Product?)null);

        // Act
        var result = await _controller.AddToFavorites(productId);

        // Assert
        var notFoundResult = result.Result.Should().BeOfType<NotFoundObjectResult>().Subject;
        var apiResponse = notFoundResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.ErrorCode.Should().Be("PRODUCT_NOT_FOUND");
    }

    [Fact]
    public async Task AddToFavorites_WhenAlreadyExists_ReturnsBadRequest()
    {
        // Arrange
        var userId = "user-1";
        var productId = Guid.NewGuid();
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        _mockUnitOfWork.Setup(x => x.Products.GetByIdAsync(productId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Product { Id = productId });

        var favorites = new List<FavoriteProduct>
        {
            new FavoriteProduct { UserId = userId, ProductId = productId }
        };

        var mockRepo = new Mock<IRepository<FavoriteProduct>>();
        var mockQueryable = favorites.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.FavoriteProducts).Returns(mockRepo.Object);

        // Act
        var result = await _controller.AddToFavorites(productId);

        // Assert
        var badRequestResult = result.Result.Should().BeOfType<BadRequestObjectResult>().Subject;
        var apiResponse = badRequestResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.ErrorCode.Should().Be("ALREADY_IN_FAVORITES");
    }

    [Fact]
    public async Task AddToFavorites_WhenNew_AddsToDatabase()
    {
        // Arrange
        var userId = "user-1";
        var productId = Guid.NewGuid();
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        _mockUnitOfWork.Setup(x => x.Products.GetByIdAsync(productId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Product { Id = productId });

        var favorites = new List<FavoriteProduct>();
        var mockRepo = new Mock<IRepository<FavoriteProduct>>();
        var mockQueryable = favorites.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.FavoriteProducts).Returns(mockRepo.Object);

        // Act
        var result = await _controller.AddToFavorites(productId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.FavoriteProducts.AddAsync(
            It.Is<FavoriteProduct>(f => f.UserId == userId && f.ProductId == productId),
            It.IsAny<CancellationToken>()
        ), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task RemoveFromFavorites_WhenNotFound_ReturnsNotFound()
    {
        // Arrange
        var userId = "user-1";
        var productId = Guid.NewGuid();
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var favorites = new List<FavoriteProduct>();
        var mockRepo = new Mock<IRepository<FavoriteProduct>>();
        var mockQueryable = favorites.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.FavoriteProducts).Returns(mockRepo.Object);

        // Act
        var result = await _controller.RemoveFromFavorites(productId);

        // Assert
        var notFoundResult = result.Result.Should().BeOfType<NotFoundObjectResult>().Subject;
        var apiResponse = notFoundResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.ErrorCode.Should().Be("FAVORITE_NOT_FOUND");
    }

    [Fact]
    public async Task RemoveFromFavorites_WhenFound_RemovesFromDatabase()
    {
        // Arrange
        var userId = "user-1";
        var productId = Guid.NewGuid();
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var favorite = new FavoriteProduct { UserId = userId, ProductId = productId };
        var favorites = new List<FavoriteProduct> { favorite };

        var mockRepo = new Mock<IRepository<FavoriteProduct>>();
        var mockQueryable = favorites.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.FavoriteProducts).Returns(mockRepo.Object);

        // Act
        var result = await _controller.RemoveFromFavorites(productId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        _mockUnitOfWork.Verify(x => x.FavoriteProducts.Remove(favorite), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task IsFavorite_WhenCalled_ReturnsStatus()
    {
        // Arrange
        var userId = "user-1";
        var productId = Guid.NewGuid();
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var favorites = new List<FavoriteProduct>
        {
            new FavoriteProduct { UserId = userId, ProductId = productId }
        };

        var mockRepo = new Mock<IRepository<FavoriteProduct>>();
        var mockQueryable = favorites.BuildMock();
        mockRepo.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.FavoriteProducts).Returns(mockRepo.Object);

        // Act
        var result = await _controller.IsFavorite(productId);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        // Verify property is true via reflection/dynamic or DTO
        // Since ApiResponse<object> returns anonymous type or object, we might need to inspect it carefully
        // But for object, we can't easily cast to anon type in test. 
        // We can check the JSON value or just success.
        // Or if the implementation returns a specific DTO? It returns `new { IsFavorite = isFavorite }`.

        // Asserting anonymous type property in test:
        var data = okResult.Value.GetType().GetProperty("Data")?.GetValue(okResult.Value);
        // This is ApiResponse.Data which is object. The actual object inside is { IsFavorite = true }

        // Simpler way: check if returned object has property
        data.Should().NotBeNull();
        // Since it's anonymous type, accessing via reflection or strictly dynamic
        var isFavoriteProp = data!.GetType().GetProperty("IsFavorite");
        isFavoriteProp.Should().NotBeNull();
        isFavoriteProp!.GetValue(data).Should().Be(true);
    }
}
