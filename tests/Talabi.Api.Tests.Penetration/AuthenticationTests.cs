using System.Net;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Talabi.Api;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// Authentication ve Authorization güvenlik testleri
/// </summary>
public class AuthenticationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;
    private readonly WebApplicationFactory<Program> _factory;

    public AuthenticationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Login_WithInvalidCredentials_ShouldNotRevealUserExistence()
    {
        // Arrange
        var loginDto = new
        {
            Email = "nonexistent@example.com",
            Password = "WrongPassword123!"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/auth/login", loginDto);

        // Assert
        // Kullanıcının var olup olmadığını açığa çıkarmamalı
        response.StatusCode.Should().BeOneOf(HttpStatusCode.Unauthorized, HttpStatusCode.BadRequest);
        
        var content = await response.Content.ReadAsStringAsync();
        // Hata mesajı genel olmalı, "kullanıcı bulunamadı" gibi spesifik olmamalı
        content.ToLowerInvariant().Should().NotContain("not found");
        content.ToLowerInvariant().Should().NotContain("user");
    }

    [Fact]
    public async Task Register_WithWeakPassword_ShouldBeRejected()
    {
        // Arrange
        var registerDto = new
        {
            Email = "test@example.com",
            Password = "12345", // Çok zayıf şifre
            FullName = "Test User",
            Language = "tr"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/auth/register", registerDto);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task RefreshToken_WithExpiredToken_ShouldBeRejected()
    {
        // Arrange
        var refreshTokenDto = new
        {
            Token = "expired.jwt.token",
            RefreshToken = "invalid_refresh_token"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/auth/refresh-token", refreshTokenDto);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task RefreshToken_WithManipulatedToken_ShouldBeRejected()
    {
        // Arrange
        // JWT token'ın payload'ını manipüle etmeye çalış
        var manipulatedToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c";
        var refreshTokenDto = new
        {
            Token = manipulatedToken,
            RefreshToken = "some_refresh_token"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/auth/refresh-token", refreshTokenDto);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task ExternalLogin_WithInvalidProvider_ShouldBeRejected()
    {
        // Arrange
        var externalAuthDto = new
        {
            Provider = "InvalidProvider",
            Email = "test@example.com",
            Token = "fake_token"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/auth/external-login", externalAuthDto);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
    }

    [Fact]
    public async Task ExternalLogin_WithoutTokenVerification_ShouldBeVulnerable()
    {
        // Arrange
        // Not: Bu test, external login'de token doğrulaması yapılmadığını gösterir
        // Production'da token doğrulaması yapılmalı
        var externalAuthDto = new
        {
            Provider = "Google",
            Email = "attacker@example.com",
            Token = "fake_unverified_token",
            FullName = "Attacker"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/auth/external-login", externalAuthDto);

        // Assert
        // Bu test, token doğrulaması olmadan giriş yapılabildiğini gösterir
        // Bu bir güvenlik açığıdır - token doğrulaması eklenmelidir
        // Şu an için bu test başarılı olabilir çünkü token doğrulaması yok
        // Bu bir güvenlik açığı olduğunu gösterir
    }

    [Fact]
    public async Task ForgotPassword_ShouldNotRevealUserExistence()
    {
        // Arrange
        var forgotPasswordDto = new
        {
            Email = "nonexistent@example.com"
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/auth/forgot-password", forgotPasswordDto);

        // Assert
        // Kullanıcının var olup olmadığını açığa çıkarmamalı
        // Her zaman aynı mesajı döndürmeli
        response.StatusCode.Should().Be(HttpStatusCode.OK);
        
        var content = await response.Content.ReadAsStringAsync();
        // Başarı mesajı dönmeli, kullanıcı bulunamadı gibi bir mesaj olmamalı
        content.ToLowerInvariant().Should().NotContain("not found");
    }

    [Fact]
    public async Task VerifyEmailCode_WithBruteForce_ShouldBeRateLimited()
    {
        // Arrange
        var verifyDto = new
        {
            Email = "test@example.com",
            Code = "000000"
        };

        // Act - Çok sayıda istek gönder
        var tasks = new List<Task<HttpResponseMessage>>();
        for (int i = 0; i < 100; i++)
        {
            tasks.Add(_client.PostAsJsonAsync("/api/auth/verify-email-code", verifyDto));
        }

        var responses = await Task.WhenAll(tasks);

        // Assert
        // Rate limiting olmalı - bazı istekler 429 (Too Many Requests) dönmeli
        var rateLimitedResponses = responses.Where(r => r.StatusCode == HttpStatusCode.TooManyRequests);
        rateLimitedResponses.Should().NotBeEmpty("Rate limiting aktif olmalı");
    }

    [Fact]
    public async Task ConfirmEmail_WithInvalidToken_ShouldNotExposeInformation()
    {
        // Arrange
        var invalidToken = "invalid_token_12345";
        var email = "test@example.com";

        // Act
        var response = await _client.GetAsync($"/api/auth/confirm-email?token={invalidToken}&email={email}");

        // Assert
        // Hata mesajı genel olmalı, detaylı bilgi vermemeli
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        
        var content = await response.Content.ReadAsStringAsync();
        // Sistem detayları açığa çıkmamalı
        content.ToLowerInvariant().Should().NotContain("database");
        content.ToLowerInvariant().Should().NotContain("sql");
    }

    [Fact]
    public async Task ConfirmEmail_WithNullToken_ShouldReturnBadRequest()
    {
        // Arrange
        var email = "test@example.com";

        // Act
        var response = await _client.GetAsync($"/api/auth/confirm-email?token=&email={email}");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        
        var content = await response.Content.ReadAsStringAsync();
        content.Should().Contain("TOKEN_REQUIRED", "Token required hatası dönmeli");
    }

    [Fact]
    public async Task ConfirmEmail_WithNullEmail_ShouldReturnBadRequest()
    {
        // Arrange
        var token = "some_token_12345";

        // Act
        var response = await _client.GetAsync($"/api/auth/confirm-email?token={token}&email=");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        
        var content = await response.Content.ReadAsStringAsync();
        content.Should().Contain("EMAIL_REQUIRED", "Email required hatası dönmeli");
    }

    [Fact]
    public async Task ConfirmEmail_WithInvalidEmailFormat_ShouldReturnBadRequest()
    {
        // Arrange
        var token = "some_token_12345";
        var invalidEmail = "not-an-email";

        // Act
        var response = await _client.GetAsync($"/api/auth/confirm-email?token={token}&email={invalidEmail}");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        
        var content = await response.Content.ReadAsStringAsync();
        content.Should().Contain("INVALID_EMAIL_FORMAT", "Invalid email format hatası dönmeli");
    }

    [Fact]
    public async Task ConfirmEmail_WithInvalidTokenFormat_ShouldReturnBadRequest()
    {
        // Arrange
        // Token çok kısa (10 karakterden az)
        var invalidToken = "short";
        var email = "test@example.com";

        // Act
        var response = await _client.GetAsync($"/api/auth/confirm-email?token={invalidToken}&email={email}");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        
        var content = await response.Content.ReadAsStringAsync();
        content.Should().Contain("INVALID_TOKEN_FORMAT", "Invalid token format hatası dönmeli");
    }

    [Fact]
    public async Task ConfirmEmail_WithTooLongToken_ShouldReturnBadRequest()
    {
        // Arrange
        // Token çok uzun (1000 karakterden fazla)
        var invalidToken = new string('a', 1001);
        var email = "test@example.com";

        // Act
        var response = await _client.GetAsync($"/api/auth/confirm-email?token={invalidToken}&email={email}");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        
        var content = await response.Content.ReadAsStringAsync();
        content.Should().Contain("INVALID_TOKEN_FORMAT", "Invalid token format hatası dönmeli");
    }

    [Fact]
    public async Task ConfirmEmail_WithBruteForce_ShouldBeRateLimited()
    {
        // Arrange
        var token = "some_token_12345";
        var email = "test@example.com";

        // Act - Çok sayıda istek gönder
        var tasks = new List<Task<HttpResponseMessage>>();
        for (int i = 0; i < 100; i++)
        {
            tasks.Add(_client.GetAsync($"/api/auth/confirm-email?token={token}&email={email}"));
        }

        var responses = await Task.WhenAll(tasks);

        // Assert
        // Rate limiting olmalı - bazı istekler 429 (Too Many Requests) dönmeli
        var rateLimitedResponses = responses.Where(r => r.StatusCode == HttpStatusCode.TooManyRequests);
        rateLimitedResponses.Should().NotBeEmpty("Rate limiting aktif olmalı");
    }

    [Fact]
    public async Task ConfirmEmail_WithNonExistentUser_ShouldNotRevealUserExistence()
    {
        // Arrange
        var token = "some_valid_looking_token_12345";
        var email = "nonexistent@example.com";

        // Act
        var response = await _client.GetAsync($"/api/auth/confirm-email?token={token}&email={email}");

        // Assert
        // Kullanıcının var olup olmadığını açığa çıkarmamalı
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        
        var content = await response.Content.ReadAsStringAsync();
        // Hata mesajı genel olmalı, "kullanıcı bulunamadı" gibi spesifik olmamalı
        content.ToLowerInvariant().Should().NotContain("not found");
        content.ToLowerInvariant().Should().NotContain("user");
        content.Should().Contain("INVALID_REQUEST", "Genel invalid request hatası dönmeli");
    }
}

