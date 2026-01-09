using FluentAssertions;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Caching.Memory;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Email;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Services;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

public class AuthControllerTests
{
    private readonly Mock<IAuthService> _mockAuthService;
    private readonly Mock<UserManager<AppUser>> _mockUserManager;
    private readonly Mock<IEmailSender> _mockEmailSender;
    private readonly AuthController _controller;

    public AuthControllerTests()
    {
        var mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        var mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        var mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();
        _mockAuthService = new Mock<IAuthService>();

        var userStore = new Mock<IUserStore<AppUser>>();
        _mockUserManager =
            new Mock<UserManager<AppUser>>(userStore.Object, null!, null!, null!, null!, null!, null!, null!, null!);

        var mockMemoryCache = new Mock<IMemoryCache>();
        mockMemoryCache.Setup(m => m.CreateEntry(It.IsAny<object>())).Returns(new Mock<ICacheEntry>().Object);
        _mockEmailSender = new Mock<IEmailSender>();
        var mockTokenVerifier = new Mock<IExternalAuthTokenVerifier>();
        var mockVerificationSecurity = new Mock<IVerificationCodeSecurityService>();
        var logger = ControllerTestHelpers.CreateMockLogger<AuthController>();

        _controller = new AuthController(
            _mockAuthService.Object,
            _mockUserManager.Object,
            mockMemoryCache.Object,
            _mockEmailSender.Object,
            mockTokenVerifier.Object,
            mockVerificationSecurity.Object,
            mockUnitOfWork.Object,
            logger,
            mockLocalizationService.Object,
            mockUserContextService.Object
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };
    }

    [Fact]
    public async Task Register_WhenValid_ReturnsSuccess()
    {
        // Arrange
        var dto = new RegisterDto { Email = "test@test.com", Password = "Password123", FullName = "Test User" };
        _mockAuthService.Setup(x =>
                x.RegisterAsync(It.IsAny<RegisterDto>(), It.IsAny<System.Globalization.CultureInfo>()))
            .ReturnsAsync(new { UserId = "123" });

        // Act
        var result = await _controller.Register(dto);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<object>>().Subject;

        apiResponse.Data.Should().NotBeNull();
    }

    [Fact]
    public async Task Login_WhenValid_ReturnsToken()
    {
        // Arrange
        var dto = new LoginDto { Email = "test@test.com", Password = "Password123" };
        var response = new LoginResponseDto { Token = "token", RefreshToken = "refresh" };

        _mockAuthService.Setup(x => x.LoginAsync(It.IsAny<LoginDto>(), It.IsAny<string>()))
            .ReturnsAsync(response);

        // Act
        var result = await _controller.Login(dto);

        // Assert
        var okResult = result.Result.Should().BeOfType<OkObjectResult>().Subject;
        var apiResponse = okResult.Value.Should().BeOfType<ApiResponse<LoginResponseDto>>().Subject;

        apiResponse.Data.Should().NotBeNull();
        apiResponse.Data!.Token.Should().Be("token");
    }

    [Fact]
    public async Task ForgotPassword_WhenUserExists_SendsEmail()
    {
        // Arrange
        var email = "test@test.com";
        var user = new AppUser { Email = email };
        _mockUserManager.Setup(x => x.FindByEmailAsync(email)).ReturnsAsync(user);
        _mockUserManager.Setup(x => x.GeneratePasswordResetTokenAsync(user)).ReturnsAsync("token");

        // Act
        var result = await _controller.ForgotPassword(new ForgotPasswordDto { Email = email });

        // Assert
        result.Result.Should().BeOfType<OkObjectResult>();

        _mockEmailSender.Verify(x => x.SendEmailAsync(It.Is<EmailTemplateRequest>(r => r.To == email), default),
            Times.Once);
    }
}
