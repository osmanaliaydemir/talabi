using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Talabi.Api;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// Security Headers testleri
/// SecurityHeadersMiddleware'in doğru header'ları eklediğini doğrular
/// </summary>
public class SecurityHeadersTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public SecurityHeadersTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Response_ShouldIncludeContentSecurityPolicy()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/api/products/search?query=test");

        // Assert
        response.Headers.Should().ContainKey("Content-Security-Policy",
            "Content-Security-Policy header'ı olmalı");
        
        var csp = response.Headers.GetValues("Content-Security-Policy").First();
        csp.Should().Contain("default-src 'self'", "CSP default-src directive olmalı");
        csp.Should().Contain("frame-ancestors 'none'", "CSP frame-ancestors 'none' olmalı");
    }

    [Fact]
    public async Task Response_ShouldNotIncludeUnsafeInlineInScriptSrc()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/api/products/search?query=test");

        // Assert
        response.Headers.Should().ContainKey("Content-Security-Policy",
            "Content-Security-Policy header'ı olmalı");
        
        var csp = response.Headers.GetValues("Content-Security-Policy").First();
        // script-src 'self' olmalı, unsafe-inline ve unsafe-eval olmamalı
        csp.Should().Contain("script-src 'self'", "CSP script-src 'self' olmalı");
        csp.Should().NotContain("script-src 'self' 'unsafe-inline'", 
            "CSP script-src'de unsafe-inline olmamalı (XSS koruması)");
        csp.Should().NotContain("script-src 'self' 'unsafe-eval'", 
            "CSP script-src'de unsafe-eval olmamalı (XSS koruması)");
    }

    [Fact]
    public async Task Response_ShouldHaveSecureCSPConfiguration()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/api/products/search?query=test");

        // Assert
        response.Headers.Should().ContainKey("Content-Security-Policy",
            "Content-Security-Policy header'ı olmalı");
        
        var csp = response.Headers.GetValues("Content-Security-Policy").First();
        
        // Güvenli CSP yapılandırması kontrolü
        csp.Should().Contain("default-src 'self'", "default-src 'self' olmalı");
        csp.Should().Contain("script-src 'self'", "script-src 'self' olmalı");
        csp.Should().Contain("frame-ancestors 'none'", "frame-ancestors 'none' olmalı (clickjacking koruması)");
        
        // Güvenlik açıkları olmamalı
        var scriptSrcMatch = System.Text.RegularExpressions.Regex.Match(csp, @"script-src\s+([^;]+)");
        if (scriptSrcMatch.Success)
        {
            var scriptSrc = scriptSrcMatch.Groups[1].Value;
            scriptSrc.Should().NotContain("unsafe-inline", 
                "script-src'de unsafe-inline olmamalı");
            scriptSrc.Should().NotContain("unsafe-eval", 
                "script-src'de unsafe-eval olmamalı");
        }
    }

    [Fact]
    public async Task Response_ShouldIncludeXFrameOptions()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/api/products/search?query=test");

        // Assert
        response.Headers.Should().ContainKey("X-Frame-Options",
            "X-Frame-Options header'ı olmalı");
        
        var xFrameOptions = response.Headers.GetValues("X-Frame-Options").First();
        xFrameOptions.Should().Be("DENY", "X-Frame-Options DENY olmalı (clickjacking koruması)");
    }

    [Fact]
    public async Task Response_ShouldIncludeXContentTypeOptions()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/api/products/search?query=test");

        // Assert
        response.Headers.Should().ContainKey("X-Content-Type-Options",
            "X-Content-Type-Options header'ı olmalı");
        
        var xContentTypeOptions = response.Headers.GetValues("X-Content-Type-Options").First();
        xContentTypeOptions.Should().Be("nosniff", 
            "X-Content-Type-Options nosniff olmalı (MIME type sniffing koruması)");
    }

    [Fact]
    public async Task Response_ShouldIncludeXXSSProtection()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/api/products/search?query=test");

        // Assert
        response.Headers.Should().ContainKey("X-XSS-Protection",
            "X-XSS-Protection header'ı olmalı (eski tarayıcılar için)");
        
        var xXssProtection = response.Headers.GetValues("X-XSS-Protection").First();
        xXssProtection.Should().Be("1; mode=block", 
            "X-XSS-Protection 1; mode=block olmalı");
    }

    [Fact]
    public async Task Response_ShouldIncludeReferrerPolicy()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/api/products/search?query=test");

        // Assert
        response.Headers.Should().ContainKey("Referrer-Policy",
            "Referrer-Policy header'ı olmalı");
        
        var referrerPolicy = response.Headers.GetValues("Referrer-Policy").First();
        referrerPolicy.Should().Contain("strict-origin-when-cross-origin",
            "Referrer-Policy strict-origin-when-cross-origin olmalı");
    }

    [Fact]
    public async Task Response_ShouldIncludePermissionsPolicy()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/api/products/search?query=test");

        // Assert
        response.Headers.Should().ContainKey("Permissions-Policy",
            "Permissions-Policy header'ı olmalı");
        
        var permissionsPolicy = response.Headers.GetValues("Permissions-Policy").First();
        permissionsPolicy.Should().Contain("geolocation=()",
            "Permissions-Policy geolocation=() olmalı");
        permissionsPolicy.Should().Contain("microphone=()",
            "Permissions-Policy microphone=() olmalı");
        permissionsPolicy.Should().Contain("camera=()",
            "Permissions-Policy camera=() olmalı");
    }

    [Fact]
    public async Task Response_ShouldNotIncludeServerHeader()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/api/products/search?query=test");

        // Assert
        response.Headers.Should().NotContainKey("Server",
            "Server header'ı olmamalı (bilgi açığa çıkması riski)");
    }

    [Fact]
    public async Task Response_ShouldNotIncludeXPoweredByHeader()
    {
        // Arrange & Act
        var response = await _client.GetAsync("/api/products/search?query=test");

        // Assert
        response.Headers.Should().NotContainKey("X-Powered-By",
            "X-Powered-By header'ı olmamalı (framework bilgisi açığa çıkması riski)");
    }
}

