using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// Contract tests that mirror Flutter's auth + cart expectations.
/// </summary>
public class MobileAuthFlowContractTests : IClassFixture<TalabiApiMobileContractFactory>
{
    private readonly TalabiApiMobileContractFactory _factory;
    private readonly HttpClient _client;

    public MobileAuthFlowContractTests(TalabiApiMobileContractFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task Register_VerifyEmailCode_Login_ReturnsMobileExpectedFields()
    {
        // Arrange
        await EnsureRoleExistsAsync("Customer");

        var email = $"mobile_{Guid.NewGuid():N}@example.com";
        var password = "Test123!@#";
        var fullName = "Mobile User";

        // Act 1: register
        var registerResp = await _client.PostAsJsonAsync("/api/auth/register", new
        {
            email,
            password,
            fullName,
            language = "tr"
        });

        // Assert 1
        registerResp.StatusCode.Should().Be(HttpStatusCode.OK);
        using (var doc = JsonDocument.Parse(await registerResp.Content.ReadAsStringAsync()))
        {
            GetBool(doc.RootElement, "success").Should().BeTrue();
        }

        // Get code captured from email sender
        var code = _factory.EmailSender.GetLastVerificationCode(email);
        code.Should().NotBeNullOrWhiteSpace("register should send a verification code email");

        // Act 2: verify email code
        var verifyResp = await _client.PostAsJsonAsync("/api/auth/verify-email-code", new
        {
            email,
            code
        });

        verifyResp.StatusCode.Should().Be(HttpStatusCode.OK);
        using (var doc = JsonDocument.Parse(await verifyResp.Content.ReadAsStringAsync()))
        {
            GetBool(doc.RootElement, "success").Should().BeTrue();
        }

        // Act 3: login
        var loginResp = await _client.PostAsJsonAsync("/api/auth/login", new
        {
            email,
            password
        });

        // Assert 3: shape matches what Flutter reads in AuthProvider.login()
        loginResp.StatusCode.Should().Be(HttpStatusCode.OK);
        using var loginDoc = JsonDocument.Parse(await loginResp.Content.ReadAsStringAsync());
        GetBool(loginDoc.RootElement, "success").Should().BeTrue();

        var data = Get(loginDoc.RootElement, "data");

        GetString(data, "token").Should().NotBeNullOrWhiteSpace();
        GetString(data, "refreshToken").Should().NotBeNullOrWhiteSpace();
        GetString(data, "userId").Should().NotBeNullOrWhiteSpace();
        GetString(data, "email").Should().Be(email);
        // fullName is nullable in backend but mobile expects it populated
        GetString(data, "fullName").Should().NotBeNullOrWhiteSpace();
        GetString(data, "role").Should().NotBeNullOrWhiteSpace();

        // These flags are used heavily by mobile routing/UX
        GetBool(data, "isActive").Should().BeTrue();
        GetBool(data, "isProfileComplete").Should().BeTrue();
        GetBool(data, "hasDeliveryZones").Should().BeFalse();
    }

    [Fact]
    public async Task Login_WhenInvalidCredentials_Returns401_WithApiResponseEnvelope()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/login", new
        {
            email = "nonexistent@example.com",
            password = "WrongPassword123!"
        });

        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeFalse();
        GetString(doc.RootElement, "errorCode").Should().Be("INVALID_CREDENTIALS");
    }

    [Fact]
    public async Task Cart_Get_WhenAnonymous_Returns401()
    {
        var response = await _client.GetAsync("/api/cart");
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Banners_WhenEmpty_Returns200_WithArrayData()
    {
        var response = await _client.GetAsync("/api/banners");
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeTrue();
        Get(doc.RootElement, "data").ValueKind.Should().Be(JsonValueKind.Array);
    }

    [Fact]
    public async Task Content_LegalTypes_WhenEmpty_Returns200_WithArrayData()
    {
        var response = await _client.GetAsync("/api/content/legal/types");
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeTrue();
        Get(doc.RootElement, "data").ValueKind.Should().Be(JsonValueKind.Array);
    }

    [Fact]
    public async Task Content_LegalDocument_WhenMissing_Returns404_WithApiResponseEnvelope()
    {
        var response = await _client.GetAsync("/api/content/legal/terms-of-use?lang=tr");
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeFalse();
        GetString(doc.RootElement, "errorCode").Should().Be("LEGAL_DOCUMENT_NOT_FOUND");
    }

    private async Task EnsureRoleExistsAsync(string roleName)
    {
        using var scope = _factory.Services.CreateScope();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();

        if (!await roleManager.RoleExistsAsync(roleName))
        {
            var result = await roleManager.CreateAsync(new IdentityRole(roleName));
            result.Succeeded.Should().BeTrue($"Role '{roleName}' should be creatable for tests");
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

