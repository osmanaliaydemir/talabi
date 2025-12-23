using AutoMapper;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using MockQueryable.Moq;
using MockQueryable;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Xunit;
using System.Linq;
using System.Threading;

namespace Talabi.Api.Tests.Unit.Controllers;

/// <summary>
/// CartController için unit testler
/// </summary>
public class CartControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly ILogger<CartController> _logger;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<IMapper> _mockMapper;
    private readonly Mock<ICampaignCalculator> _mockCampaignCalculator;
    private readonly CartController _controller;

    public CartControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _logger = ControllerTestHelpers.CreateMockLogger<CartController>();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockMapper = new Mock<IMapper>();
        _mockCampaignCalculator = new Mock<ICampaignCalculator>();

        _controller = new CartController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object,
            _mockCampaignCalculator.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task GetCart_WhenCartNotFound_ReturnsEmptyCartDto()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var carts = new List<Cart>();
        var mockQueryable = carts.BuildMock();

        var mockCartRepo = new Mock<IRepository<Cart>>();
        mockCartRepo.Setup(x => x.Query()).Returns(mockQueryable);
        _mockUnitOfWork.Setup(x => x.Carts).Returns(mockCartRepo.Object);

        // Act
        var result = await _controller.GetCart();

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<CartDto>>().Subject;

        apiResponse.Data.Should().NotBeNull();
        apiResponse.Data!.Items.Should().BeEmpty();
        apiResponse.Data.UserId.Should().Be(userId);
    }

    [Fact]
    public async Task AddToCart_WhenUserHasNoAddress_ReturnsBadRequest()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        // No addresses
        var addresses = new List<UserAddress>();
        var mockAddressRepo = new Mock<IRepository<UserAddress>>();
        mockAddressRepo.Setup(x => x.Query()).Returns(addresses.BuildMock());
        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockAddressRepo.Object);


        var dto = new AddToCartDto { ProductId = Guid.NewGuid(), Quantity = 1 };

        // Act
        var result = await _controller.AddToCart(dto);

        // Assert
        var badRequest = result.Result.Should().BeOfType<BadRequestObjectResult>().Subject;
        var apiResponse = badRequest.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.ErrorCode.Should().Be("ADDRESS_REQUIRED");
    }

    [Fact]
    public async Task AddToCart_WhenProductNotFound_ReturnsNotFound()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        // Has address
        List<UserAddress> addresses = [new() { UserId = userId }];
        var mockAddressRepo = new Mock<IRepository<UserAddress>>();
        mockAddressRepo.Setup(x => x.Query()).Returns(addresses.BuildMock());
        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockAddressRepo.Object);

        // Product not found
        _mockUnitOfWork.Setup(x => x.Products.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((Product?)null);

        var dto = new AddToCartDto { ProductId = Guid.NewGuid(), Quantity = 1 };

        // Act
        var result = await _controller.AddToCart(dto);

        // Assert
        var notFound = result.Result.Should().BeOfType<NotFoundObjectResult>().Subject;
        var apiResponse = notFound.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.ErrorCode.Should().Be("PRODUCT_NOT_FOUND");
    }

    [Fact]
    public async Task AddToCart_WhenNewItem_AddsToCart()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        // Has address
        List<UserAddress> addresses = [new() { UserId = userId }];
        var mockAddressRepo = new Mock<IRepository<UserAddress>>();
        mockAddressRepo.Setup(x => x.Query()).Returns(addresses.BuildMock());
        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockAddressRepo.Object);

        // Product exists
        var product = new Product { Id = Guid.NewGuid(), Name = "Test Product" };
        _mockUnitOfWork.Setup(x => x.Products.GetByIdAsync(product.Id, It.IsAny<CancellationToken>()))
            .ReturnsAsync(product);

        // Cart exists but empty
        var cart = new Cart { Id = Guid.NewGuid(), UserId = userId };
        var carts = new List<Cart> { cart };
        var mockCartRepo = new Mock<IRepository<Cart>>();
        mockCartRepo.Setup(x => x.Query()).Returns(carts.BuildMock());
        _mockUnitOfWork.Setup(x => x.Carts).Returns(mockCartRepo.Object);

        // No cart items
        var cartItems = new List<CartItem>();
        var mockCartItemRepo = new Mock<IRepository<CartItem>>();
        mockCartItemRepo.Setup(x => x.Query()).Returns(cartItems.BuildMock());
        _mockUnitOfWork.Setup(x => x.CartItems).Returns(mockCartItemRepo.Object);

        var dto = new AddToCartDto { ProductId = product.Id, Quantity = 2 };

        // Act
        var result = await _controller.AddToCart(dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.CartItems.AddAsync(
            It.Is<CartItem>(ci => ci.CartId == cart.Id && ci.ProductId == product.Id && ci.Quantity == 2),
            It.IsAny<CancellationToken>()
        ), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(default), Times.Once);
    }

    [Fact]
    public async Task AddToCart_WhenItemExists_UpdatesQuantity()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        // Has address
        List<UserAddress> addresses = [new() { UserId = userId }];
        var mockAddressRepo = new Mock<IRepository<UserAddress>>();
        mockAddressRepo.Setup(x => x.Query()).Returns(addresses.BuildMock());
        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockAddressRepo.Object);

        var productId = Guid.NewGuid();
        var product = new Product { Id = productId, Name = "Test Product" };
        _mockUnitOfWork.Setup(x => x.Products.GetByIdAsync(productId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(product);

        var cart = new Cart { Id = Guid.NewGuid(), UserId = userId };
        var mockCartRepo = new Mock<IRepository<Cart>>();
        mockCartRepo.Setup(x => x.Query()).Returns(new List<Cart> { cart }.BuildMock());
        _mockUnitOfWork.Setup(x => x.Carts).Returns(mockCartRepo.Object);

        var existingItem = new CartItem { Id = Guid.NewGuid(), CartId = cart.Id, ProductId = productId, Quantity = 1 };
        var mockCartItemRepo = new Mock<IRepository<CartItem>>();
        mockCartItemRepo.Setup(x => x.Query()).Returns(new List<CartItem> { existingItem }.BuildMock());
        _mockUnitOfWork.Setup(x => x.CartItems).Returns(mockCartItemRepo.Object);

        var dto = new AddToCartDto { ProductId = productId, Quantity = 2 };

        // Act
        var result = await _controller.AddToCart(dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        // Quantity should terminate at 3 (1 + 2)
        // Note: In unit test with mock objects, the object reference is updated in memory
        existingItem.Quantity.Should().Be(3);

        _mockUnitOfWork.Verify(x => x.CartItems.Update(existingItem), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(default), Times.Once);
    }

    [Fact]
    public async Task UpdateCartItem_WhenQuantityZero_RemovesItem()
    {
        // Arrange
        var userId = "user-1";
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var itemId = Guid.NewGuid();
        var cart = new Cart { Id = Guid.NewGuid(), UserId = userId };
        var cartItem = new CartItem { Id = itemId, CartId = cart.Id, Cart = cart, Quantity = 5 };

        var mockCartItemRepo = new Mock<IRepository<CartItem>>();
        mockCartItemRepo.Setup(x => x.Query()).Returns(new List<CartItem> { cartItem }.BuildMock());
        _mockUnitOfWork.Setup(x => x.CartItems).Returns(mockCartItemRepo.Object);
        _mockUnitOfWork.Setup(x => x.Carts).Returns(new Mock<IRepository<Cart>>().Object); // For Cart update

        var dto = new UpdateCartItemDto { Quantity = 0 };

        // Act
        var result = await _controller.UpdateCartItem(itemId, dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();
        _mockUnitOfWork.Verify(x => x.CartItems.Remove(cartItem), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(default), Times.Once);
    }
}
