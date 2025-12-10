using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Moq;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Tests.Helpers;

/// <summary>
/// Controller testleri için helper metodlar
/// </summary>
public static class ControllerTestHelpers
{
    /// <summary>
    /// Mock IUnitOfWork oluşturur
    /// </summary>
    public static Mock<IUnitOfWork> CreateMockUnitOfWork()
    {
        return new Mock<IUnitOfWork>();
    }

    /// <summary>
    /// Mock ILogger oluşturur
    /// </summary>
    public static ILogger<T> CreateMockLogger<T>()
    {
        return new Mock<ILogger<T>>().Object;
    }

    /// <summary>
    /// Mock ILocalizationService oluşturur
    /// </summary>
    public static Mock<ILocalizationService> CreateMockLocalizationService()
    {
        var mock = new Mock<ILocalizationService>();
        mock.Setup(x => x.GetLocalizedString(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<System.Globalization.CultureInfo>(), It.IsAny<object[]>()))
            .Returns((string resource, string key, System.Globalization.CultureInfo culture, object[] args) => key);
        return mock;
    }

    /// <summary>
    /// Mock IUserContextService oluşturur
    /// </summary>
    public static Mock<IUserContextService> CreateMockUserContextService(string? userId = null)
    {
        var mock = new Mock<IUserContextService>();
        mock.Setup(x => x.GetUserId()).Returns(userId ?? Guid.NewGuid().ToString());
        return mock;
    }

    /// <summary>
    /// Mock IConfiguration oluşturur
    /// </summary>
    public static IConfiguration CreateMockConfiguration(Dictionary<string, string>? settings = null)
    {
        var configData = new Dictionary<string, string?>
        {
            { "GoogleMaps:ApiKey", "test-api-key-12345" }
        };

        if (settings != null)
        {
            foreach (var setting in settings)
            {
                configData[setting.Key] = setting.Value;
            }
        }

        return new ConfigurationBuilder()
            .AddInMemoryCollection(configData)
            .Build();
    }

    /// <summary>
    /// Controller için HttpContext oluşturur
    /// </summary>
    public static ControllerContext CreateControllerContext(string? language = null)
    {
        var httpContext = new DefaultHttpContext();
        
        if (!string.IsNullOrEmpty(language))
        {
            httpContext.Request.Headers["Accept-Language"] = language;
        }

        return new ControllerContext
        {
            HttpContext = httpContext
        };
    }
}

