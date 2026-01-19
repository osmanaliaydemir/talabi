using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Text;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// Contract tests for endpoints that Flutter calls after authentication:
/// - /orders
/// - /orders/{id}, /orders/{id}/detail (shape expectations)
/// - /cart
/// - /profile & /profile/notification-settings
/// </summary>
public class MobileOrdersCartProfileContractTests : IClassFixture<TalabiApiMobileContractFactory>
{
    private readonly TalabiApiMobileContractFactory _factory;

    public MobileOrdersCartProfileContractTests(TalabiApiMobileContractFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task OrdersList_WhenAuthenticated_Returns200_WithApiResponseAndArrayData()
    {
        var client = await CreateAuthenticatedClientAsync();

        var response = await client.GetAsync("/api/orders");
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeTrue();
        Get(doc.RootElement, "data").ValueKind.Should().Be(JsonValueKind.Array);
    }

    [Fact]
    public async Task OrdersGet_WhenOrderDoesNotExist_Returns404_WithErrorCode()
    {
        var client = await CreateAuthenticatedClientAsync();

        var response = await client.GetAsync($"/api/orders/{Guid.NewGuid():D}");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeFalse();
        GetString(doc.RootElement, "errorCode").Should().Be("ORDER_NOT_FOUND");
    }

    [Fact]
    public async Task OrdersDetail_WhenOrderDoesNotExist_Returns404_WithErrorCode()
    {
        var client = await CreateAuthenticatedClientAsync();

        var response = await client.GetAsync($"/api/orders/{Guid.NewGuid():D}/detail");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeFalse();
        GetString(doc.RootElement, "errorCode").Should().Be("ORDER_NOT_FOUND");
    }

    [Fact]
    public async Task CartGet_WhenAuthenticated_Returns200_WithItemsArray()
    {
        var client = await CreateAuthenticatedClientAsync();

        var response = await client.GetAsync("/api/cart");
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeTrue();

        var data = Get(doc.RootElement, "data");
        // Flutter expects a Map; at minimum ensure "items" is present and is array
        Get(data, "items").ValueKind.Should().Be(JsonValueKind.Array);
    }

    [Fact]
    public async Task ProfileGet_WhenAuthenticated_Returns200_WithObjectData()
    {
        var client = await CreateAuthenticatedClientAsync();

        var response = await client.GetAsync("/api/profile");
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeTrue();
        Get(doc.RootElement, "data").ValueKind.Should().Be(JsonValueKind.Object);
    }

    [Fact]
    public async Task NotificationSettingsGet_WhenAuthenticated_Returns200_WithExpectedFields()
    {
        var client = await CreateAuthenticatedClientAsync();

        var response = await client.GetAsync("/api/profile/notification-settings");
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeTrue();

        var data = Get(doc.RootElement, "data");
        Get(data, "orderUpdates").ValueKind.Should().BeOneOf(JsonValueKind.True, JsonValueKind.False);
        Get(data, "promotions").ValueKind.Should().BeOneOf(JsonValueKind.True, JsonValueKind.False);
        Get(data, "newProducts").ValueKind.Should().BeOneOf(JsonValueKind.True, JsonValueKind.False);
    }

    private async Task<HttpClient> CreateAuthenticatedClientAsync()
    {
        var client = _factory.CreateClient();

        // Register -> VerifyEmailCode -> Login (mirrors mobile expected flow)
        await EnsureRoleExistsAsync("Customer");

        var email = $"mobile_{Guid.NewGuid():N}@example.com";
        var password = "Test123!@#";
        var fullName = "Mobile User";

        var registerResp = await client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password,
            fullName,
            language = "tr"
        });
        registerResp.EnsureSuccessStatusCode();

        var code = _factory.EmailSender.GetLastVerificationCode(email);
        code.Should().NotBeNullOrWhiteSpace();

        var verifyResp = await client.PostAsJsonAsync("/api/auth/verify-email-code", new
        {
            email,
            code
        });
        verifyResp.EnsureSuccessStatusCode();

        var loginResp = await client.PostAsJsonAsync("/api/auth/login", new { email, password });
        loginResp.EnsureSuccessStatusCode();

        using var doc = JsonDocument.Parse(await loginResp.Content.ReadAsStringAsync());
        var token = GetString(Get(doc.RootElement, "data"), "token");
        token.Should().NotBeNullOrWhiteSpace();

        // Sanity check: token should validate with current host configuration
        using (var scope = _factory.Services.CreateScope())
        {
            var cfg = scope.ServiceProvider.GetRequiredService<IConfiguration>();
            var jwtSettings = cfg.GetSection("JwtSettings");
            var secret = jwtSettings["Secret"];
            var issuer = jwtSettings["Issuer"];
            var audience = jwtSettings["Audience"];

            secret.Should().NotBeNullOrWhiteSpace();
            issuer.Should().NotBeNullOrWhiteSpace();
            audience.Should().NotBeNullOrWhiteSpace();

            var handler = new JwtSecurityTokenHandler();
            handler.ValidateToken(token, new TokenValidationParameters
            {
                ValidateIssuer = true,
                ValidateAudience = true,
                ValidateLifetime = true,
                ValidateIssuerSigningKey = true,
                ValidIssuer = issuer,
                ValidAudience = audience,
                IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret!))
            }, out _);
        }

        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    private async Task EnsureRoleExistsAsync(string roleName)
    {
        using var scope = _factory.Services.CreateScope();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();

        if (!await roleManager.RoleExistsAsync(roleName))
        {
            var result = await roleManager.CreateAsync(new IdentityRole(roleName));
            result.Succeeded.Should().BeTrue();
        }
    }

    private static JsonElement Get(JsonElement obj, string name)
    {
        foreach (var prop in obj.EnumerateObject())
        {
            if (string.Equals(prop.Name, name, StringComparison.OrdinalIgnoreCase))
                return prop.Value;
        }

        throw new Xunit.Sdk.XunitException($"Expected JSON property '{name}' (case-insensitive).");
    }

    private static string? GetString(JsonElement obj, string name)
    {
        var el = Get(obj, name);
        return el.ValueKind == JsonValueKind.Null ? null : el.GetString();
    }

    private static bool GetBool(JsonElement obj, string name)
    {
        var el = Get(obj, name);
        return el.GetBoolean();
    }
}

