using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Talabi.Api;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// SQL Injection ve XSS testleri
/// </summary>
public class InjectionTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public InjectionTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Theory]
    [InlineData("' OR '1'='1")]
    [InlineData("'; DROP TABLE Users; --")]
    [InlineData("' UNION SELECT * FROM Users --")]
    [InlineData("1' OR '1'='1")]
    [InlineData("admin'--")]
    [InlineData("admin'/*")]
    public async Task Search_WithSqlInjection_ShouldNotExecute(string maliciousInput)
    {
        // Arrange
        var searchRequest = new
        {
            Query = maliciousInput,
            Page = 1,
            PageSize = 10
        };

        // Act
        var response = await _client.GetAsync($"/api/products/search?query={Uri.EscapeDataString(maliciousInput)}");

        // Assert
        // SQL injection çalışmamalı - Entity Framework parametreli sorgular kullanmalı
        response.StatusCode.Should().NotBe(HttpStatusCode.InternalServerError, 
            "SQL injection saldırısı başarısız olmalı");
        
        // Hata mesajında SQL detayları olmamalı
        if (response.StatusCode != HttpStatusCode.OK)
        {
            var content = await response.Content.ReadAsStringAsync();
            content.ToLowerInvariant().Should().NotContain("sql");
            content.ToLowerInvariant().Should().NotContain("syntax");
        }
    }

    [Theory]
    [InlineData("<script>alert('XSS')</script>")]
    [InlineData("<img src=x onerror=alert('XSS')>")]
    [InlineData("javascript:alert('XSS')")]
    [InlineData("<svg onload=alert('XSS')>")]
    [InlineData("'><script>alert('XSS')</script>")]
    public async Task Register_WithXssPayload_ShouldBeSanitized(string xssPayload)
    {
        // Arrange
        var registerDto = new
        {
            Email = "test@example.com",
            Password = "Test123!@#",
            FullName = xssPayload, // XSS payload'ı
            Language = "tr"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/auth/register", registerDto);

        // Assert
        // XSS payload sanitize edilmeli
        if (response.StatusCode == HttpStatusCode.OK)
        {
            var content = await response.Content.ReadAsStringAsync();
            // Response'da script tag'leri olmamalı
            content.ToLowerInvariant().Should().NotContain("<script>");
            content.ToLowerInvariant().Should().NotContain("javascript:");
            content.ToLowerInvariant().Should().NotContain("onerror=");
            content.ToLowerInvariant().Should().NotContain("onload=");
        }
    }

    [Theory]
    [InlineData("1; DELETE FROM Orders")]
    [InlineData("1' OR '1'='1")]
    [InlineData("1 UNION SELECT * FROM Users")]
    public async Task GetOrder_WithSqlInjectionInId_ShouldNotExecute(string maliciousId)
    {
        // Arrange
        // Not: Guid formatında olmayan ID'ler zaten reddedilmeli
        // Ama yine de test ediyoruz

        // Act
        var response = await _client.GetAsync($"/api/orders/{maliciousId}");

        // Assert
        // SQL injection çalışmamalı
        response.StatusCode.Should().NotBe(HttpStatusCode.InternalServerError);
        
        var content = await response.Content.ReadAsStringAsync();
        content.ToLowerInvariant().Should().NotContain("sql");
    }

    [Fact]
    public async Task Search_WithCommandInjection_ShouldNotExecute()
    {
        // Arrange
        var maliciousInput = "test; rm -rf /";

        // Act
        var response = await _client.GetAsync($"/api/products/search?query={Uri.EscapeDataString(maliciousInput)}");

        // Assert
        // Command injection çalışmamalı
        response.StatusCode.Should().NotBe(HttpStatusCode.InternalServerError);
    }

    [Theory]
    [InlineData("../../etc/passwd")]
    [InlineData("..\\..\\windows\\system32\\config\\sam")]
    [InlineData("%2e%2e%2f%2e%2e%2fetc%2fpasswd")]
    public async Task GetOrder_WithPathTraversal_ShouldNotAccessFiles(string pathTraversal)
    {
        // Arrange
        // Path traversal saldırısı

        // Act
        var response = await _client.GetAsync($"/api/orders/{pathTraversal}");

        // Assert
        // Path traversal çalışmamalı
        response.StatusCode.Should().NotBe(HttpStatusCode.OK);
    }

    [Fact]
    public async Task Search_WithNoSqlInjection_ShouldNotExecute()
    {
        // Arrange
        // NoSQL injection payload'ı (MongoDB gibi)
        var maliciousInput = "'; return true; var x='";

        // Act
        var response = await _client.GetAsync($"/api/products/search?query={Uri.EscapeDataString(maliciousInput)}");

        // Assert
        // NoSQL injection çalışmamalı (SQL Server kullanılıyor)
        response.StatusCode.Should().NotBe(HttpStatusCode.InternalServerError);
    }
}

