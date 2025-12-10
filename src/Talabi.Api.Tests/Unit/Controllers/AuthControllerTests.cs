using FluentAssertions;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;
using Talabi.Core.Services;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

/// <summary>
/// AuthController için unit testler
/// </summary>
public class AuthControllerTests
{
    private readonly Mock<IAuthService> _mockAuthService;
    private readonly Mock<UserManager<Core.Entities.AppUser>> _mockUserManager;
    private readonly Mock<IMemoryCache> _mockMemoryCache;
    private readonly Mock<Core.Services.IEmailSender> _mockEmailSender;
    private readonly Mock<IUnitOfWork> _mockUnitOfWork;
    private readonly ILogger<AuthController> _logger;
    private readonly Mock<ILocalizationService> _mockLocalizationService;
    private readonly Mock<IUserContextService> _mockUserContextService;
    private readonly AuthController _controller;

    public AuthControllerTests()
    {
        _mockAuthService = new Mock<IAuthService>();
        _mockUserManager = new Mock<UserManager<Core.Entities.AppUser>>(
            Mock.Of<IUserStore<Core.Entities.AppUser>>(),
            null!, null!, null!, null!, null!, null!, null!, null!);
        _mockMemoryCache = new Mock<IMemoryCache>();
        _mockEmailSender = new Mock<Core.Services.IEmailSender>();
        _mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        _logger = ControllerTestHelpers.CreateMockLogger<AuthController>();
        _mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        _mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();

        _controller = new AuthController(
            _mockAuthService.Object,
            _mockUserManager.Object,
            _mockMemoryCache.Object,
            _mockEmailSender.Object,
            _mockUnitOfWork.Object,
            _logger,
            _mockLocalizationService.Object,
            _mockUserContextService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task Register_WhenValidDto_ReturnsOk()
    {
        // Arrange
        var dto = new RegisterDto
        {
            Email = "test@example.com",
            Password = "Test123!",
            FullName = "Test User",
            Language = "tr"
        };

        var expectedResult = new { UserId = Guid.NewGuid().ToString(), Email = dto.Email };
        _mockAuthService
            .Setup(x => x.RegisterAsync(It.IsAny<RegisterDto>(), It.IsAny<System.Globalization.CultureInfo>()))
            .ReturnsAsync(expectedResult);

        // Act
        var result = await _controller.Register(dto);

        // Assert
        result.Should().NotBeNull();
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.Success.Should().BeTrue();
        apiResponse.Data.Should().NotBeNull();
    }

    [Fact]
    public async Task Register_WhenInvalidOperationException_ReturnsBadRequest()
    {
        // Arrange
        var dto = new RegisterDto
        {
            Email = "test@example.com",
            Password = "Test123!",
            FullName = "Test User"
        };

        _mockAuthService
            .Setup(x => x.RegisterAsync(It.IsAny<RegisterDto>(), It.IsAny<System.Globalization.CultureInfo>()))
            .ThrowsAsync(new InvalidOperationException("User already exists"));

        // Act
        var result = await _controller.Register(dto);

        // Assert
        result.Should().NotBeNull();
        var badRequestResult = result.Result.Should().BeOfType<BadRequestObjectResult>().Subject;
        var apiResponse = badRequestResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.Success.Should().BeFalse();
        apiResponse.ErrorCode.Should().Be("REGISTRATION_FAILED");
    }

    [Fact]
    public async Task Register_WhenException_ReturnsInternalServerError()
    {
        // Arrange
        var dto = new RegisterDto
        {
            Email = "test@example.com",
            Password = "Test123!",
            FullName = "Test User"
        };

        _mockAuthService
            .Setup(x => x.RegisterAsync(It.IsAny<RegisterDto>(), It.IsAny<System.Globalization.CultureInfo>()))
            .ThrowsAsync(new Exception("Database error"));

        // Act
        var result = await _controller.Register(dto);

        // Assert
        result.Should().NotBeNull();
        var statusCodeResult = result.Result.Should().BeOfType<ObjectResult>().Subject;
        statusCodeResult.StatusCode.Should().Be(500);
        var apiResponse = statusCodeResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;
        apiResponse.Success.Should().BeFalse();
        apiResponse.ErrorCode.Should().Be("INTERNAL_ERROR");
    }
}

