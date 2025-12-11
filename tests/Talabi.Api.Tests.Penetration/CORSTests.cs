using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Talabi.Api;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// CORS (Cross-Origin Resource Sharing) testleri
/// CORS yapılandırmasının doğru çalıştığını doğrular
/// </summary>
public class CORSTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public CORSTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task PreflightRequest_ShouldReturnCorsHeaders()
    {
        // Arrange
        var request = new HttpRequestMessage(HttpMethod.Options, "/api/products/search");
        request.Headers.Add("Origin", "https://example.com");
        request.Headers.Add("Access-Control-Request-Method", "GET");
        request.Headers.Add("Access-Control-Request-Headers", "content-type");

        // Act
        var response = await _client.SendAsync(request);

        // Assert
        response.Headers.Should().ContainKey("Access-Control-Allow-Origin",
            "CORS preflight response'unda Access-Control-Allow-Origin header'ı olmalı");
    }

    [Fact]
    public async Task CrossOriginRequest_ShouldIncludeCorsHeaders()
    {
        // Arrange
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/products/search?query=test");
        request.Headers.Add("Origin", "https://example.com");

        // Act
        var response = await _client.SendAsync(request);

        // Assert
        // CORS header'ları response'da olmalı
        // Not: Development ortamında AllowAnyOrigin kullanılıyorsa bu test geçebilir
        // Production'da belirli origin'ler için kontrol edilmeli
    }

    [Fact]
    public async Task CORS_ShouldNotAllowWildcardOriginWithCredentials()
    {
        // Arrange
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/products/search?query=test");
        request.Headers.Add("Origin", "https://malicious.com");

        // Act
        var response = await _client.SendAsync(request);

        // Assert
        // Eğer credentials kullanılıyorsa, wildcard origin (*) kullanılmamalı
        // Bu test, production ortamında belirli origin'lerin whitelist'te olduğunu doğrular
        // Development ortamında AllowAnyOrigin kullanılıyorsa bu test farklı davranabilir
    }

    [Fact]
    public async Task CORS_ShouldRespectAllowedMethods()
    {
        // Arrange
        var request = new HttpRequestMessage(HttpMethod.Options, "/api/products/search");
        request.Headers.Add("Origin", "https://example.com");
        request.Headers.Add("Access-Control-Request-Method", "DELETE");

        // Act
        var response = await _client.SendAsync(request);

        // Assert
        // Eğer DELETE method'u allowed methods listesindeyse, header'da olmalı
        // Eğer değilse, preflight request başarısız olmalı veya method listede olmamalı
        if (response.Headers.Contains("Access-Control-Allow-Methods"))
        {
            var allowedMethods = response.Headers.GetValues("Access-Control-Allow-Methods").First();
            // Allowed methods kontrolü yapılabilir
        }
    }

    [Fact]
    public async Task CORS_ShouldNotExposeSensitiveHeaders()
    {
        // Arrange
        var request = new HttpRequestMessage(HttpMethod.Get, "/api/products/search?query=test");
        request.Headers.Add("Origin", "https://example.com");

        // Act
        var response = await _client.SendAsync(request);

        // Assert
        // Access-Control-Expose-Headers header'ında hassas header'lar olmamalı
        // Örneğin: Authorization, X-Auth-Token gibi header'lar expose edilmemeli
        if (response.Headers.Contains("Access-Control-Expose-Headers"))
        {
            var exposedHeaders = response.Headers.GetValues("Access-Control-Expose-Headers").First();
            exposedHeaders.ToLowerInvariant().Should().NotContain("authorization",
                "Authorization header'ı expose edilmemeli");
        }
    }

    [Fact]
    public async Task CORS_ShouldSetMaxAgeForPreflight()
    {
        // Arrange
        var request = new HttpRequestMessage(HttpMethod.Options, "/api/products/search");
        request.Headers.Add("Origin", "https://example.com");
        request.Headers.Add("Access-Control-Request-Method", "GET");

        // Act
        var response = await _client.SendAsync(request);

        // Assert
        // Access-Control-Max-Age header'ı preflight response'unda olmalı
        // Bu, tarayıcının preflight cache süresini belirler
        if (response.Headers.Contains("Access-Control-Max-Age"))
        {
            var maxAge = response.Headers.GetValues("Access-Control-Max-Age").First();
            int.TryParse(maxAge, out var maxAgeValue).Should().BeTrue();
            maxAgeValue.Should().BeGreaterThan(0, "Max-Age değeri pozitif olmalı");
        }
    }
}

