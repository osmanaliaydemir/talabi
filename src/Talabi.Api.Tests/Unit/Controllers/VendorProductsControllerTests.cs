using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
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

public class VendorProductsControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly VendorProductsController _controller;

    public VendorProductsControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        var logger = ControllerTestHelpers.CreateMockLogger<VendorProductsController>();

        _controller = new VendorProductsController(
            _mockUnitOfWork.Object,
            logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    private void SetupVendor(string userId, Guid vendorId)
    {
        _mockUserContextService.Setup(x => x.GetUserId()).Returns(userId);

        var vendor = new Vendor { Id = vendorId, OwnerId = userId };
        var vendors = new List<Vendor> { vendor };
        var mockRepo = new Mock<IRepository<Vendor>>();
        mockRepo.Setup(x => x.Query()).Returns(vendors.BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepo.Object);
    }

    [Fact]
    public async Task GetProducts_WhenCalled_ReturnsPagedProducts()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var products = new List<Product>
        {
            new Product { Id = Guid.NewGuid(), VendorId = vendorId, Name = "P1", CreatedAt = DateTime.UtcNow },
            new Product { Id = Guid.NewGuid(), VendorId = vendorId, Name = "P2", CreatedAt = DateTime.UtcNow.AddMinutes(-1) }
        };

        var mockRepo = new Mock<IRepository<Product>>();
        mockRepo.Setup(x => x.Query()).Returns(products.BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetProducts();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<VendorProductDto>>>().Subject;

        apiResponse.Data.Items.Should().HaveCount(2);
        apiResponse.Data.Items.First().Name.Should().Be("P1"); // Ordered by CreatedAt Desc
    }

    [Fact]
    public async Task GetProduct_WhenFound_ReturnsProduct()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        var productId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var product = new Product { Id = productId, VendorId = vendorId, Name = "P1" };
        var products = new List<Product> { product };

        var mockRepo = new Mock<IRepository<Product>>();
        mockRepo.Setup(x => x.Query()).Returns(products.BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetProduct(productId);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<VendorProductDto>>().Subject;

        apiResponse.Data.Id.Should().Be(productId);
    }

    [Fact]
    public async Task CreateProduct_WhenValid_CreatesProduct()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var dto = new CreateProductDto { Name = "New Product", Price = 100 };

        var mockRepo = new Mock<IRepository<Product>>();
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockRepo.Object);

        // Act
        var result = await _controller.CreateProduct(dto);

        // Assert
        var createdResult = result.Result.Should().BeOfType<CreatedAtActionResult>().Subject;
        var apiResponse = createdResult.Value.Should().BeOfType<ApiResponse<VendorProductDto>>().Subject;

        apiResponse.Data.Name.Should().Be("New Product");

        _mockUnitOfWork.Verify(x => x.Products.AddAsync(It.Is<Product>(p => p.Name == "New Product" && p.VendorId == vendorId), It.IsAny<CancellationToken>()), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateProduct_WhenFound_UpdatesProduct()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        var productId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var product = new Product { Id = productId, VendorId = vendorId, Name = "Old Name" };
        var products = new List<Product> { product };

        var mockRepo = new Mock<IRepository<Product>>();
        mockRepo.Setup(x => x.Query()).Returns(products.BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockRepo.Object);

        var dto = new UpdateProductDto { Name = "New Name" };

        // Act
        var result = await _controller.UpdateProduct(productId, dto);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.Products.Update(It.Is<Product>(p => p.Name == "New Name")), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task DeleteProduct_WhenFound_DeletesProduct()
    {
        // Arrange
        var userId = "user-1";
        var vendorId = Guid.NewGuid();
        var productId = Guid.NewGuid();
        SetupVendor(userId, vendorId);

        var product = new Product { Id = productId, VendorId = vendorId };
        var products = new List<Product> { product };

        var mockRepo = new Mock<IRepository<Product>>();
        mockRepo.Setup(x => x.Query()).Returns(products.BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockRepo.Object);

        // Act
        var result = await _controller.DeleteProduct(productId);

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockUnitOfWork.Verify(x => x.Products.Remove(It.Is<Product>(p => p.Id == productId)), Times.Once);
        _mockUnitOfWork.Verify(x => x.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }
}
