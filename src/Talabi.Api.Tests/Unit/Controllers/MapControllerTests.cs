using AutoMapper;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

/// <summary>
/// MapController için unit testler
/// </summary>
public class MapControllerTests
{
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly ILogger<MapController> _logger;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly Mock<IMapper> _mockMapper;
    private readonly IConfiguration _configuration;
    private readonly MapController _controller;

    public MapControllerTests()
    {
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _logger = ControllerTestHelpers.CreateMockLogger<MapController>();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockMapper = new Mock<IMapper>();
        _configuration = ControllerTestHelpers.CreateMockConfiguration();

        _controller = new MapController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object,
            _configuration
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public void GetApiKey_WhenApiKeyExists_ReturnsOkWithApiKey()
    {
        // Arrange
        var config = ControllerTestHelpers.CreateMockConfiguration(new Dictionary<string, string>
        {
            { "GoogleMaps:ApiKey", "test-api-key-12345" }
        });

        var controller = new MapController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object,
            config
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };

        // Act
        var result = controller.GetApiKey();

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Should().BeOfType<ActionResult<ApiResponse<object>>>().Subject;
        var actionResult = okResult.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = actionResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;

        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();

        // Use reflection to get ApiKey property
        var dataType = apiResponse.Data?.GetType();
        if (dataType != null)
        {
            var apiKeyProperty = dataType.GetProperty("ApiKey");
            if (apiKeyProperty != null)
            {
                var apiKey = apiKeyProperty.GetValue(apiResponse.Data)?.ToString();
                apiKey.Should().Be("test-api-key-12345");
            }
        }
    }

    [Fact]
    public void GetApiKey_WhenApiKeyNotConfigured_ReturnsNotFound()
    {
        // Arrange
        var config = ControllerTestHelpers.CreateMockConfiguration(new Dictionary<string, string>
        {
            { "GoogleMaps:ApiKey", "" }
        });

        var controller = new MapController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object,
            config
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };

        // Act
        var result = controller.GetApiKey();

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Should().BeOfType<ActionResult<ApiResponse<object>>>().Subject;
        var actionResult = okResult.Result.Should().BeOfType<NotFoundObjectResult>().Subject;
        var apiResponse = actionResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;

        apiResponse.Success.Should().BeFalse();
        apiResponse.ErrorCode.Should().Be("API_KEY_NOT_CONFIGURED");
    }

    [Fact]
    public void GetApiKey_WhenConfigurationIsNull_ReturnsInternalServerError()
    {
        // Arrange
        var controller = new MapController(
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object,
            _mockMapper.Object,
            null! // null configuration
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };

        // Act
        var result = controller.GetApiKey();

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Should().BeOfType<ActionResult<ApiResponse<object>>>().Subject;
        var actionResult = okResult.Result.Should().BeOfType<ObjectResult>().Subject;
        actionResult.StatusCode.Should().Be(500);

        var apiResponse = actionResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.Success.Should().BeFalse();
        apiResponse.ErrorCode.Should().Be("INTERNAL_SERVER_ERROR");
    }
}

