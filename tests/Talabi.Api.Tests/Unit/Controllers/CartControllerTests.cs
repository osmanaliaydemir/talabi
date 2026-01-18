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

namespace Talabi.Api.Tests.Unit.Controllers;

/// <summary>
/// CartController için unit testler
/// </summary>
public class CartControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly CartController _controller;

    public CartControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        var mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        var mockMapper = new Mock<IMapper>();
        var mockCampaignCalculator = new Mock<ICampaignCalculator>();
        var logger = ControllerTestHelpers.CreateMockLogger<CartController>();

        _controller = new CartController(
            _mockUnitOfWork.Object,
            logger,
            mockLocalizationService.Object,
            _mockUserContextService.Object,
            mockMapper.Object,
            mockCampaignCalculator.Object
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

        // CartController always queries default address for location checks
        var mockAddressRepo = new Mock<IRepository<UserAddress>>();
        mockAddressRepo.Setup(x => x.Query()).Returns(new List<UserAddress>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockAddressRepo.Object);

        // Act
        var result = await _controller.GetCart();

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<CartDto>>().Subject;

        apiResponse.Data.Should().NotBeNull();
        apiResponse.Data!.Items.Should().BeEmpty();
        apiResponse.Data!.UserId.Should().Be(userId);
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
        var addresses = new List<UserAddress> { new UserAddress { UserId = userId } };
        var mockAddressRepo = new Mock<IRepository<UserAddress>>();
        mockAddressRepo.Setup(x => x.Query()).Returns(addresses.BuildMock());
        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockAddressRepo.Object);

        // Product not found (CartController uses Products.Query)
        var mockProductRepo = new Mock<IRepository<Product>>();
        mockProductRepo.Setup(x => x.Query()).Returns(new List<Product>().AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockProductRepo.Object);

        // Vendor lookup (CartController may call Vendors.GetByIdAsync)
        _mockUnitOfWork.Setup(x => x.Vendors.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((Vendor?)null);

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
        var addresses = new List<UserAddress> { new UserAddress { UserId = userId } };
        var mockAddressRepo = new Mock<IRepository<UserAddress>>();
        mockAddressRepo.Setup(x => x.Query()).Returns(addresses.BuildMock());
        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockAddressRepo.Object);

        // Product exists (CartController uses Products.Query)
        var product = new Product { Id = Guid.NewGuid(), Name = "Test Product", VendorId = Guid.NewGuid() };
        var mockProductRepo = new Mock<IRepository<Product>>();
        mockProductRepo.Setup(x => x.Query()).Returns(new List<Product> { product }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockProductRepo.Object);

        // Vendor lookup (not used unless default address has lat/lon)
        _mockUnitOfWork.Setup(x => x.Vendors.GetByIdAsync(product.VendorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Vendor { Id = product.VendorId, IsActive = true });

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
        var addresses = new List<UserAddress> { new UserAddress { UserId = userId } };
        var mockAddressRepo = new Mock<IRepository<UserAddress>>();
        mockAddressRepo.Setup(x => x.Query()).Returns(addresses.BuildMock());
        _mockUnitOfWork.Setup(x => x.UserAddresses).Returns(mockAddressRepo.Object);

        var productId = Guid.NewGuid();
        var product = new Product { Id = productId, Name = "Test Product", VendorId = Guid.NewGuid() };
        var mockProductRepo = new Mock<IRepository<Product>>();
        mockProductRepo.Setup(x => x.Query()).Returns(new List<Product> { product }.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockProductRepo.Object);

        _mockUnitOfWork.Setup(x => x.Vendors.GetByIdAsync(product.VendorId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Vendor { Id = product.VendorId, IsActive = true });

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
