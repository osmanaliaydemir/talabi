using FluentAssertions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Moq;
using Talabi.Api.Controllers;
using Talabi.Api.Tests.Helpers;
using Talabi.Core.Interfaces;
using Xunit;

namespace Talabi.Api.Tests.Unit.Controllers;

/// <summary>
/// BaseController için unit testler
/// </summary>
public class BaseControllerTests
{
    [Fact]
    public void GetLanguageFromRequest_WithQueryParameter_ReturnsNormalizedLanguage()
    {
        // Arrange
        var mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        var logger = ControllerTestHelpers.CreateMockLogger<TestController>();
        var mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        var mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();

        var controller = new TestController(
            mockUnitOfWork.Object,
            logger,
            mockLocalizationService.Object,
            mockUserContextService.Object
        );

        var httpContext = new DefaultHttpContext();
        httpContext.Request.QueryString = new Microsoft.AspNetCore.Http.QueryString("?lang=en");
        controller.ControllerContext = new ControllerContext
        {
            HttpContext = httpContext
        };

        // Act
        var language = controller.GetLanguageFromRequestPublic("en");

        // Assert
        language.Should().Be("en");
    }

    [Fact]
    public void GetLanguageFromRequest_WithAcceptLanguageHeader_ReturnsNormalizedLanguage()
    {
        // Arrange
        var mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        var logger = ControllerTestHelpers.CreateMockLogger<TestController>();
        var mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        var mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();

        var controller = new TestController(
            mockUnitOfWork.Object,
            logger,
            mockLocalizationService.Object,
            mockUserContextService.Object
        );

        var httpContext = new DefaultHttpContext();
        httpContext.Request.Headers["Accept-Language"] = "tr-TR,tr;q=0.9";
        controller.ControllerContext = new ControllerContext
        {
            HttpContext = httpContext
        };

        // Act
        var language = controller.GetLanguageFromRequestPublic();

        // Assert
        language.Should().Be("tr");
    }

    [Fact]
    public void GetLanguageFromRequest_WithoutLanguage_ReturnsDefaultTurkish()
    {
        // Arrange
        var mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        var logger = ControllerTestHelpers.CreateMockLogger<TestController>();
        var mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        var mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();

        var controller = new TestController(
            mockUnitOfWork.Object,
            logger,
            mockLocalizationService.Object,
            mockUserContextService.Object
        );

        var httpContext = new DefaultHttpContext();
        controller.ControllerContext = new ControllerContext
        {
            HttpContext = httpContext
        };

        // Act
        var language = controller.GetLanguageFromRequestPublic();

        // Assert
        language.Should().Be("tr");
    }

    [Theory]
    [InlineData("tr", "tr")]
    [InlineData("TR", "tr")]
    [InlineData("tr-TR", "tr")]
    [InlineData("turkish", "tr")]
    [InlineData("en", "en")]
    [InlineData("EN", "en")]
    [InlineData("en-US", "en")]
    [InlineData("english", "en")]
    [InlineData("ar", "ar")]
    [InlineData("AR", "ar")]
    [InlineData("ar-SA", "ar")]
    [InlineData("arabic", "ar")]
    [InlineData("invalid", "tr")] // Default fallback
    public void NormalizeLanguageCode_WithVariousInputs_ReturnsCorrectLanguage(string input, string expected)
    {
        // Arrange
        var mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        var logger = ControllerTestHelpers.CreateMockLogger<TestController>();
        var mockLocalizationService = ControllerTestHelpers.CreateMockLocalizationService();
        var mockUserContextService = ControllerTestHelpers.CreateMockUserContextService();

        var controller = new TestController(
            mockUnitOfWork.Object,
            logger,
            mockLocalizationService.Object,
            mockUserContextService.Object
        );

        // Act
        var result = TestController.NormalizeLanguageCodePublic(input);

        // Assert
        result.Should().Be(expected);
    }
}

/// <summary>
/// BaseController'ı test etmek için test controller'ı
/// </summary>
public class TestController : BaseController
{
    public TestController(
        IUnitOfWork unitOfWork,
        ILogger logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
    }

    // Test için public metodlar
    public string GetLanguageFromRequestPublic(string? language = null)
    {
        return GetLanguageFromRequest(language);
    }

    public static string NormalizeLanguageCodePublic(string? languageCode)
    {
        return NormalizeLanguageCode(languageCode);
    }
}

