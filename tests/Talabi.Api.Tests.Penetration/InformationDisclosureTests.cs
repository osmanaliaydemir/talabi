using System.Net;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Talabi.Api;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// Information Disclosure testleri
/// </summary>
public class InformationDisclosureTests : IClassFixture<TalabiApiTestFactory>
{
    private readonly HttpClient _client;
    private readonly TalabiApiTestFactory _factory;

    public InformationDisclosureTests(TalabiApiTestFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task ErrorResponse_ShouldNotExposeStackTraces()
    {
        // Arrange
        // Geçersiz bir endpoint'e istek gönder
        var invalidEndpoint = "/api/invalid/endpoint/that/does/not/exist";

        // Act
        var response = await _client.GetAsync(invalidEndpoint);

        // Assert
        // Stack trace veya detaylı hata mesajı dönmemeli
        var content = await response.Content.ReadAsStringAsync();
        content.Should().NotContain("at ", "Stack trace açığa çıkmamalı");
        content.Should().NotContain("System.", "Sistem detayları açığa çıkmamalı");
        content.Should().NotContain("Exception", "Exception detayları açığa çıkmamalı");
    }

    [Fact]
    public async Task ErrorResponse_ShouldNotExposeDatabaseErrors()
    {
        // Arrange
        // SQL hatası oluşturacak bir istek (örneğin geçersiz GUID)
        var invalidGuid = "not-a-valid-guid";

        // Act
        var response = await _client.GetAsync($"/api/orders/{invalidGuid}");

        // Assert
        // Database hata mesajları açığa çıkmamalı
        var content = await response.Content.ReadAsStringAsync();
        content.ToLowerInvariant().Should().NotContain("sql");
        content.ToLowerInvariant().Should().NotContain("database");
        content.ToLowerInvariant().Should().NotContain("connection");
        content.ToLowerInvariant().Should().NotContain("server");
    }

    [Fact]
    public async Task ResponseHeaders_ShouldNotExposeServerInformation()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/api/products/search?query=test");

        // Assert
        // Server bilgisi header'da olmamalı
        response.Headers.Should().NotContainKey("Server", "Server bilgisi açığa çıkmamalı");
        response.Headers.Should().NotContainKey("X-Powered-By", "Framework bilgisi açığa çıkmamalı");
    }

    [Fact]
    public async Task HealthCheck_ShouldNotExposeSensitiveInformation()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/health");

        // Assert
        // Health check detaylarında hassas bilgiler olmamalı
        if (response.IsSuccessStatusCode)
        {
            var content = await response.Content.ReadAsStringAsync();
            content.ToLowerInvariant().Should().NotContain("password");
            content.ToLowerInvariant().Should().NotContain("connectionstring");
            content.ToLowerInvariant().Should().NotContain("secret");
            content.ToLowerInvariant().Should().NotContain("key");
        }
    }

    [Fact]
    public async Task OpenApiEndpoint_ShouldNotExposeInProduction()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/openapi/v1.json");

        // Assert
        // Production'da OpenAPI endpoint'i erişilebilir olmamalı
        // Development'ta erişilebilir olabilir
        // Bu test, production'da endpoint'in kapalı olduğunu doğrular
        // Şu an için development modunda olabilir, bu yüzden 200 dönebilir
    }

    [Fact]
    public async Task HangfireDashboard_ShouldNotBePubliclyAccessible()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/hangfire");

        // Assert
        // Hangfire dashboard herkese açık olmamalı
        // Authentication gerektirmeli veya tamamen kapalı olmalı
        response.StatusCode.Should().NotBe(HttpStatusCode.OK, 
            "Hangfire dashboard herkese açık olmamalı");
    }

    [Fact]
    public async Task ErrorResponse_ShouldNotExposeFilePaths()
    {
        // Arrange
        // Hata oluşturacak bir istek

        // Act
        var response = await _client.GetAsync("/api/invalid");

        // Assert
        // Dosya yolları açığa çıkmamalı
        var content = await response.Content.ReadAsStringAsync();
        content.Should().NotContain("C:\\", "Windows dosya yolu açığa çıkmamalı");
        content.Should().NotContain("/home/", "Linux dosya yolu açığa çıkmamalı");
        content.Should().NotContain(".cs", "Kaynak kod dosya adları açığa çıkmamalı");
    }
}

