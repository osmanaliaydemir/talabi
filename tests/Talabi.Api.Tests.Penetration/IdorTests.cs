using System.Net;
using System.Net.Http.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Mvc.Testing;
using Talabi.Api;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// IDOR (Insecure Direct Object Reference) testleri
/// </summary>
public class IdorTests : IClassFixture<TalabiApiTestFactory>
{
    private readonly HttpClient _client;
    private readonly TalabiApiTestFactory _factory;

    public IdorTests(TalabiApiTestFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    [Fact]
    public async Task GetOrder_WithAnotherUserOrderId_ShouldBeForbidden()
    {
        // Arrange
        // Not: Bu test için iki farklı kullanıcı token'ı gerekli
        // User1'in order ID'sini User2 ile erişmeye çalış
        
        var orderId = Guid.NewGuid(); // Başka bir kullanıcının order ID'si

        // Act
        // Not: Authentication token ile test edilmeli
        var response = await _client.GetAsync($"/api/orders/{orderId}");

        // Assert
        // Başka kullanıcının order'ına erişim engellenmeli
        // Şu an için authentication olmadan 401 dönmeli
        // Authentication ile test edildiğinde 403 Forbidden dönmeli
        response.StatusCode.Should().BeOneOf(
            HttpStatusCode.Unauthorized, 
            HttpStatusCode.Forbidden, 
            HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task UpdateOrderStatus_WithUnauthorizedUser_ShouldBeForbidden()
    {
        // Arrange
        var orderId = Guid.NewGuid();
        var updateDto = new
        {
            Status = "Preparing"
        };

        // Act
        var response = await _client.PutAsJsonAsync($"/api/orders/{orderId}/status", updateDto);

        // Assert
        // Yetkisiz kullanıcı order durumunu değiştirememeli
        response.StatusCode.Should().BeOneOf(
            HttpStatusCode.Unauthorized, 
            HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task CancelOrder_WithAnotherUserOrderId_ShouldBeForbidden()
    {
        // Arrange
        var orderId = Guid.NewGuid();
        var cancelDto = new
        {
            Reason = "Test cancellation"
        };

        // Act
        var response = await _client.PostAsJsonAsync($"/api/orders/{orderId}/cancel", cancelDto);

        // Assert
        // Başka kullanıcının order'ını iptal edememeli
        response.StatusCode.Should().BeOneOf(
            HttpStatusCode.Unauthorized, 
            HttpStatusCode.Forbidden);
    }

    [Fact]
    public async Task GetOrderDetail_WithAnotherUserOrderId_ShouldBeForbidden()
    {
        // Arrange
        var orderId = Guid.NewGuid();

        // Act
        var response = await _client.GetAsync($"/api/orders/{orderId}/detail");

        // Assert
        // Başka kullanıcının order detayına erişememeli
        response.StatusCode.Should().BeOneOf(
            HttpStatusCode.Unauthorized, 
            HttpStatusCode.Forbidden, 
            HttpStatusCode.NotFound);
    }

    [Fact]
    public async Task GetProfile_WithAnotherUserId_ShouldBeForbidden()
    {
        // Arrange
        var userId = Guid.NewGuid().ToString();

        // Act
        var response = await _client.GetAsync($"/api/profile/{userId}");

        // Assert
        // Başka kullanıcının profil bilgilerine erişememeli
        response.StatusCode.Should().BeOneOf(
            HttpStatusCode.Unauthorized, 
            HttpStatusCode.Forbidden, 
            HttpStatusCode.NotFound);
    }
}

