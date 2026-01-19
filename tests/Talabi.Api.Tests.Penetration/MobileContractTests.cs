using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// Mobile-facing API contract tests.
/// Goal: lock down HTTP status codes + JSON response shape (without DB dependency).
/// </summary>
public class MobileContractTests : IClassFixture<TalabiApiTestFactory>
{
    private readonly HttpClient _client;

    public MobileContractTests(TalabiApiTestFactory factory)
    {
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task ProductsSearch_WhenUserLocationMissing_ReturnsApiResponseWithEmptyPagedResultShape()
    {
        // Act
        var response = await _client.GetAsync("/api/products/search?query=test");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        AssertApiResponseShape(doc.RootElement);

        var success = GetPropertyIgnoreCase(doc.RootElement, "success").GetBoolean();
        success.Should().BeTrue();

        var data = GetPropertyIgnoreCase(doc.RootElement, "data");
        var items = GetPropertyIgnoreCase(data, "items");
        items.ValueKind.Should().Be(JsonValueKind.Array);
    }

    [Fact]
    public async Task VendorsList_WhenUserLocationMissing_ReturnsApiResponseWithEmptyPagedResultShape()
    {
        // Act
        var response = await _client.GetAsync("/api/vendors");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.OK);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        AssertApiResponseShape(doc.RootElement);

        var success = GetPropertyIgnoreCase(doc.RootElement, "success").GetBoolean();
        success.Should().BeTrue();

        var data = GetPropertyIgnoreCase(doc.RootElement, "data");
        var items = GetPropertyIgnoreCase(data, "items");
        items.ValueKind.Should().Be(JsonValueKind.Array);
    }

    [Fact]
    public async Task OrdersCancel_WhenAnonymous_Returns401()
    {
        // Arrange
        var orderId = Guid.NewGuid();
        var cancelDto = new { Reason = "Test cancellation" };

        // Act
        var response = await _client.PostAsJsonAsync($"/api/orders/{orderId}/cancel", cancelDto);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task RefreshToken_WhenTokenIsMalformed_Returns400WithInvalidTokenErrorCode()
    {
        // Arrange (intentionally malformed)
        var dto = new { Token = "not-a-jwt", RefreshToken = "anything" };

        // Act
        var response = await _client.PostAsJsonAsync("/api/auth/refresh-token", dto);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        AssertApiResponseShape(doc.RootElement);

        var success = GetPropertyIgnoreCase(doc.RootElement, "success").GetBoolean();
        success.Should().BeFalse();

        var errorCode = GetPropertyIgnoreCase(doc.RootElement, "errorCode").GetString();
        errorCode.Should().Be("INVALID_TOKEN");
    }

    private static void AssertApiResponseShape(JsonElement root)
    {
        root.ValueKind.Should().Be(JsonValueKind.Object);

        // Expect ApiResponse<T> envelope (camelCase under ASP.NET default JSON settings)
        var successKind = GetPropertyIgnoreCase(root, "success").ValueKind;
        successKind.Should().BeOneOf(JsonValueKind.True, JsonValueKind.False);

        // Optional fields (must exist or be null when present)
        // We don't force presence of message/errors/errorCode because some success responses may omit them,
        // but if present, they must be the correct kinds.
        if (TryGetPropertyIgnoreCase(root, "message", out var message))
            message.ValueKind.Should().BeOneOf(JsonValueKind.String, JsonValueKind.Null);

        if (TryGetPropertyIgnoreCase(root, "data", out var data))
            data.ValueKind.Should().NotBe(JsonValueKind.Undefined);

        if (TryGetPropertyIgnoreCase(root, "errorCode", out var errorCode))
            errorCode.ValueKind.Should().BeOneOf(JsonValueKind.String, JsonValueKind.Null);

        if (TryGetPropertyIgnoreCase(root, "errors", out var errors))
            errors.ValueKind.Should().BeOneOf(JsonValueKind.Array, JsonValueKind.Null);
    }

    private static JsonElement GetPropertyIgnoreCase(JsonElement obj, string name)
    {
        if (TryGetPropertyIgnoreCase(obj, name, out var value))
            return value;

        throw new Xunit.Sdk.XunitException($"Expected JSON object to contain property '{name}' (case-insensitive).");
    }

    private static bool TryGetPropertyIgnoreCase(JsonElement obj, string name, out JsonElement value)
    {
        foreach (var prop in obj.EnumerateObject())
        {
            if (string.Equals(prop.Name, name, StringComparison.OrdinalIgnoreCase))
            {
                value = prop.Value;
                return true;
            }
        }

        value = default;
        return false;
    }
}

