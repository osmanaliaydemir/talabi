using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using MockQueryable.Moq;
using MockQueryable;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Core.Options;
using Xunit;
using System.Linq;

namespace Talabi.Api.Tests.Unit.Controllers;

/// <summary>
/// VendorsController için unit testler
/// </summary>
public class VendorsControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly ILogger<VendorsController> _logger;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<ICacheService> _mockCacheService;
    private readonly Mock<IOptions<CacheOptions>> _mockCacheOptions;
    private readonly VendorsController _controller;

    public VendorsControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _logger = ControllerTestHelpers.CreateMockLogger<VendorsController>();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockCacheService = new Mock<ICacheService>();
        _mockCacheOptions = new Mock<IOptions<CacheOptions>>();
        
        // Setup default cache options
        _mockCacheOptions.Setup(x => x.Value).Returns(new CacheOptions());

        _controller = new VendorsController(
            _mockUnitOfWork.Object,
            _logger,
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
    public async Task GetVendors_WhenNoFilters_ReturnsAllActiveVendors()
    {
        // Arrange
        var vendors = new List<Vendor>
        {
            new Vendor
            {
                Id = Guid.NewGuid(),
                Name = "Vendor 1",
                Type = VendorType.Restaurant,
                IsActive = true
            },
            new Vendor
            {
                Id = Guid.NewGuid(),
                Name = "Vendor 2",
                Type = VendorType.Market,
                IsActive = true
            }
        };

        var mockRepository = new Mock<IRepository<Vendor>>();
        var mockQueryable = vendors.BuildMock();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);

        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepository.Object);

        // Act
        var result = await _controller.GetVendors();

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<VendorDto>>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Items.Should().HaveCount(2);
        apiResponse.Data.Items.Should().Contain(v => v.Name == "Vendor 1");
        apiResponse.Data.Items.Should().Contain(v => v.Name == "Vendor 2");
    }

    [Fact]
    public async Task GetVendors_WhenVendorTypeFilter_ReturnsFilteredVendors()
    {
        // Arrange
        var vendors = new List<Vendor>
        {
            new Vendor
            {
                Id = Guid.NewGuid(),
                Name = "Restaurant 1",
                Type = VendorType.Restaurant,
                IsActive = true
            },
            new Vendor
            {
                Id = Guid.NewGuid(),
                Name = "Market 1",
                Type = VendorType.Market,
                IsActive = true
            }
        };

        var mockRepository = new Mock<IRepository<Vendor>>();
        var mockQueryable = vendors.BuildMock();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);

        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepository.Object);

        // Act
        var result = await _controller.GetVendors(vendorType: VendorType.Restaurant);

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<VendorDto>>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Items.Should().HaveCount(1);
        apiResponse.Data.Items.First().Name.Should().Be("Restaurant 1");
        apiResponse.Data.Items.First().Type.Should().Be(VendorType.Restaurant);
    }

    [Fact]
    public async Task GetVendors_WhenPageIsLessThanOne_SetsPageToOne()
    {
        // Arrange
        var vendors = new List<Vendor>
        {
            new Vendor
            {
                Id = Guid.NewGuid(),
                Name = "Vendor 1",
                Type = VendorType.Restaurant,
                IsActive = true
            }
        };

        var mockRepository = new Mock<IRepository<Vendor>>();
        var mockQueryable = vendors.BuildMock();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);

        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepository.Object);

        // Act
        var result = await _controller.GetVendors(page: 0, pageSize: 6);

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<VendorDto>>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Page.Should().Be(1);
    }

    [Fact]
    public async Task GetVendors_WhenPageSizeIsLessThanOne_SetsPageSizeToSix()
    {
        // Arrange
        var vendors = new List<Vendor>
        {
            new Vendor
            {
                Id = Guid.NewGuid(),
                Name = "Vendor 1",
                Type = VendorType.Restaurant,
                IsActive = true
            }
        };

        var mockRepository = new Mock<IRepository<Vendor>>();
        var mockQueryable = vendors.BuildMock();
        mockRepository.Setup(x => x.Query()).Returns(mockQueryable);

        _mockUnitOfWork.Setup(x => x.Vendors).Returns(mockRepository.Object);

        // Act
        var result = await _controller.GetVendors(page: 1, pageSize: 0);

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PagedResultDto<VendorDto>>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.PageSize.Should().Be(6);
    }
}
