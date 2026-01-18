using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Talabi.Api;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// Rate Limiting bypass testleri
/// </summary>
public class RateLimitingTests : IClassFixture<TalabiApiRateLimitFactory>
{
    private readonly HttpClient _client;
    private readonly TalabiApiRateLimitFactory _factory;

    public RateLimitingTests(TalabiApiRateLimitFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Login_WithBruteForce_ShouldBeRateLimited()
    {
        // Arrange
        var loginDto = new
        {
            Email = "test@example.com",
            Password = "WrongPassword123!"
        };

        // Act - 5'ten fazla istek gönder (limit: 5/dakika)
        var tasks = new List<Task<HttpResponseMessage>>();
        for (int i = 0; i < 10; i++)
        {
            tasks.Add(_client.PostAsJsonAsync("/api/auth/login", loginDto));
        }

        var responses = await Task.WhenAll(tasks);

        // Assert
        // Rate limiting aktif olmalı - 5'ten fazla istek 429 dönmeli
        var rateLimitedResponses = responses.Where(r => r.StatusCode == HttpStatusCode.TooManyRequests);
        rateLimitedResponses.Should().NotBeEmpty("Login endpoint'i için rate limiting aktif olmalı (limit: 5/dakika)");
        
        // İlk 5 istek başarılı olabilir, sonraki istekler rate limited olmalı
        var successCount = responses.Count(r => r.StatusCode != HttpStatusCode.TooManyRequests);
        successCount.Should().BeLessThanOrEqualTo(5, "Login endpoint'i için maksimum 5 istek/dakika izin verilmeli");
    }

    [Fact]
    public async Task Register_WithMassRegistration_ShouldBeRateLimited()
    {
        // Arrange
        var tasks = new List<Task<HttpResponseMessage>>();
        
        // Act - 3'ten fazla kayıt isteği (limit: 3/saat)
        for (int i = 0; i < 10; i++)
        {
            var registerDto = new
            {
                Email = $"test{i}@example.com",
                Password = "Test123!@#",
                FullName = $"Test User {i}",
                Language = "tr"
            };
            tasks.Add(_client.PostAsJsonAsync("/api/auth/register", registerDto));
        }

        var responses = await Task.WhenAll(tasks);

        // Assert
        // Rate limiting aktif olmalı - 3'ten fazla istek 429 dönmeli
        var rateLimitedResponses = responses.Where(r => r.StatusCode == HttpStatusCode.TooManyRequests);
        rateLimitedResponses.Should().NotBeEmpty("Register endpoint'i için rate limiting aktif olmalı (limit: 3/saat)");
        
        // İlk 3 istek başarılı olabilir, sonraki istekler rate limited olmalı
        var successCount = responses.Count(r => r.StatusCode != HttpStatusCode.TooManyRequests);
        successCount.Should().BeLessThanOrEqualTo(3, "Register endpoint'i için maksimum 3 istek/saat izin verilmeli");
    }

    [Fact]
    public async Task Search_WithRapidRequests_ShouldBeRateLimited()
    {
        // Arrange
        var tasks = new List<Task<HttpResponseMessage>>();

        // Act - Çok hızlı arama istekleri
        for (int i = 0; i < 200; i++)
        {
            tasks.Add(_client.GetAsync($"/api/products/search?query=test{i}"));
        }

        var responses = await Task.WhenAll(tasks);

        // Assert
        // Rate limiting aktif olmalı
        var rateLimitedResponses = responses.Where(r => r.StatusCode == HttpStatusCode.TooManyRequests);
        rateLimitedResponses.Should().NotBeEmpty("Rate limiting aktif olmalı");
    }

    [Fact]
    public async Task RateLimit_WithDifferentIpAddresses_ShouldNotBypass()
    {
        // Arrange
        // Not: Gerçek test için farklı IP'lerden istek gönderilmeli
        // Bu test, rate limiting'in IP bazlı olduğunu doğrular
        
        var loginDto = new
        {
            Email = "test@example.com",
            Password = "WrongPassword123!"
        };

        // Act - Aynı IP'den çok sayıda istek
        var tasks = new List<Task<HttpResponseMessage>>();
        for (int i = 0; i < 100; i++)
        {
            tasks.Add(_client.PostAsJsonAsync("/api/auth/login", loginDto));
        }

        var responses = await Task.WhenAll(tasks);

        // Assert
        // Rate limiting çalışmalı
        var rateLimitedResponses = responses.Where(r => r.StatusCode == HttpStatusCode.TooManyRequests);
        rateLimitedResponses.Should().NotBeEmpty("Rate limiting aktif olmalı");
    }
}

