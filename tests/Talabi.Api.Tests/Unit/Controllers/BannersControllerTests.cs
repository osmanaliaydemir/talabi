using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using MockQueryable.Moq;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Options;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class BannersControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<ICacheService> _mockCacheService;
    private readonly Mock<IOptions<CacheOptions>> _mockCacheOptions;
    private readonly BannersController _controller;

    public BannersControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockCacheService = new Mock<ICacheService>();
        _mockCacheOptions = new Mock<IOptions<CacheOptions>>();

        _mockCacheOptions.Setup(x => x.Value).Returns(new CacheOptions
        {
            BannersKeyPrefix = "banners",
            BannersCacheTTLMinutes = 60
        });

        // Setup CacheService to execute the factory
        _mockCacheService
            .Setup(x => x.GetOrSetAsync(It.IsAny<string>(), It.IsAny<Func<Task<List<PromotionalBannerDto>>>>(), It.IsAny<int>()))
            .Returns<string, Func<Task<List<PromotionalBannerDto>>>, int>((k, f, t) => f());

        var logger = ControllerTestHelpers.CreateMockLogger<BannersController>();

        _controller = new BannersController(
            _mockUnitOfWork.Object,
            logger,
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
    public async Task GetBanners_WhenCalled_ReturnsActiveBanners()
    {
        // Arrange
        var banners = new List<PromotionalBanner>
        {
            new()
            {
                Id = Guid.NewGuid(),
                IsActive = true,
                Title = "Banner 1",
                DisplayOrder = 1,
                Translations = []
            },
            new()
            {
                Id = Guid.NewGuid(),
                IsActive = false,
                Title = "Banner 2",
                DisplayOrder = 2,
                Translations = []
            }
        };

        var mockRepo = new Mock<IRepository<PromotionalBanner>>();
        mockRepo.Setup(x => x.Query()).Returns(banners.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.PromotionalBanners).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetBanners();

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<List<PromotionalBannerDto>>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().HaveCount(1);
        apiResponse.Data!.First().Title.Should().Be("Banner 1");
    }

    [Fact]
    public async Task GetBanner_WhenExists_ReturnsBanner()
    {
        // Arrange
        var id = Guid.NewGuid();
        var banners = new List<PromotionalBanner>
        {
            new()
            {
                Id = id,
                Title = "Banner 1",
                Translations = []
            }
        };

        var mockRepo = new Mock<IRepository<PromotionalBanner>>();
        mockRepo.Setup(x => x.Query()).Returns(banners.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.PromotionalBanners).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetBanner(id);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<PromotionalBannerDto>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data!.Id.Should().Be(id);
    }

    [Fact]
    public async Task GetBanner_WhenNotExists_ReturnsNotFound()
    {
        // Arrange
        var banners = new List<PromotionalBanner>();

        var mockRepo = new Mock<IRepository<PromotionalBanner>>();
        mockRepo.Setup(x => x.Query()).Returns(banners.AsQueryable().BuildMock());
        _mockUnitOfWork.Setup(x => x.PromotionalBanners).Returns(mockRepo.Object);

        // Act
        var result = await _controller.GetBanner(Guid.NewGuid());

        // Assert
        result.Result.Should().BeOfType<NotFoundObjectResult>();
    }
}
