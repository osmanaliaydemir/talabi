using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// Authentication-related rate limiting tests.
/// These are separated to run with rate limiting enabled.
/// </summary>
public class AuthenticationRateLimitingTests : IClassFixture<TalabiApiRateLimitFactory>
{
    private readonly HttpClient _client;

    public AuthenticationRateLimitingTests(TalabiApiRateLimitFactory factory)
    {
        _client = factory.CreateClient();
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

        // Act - send many requests quickly
        var tasks = new List<Task<HttpResponseMessage>>();
        for (int i = 0; i < 20; i++)
        {
            tasks.Add(_client.PostAsJsonAsync("/api/auth/verify-email-code", verifyDto));
        }

        var responses = await Task.WhenAll(tasks);

        // Assert - some requests should be rate limited
        responses.Any(r => r.StatusCode == HttpStatusCode.TooManyRequests)
            .Should().BeTrue("Rate limiting aktif olmalı");
    }

    [Fact]
    public async Task ConfirmEmail_WithBruteForce_ShouldBeRateLimited()
    {
        // Arrange
        var token = "some_token_12345";
        var email = "test@example.com";

        // Act - send many requests quickly
        var tasks = new List<Task<HttpResponseMessage>>();
        for (int i = 0; i < 20; i++)
        {
            tasks.Add(_client.GetAsync($"/api/auth/confirm-email?token={token}&email={email}"));
        }

        var responses = await Task.WhenAll(tasks);

        // Assert - some requests should be rate limited
        responses.Any(r => r.StatusCode == HttpStatusCode.TooManyRequests)
            .Should().BeTrue("Rate limiting aktif olmalı");
    }
}

