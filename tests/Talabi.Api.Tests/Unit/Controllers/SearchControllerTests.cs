using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Moq;
using MockQueryable.Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class SearchControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly SearchController _controller;

    public SearchControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        var logger = ControllerTestHelpers.CreateMockLogger<SearchController>();

        _controller = new SearchController(
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
    public async Task Autocomplete_WhenQueryMatchesProductsAndVendors_ReturnsCombinedResults()
    {
        // Arrange
        var query = "Test";

        // Products
        var products = new List<Product>
        {
            new Product { Id = Guid.NewGuid(), Name = "Test Product" },
            new Product { Id = Guid.NewGuid(), Name = "Other Product" } // Should not match
        };
        var mockProductRepo = new Mock<IRepository<Product>>();
        mockProductRepo.Setup(x => x.Query()).Returns(products.BuildMock());
        _mockUnitOfWork.Setup(x => x.Products).Returns(mockProductRepo.Object);

        // Vendors
        var vendors = new List<Vendor>
        {
            new Vendor { Id = Guid.NewGuid(), Name = "Test Vendor" },
            new Vendor { Id = Guid.NewGuid(), Name = "Other Vendor" } // Should not match
        };
        var mockVendorRepo = new Mock<IRepository<Vendor>>();
        mockVendorRepo.Setup(x => x.Query()).Returns(vendors.BuildMock());
        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockVendorRepo.Object);

        // Act
        var result = await _controller.Autocomplete(query);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<AutocompleteResultDto>>>().Subject;

        apiResponse.Data.Should().HaveCount(2);
        apiResponse.Data.Should().Contain(x => x.Name == "Test Product" && x.Type == "product");
        apiResponse.Data.Should().Contain(x => x.Name == "Test Vendor" && x.Type == "vendor");
    }

    [Fact]
    public async Task Autocomplete_WhenQueryIsEmpty_ReturnsEmptyList()
    {
        // Act
        var result = await _controller.Autocomplete("");

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<AutocompleteResultDto>>>().Subject;

        apiResponse.Data.Should().BeEmpty();
    }
}
