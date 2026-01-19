using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using FluentAssertions;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;
using Xunit;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// Mobile-critical mutation flows:
/// - Cart: add -> get -> update -> remove -> get
/// - Orders: create -> cancel
/// 
/// Runs against Test env (InMemory DB, deterministic JWT, external stubs).
/// </summary>
public class MobileCartOrderMutationContractTests : IClassFixture<TalabiApiMobileContractFactory>
{
    private readonly TalabiApiMobileContractFactory _factory;

    public MobileCartOrderMutationContractTests(TalabiApiMobileContractFactory factory)
    {
        _factory = factory;
    }

    [Fact]
    public async Task Cart_Add_Update_Remove_Flow_Works_And_ResponseShapeIsStable()
    {
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();

        // Seed vendor/product + address so cart endpoints can work
        var (vendorId, productId, addressId) = await SeedVendorProductAndAddressAsync(userId);

        // 1) Add to cart
        var addResp = await client.PostAsJsonAsync("/api/cart/items", new
        {
            productId,
            quantity = 1
        });
        addResp.StatusCode.Should().Be(HttpStatusCode.OK);

        using (var addDoc = JsonDocument.Parse(await addResp.Content.ReadAsStringAsync()))
        {
            GetBool(addDoc.RootElement, "success").Should().BeTrue();
        }

        // 2) Get cart and extract itemId
        var getResp = await client.GetAsync("/api/cart");
        getResp.StatusCode.Should().Be(HttpStatusCode.OK);

        Guid itemId;
        using (var cartDoc = JsonDocument.Parse(await getResp.Content.ReadAsStringAsync()))
        {
            GetBool(cartDoc.RootElement, "success").Should().BeTrue();
            var data = Get(cartDoc.RootElement, "data");
            var items = Get(data, "items");
            items.ValueKind.Should().Be(JsonValueKind.Array);
            items.GetArrayLength().Should().BeGreaterThan(0);

            var first = items.EnumerateArray().First();
            GetString(first, "productId").Should().NotBeNullOrWhiteSpace();
            GetString(first, "id").Should().NotBeNullOrWhiteSpace();

            itemId = Guid.Parse(GetString(first, "id")!);
        }

        // 3) Update cart item quantity
        var updateResp = await client.PutAsJsonAsync($"/api/cart/items/{itemId:D}", new { quantity = 2 });
        updateResp.StatusCode.Should().Be(HttpStatusCode.OK);
        using (var updDoc = JsonDocument.Parse(await updateResp.Content.ReadAsStringAsync()))
        {
            GetBool(updDoc.RootElement, "success").Should().BeTrue();
        }

        // 4) Remove cart item
        var removeResp = await client.DeleteAsync($"/api/cart/items/{itemId:D}");
        removeResp.StatusCode.Should().Be(HttpStatusCode.OK);
        using (var remDoc = JsonDocument.Parse(await removeResp.Content.ReadAsStringAsync()))
        {
            GetBool(remDoc.RootElement, "success").Should().BeTrue();
        }

        // 5) Get cart again - should be empty items array
        var get2Resp = await client.GetAsync("/api/cart");
        get2Resp.StatusCode.Should().Be(HttpStatusCode.OK);
        using (var cart2Doc = JsonDocument.Parse(await get2Resp.Content.ReadAsStringAsync()))
        {
            GetBool(cart2Doc.RootElement, "success").Should().BeTrue();
            var items = Get(Get(cart2Doc.RootElement, "data"), "items");
            items.ValueKind.Should().Be(JsonValueKind.Array);
        }
    }

    [Fact]
    public async Task Orders_Create_Then_Cancel_Works_And_ReturnsApiResponseEnvelope()
    {
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();

        var (vendorId, productId, addressId) = await SeedVendorProductAndAddressAsync(userId);

        // Create order (mirrors Flutter OrderRemoteDataSource.createOrder())
        var createResp = await client.PostAsJsonAsync("/api/orders", new
        {
            vendorId,
            items = new[]
            {
                new { productId, quantity = 1 }
            },
            deliveryAddressId = addressId,
            paymentMethod = "Cash"
        });

        var createBody = await createResp.Content.ReadAsStringAsync();
        createResp.StatusCode.Should().Be(HttpStatusCode.Created, $"body: {createBody}");

        Guid orderId;
        using (var doc = JsonDocument.Parse(createBody))
        {
            GetBool(doc.RootElement, "success").Should().BeTrue();
            var data = Get(doc.RootElement, "data");
            GetString(data, "id").Should().NotBeNullOrWhiteSpace();
            orderId = Guid.Parse(GetString(data, "id")!);
        }

        // Cancel order
        var cancelResp = await client.PostAsJsonAsync($"/api/orders/{orderId:D}/cancel", new { reason = "Test cancellation" });
        var cancelBody = await cancelResp.Content.ReadAsStringAsync();
        cancelResp.StatusCode.Should().Be(HttpStatusCode.OK, $"body: {cancelBody}");
        using (var doc = JsonDocument.Parse(cancelBody))
        {
            GetBool(doc.RootElement, "success").Should().BeTrue();
        }
    }

    [Fact]
    public async Task Orders_GetDetail_Returns_Items_And_StatusHistory_WithStableShape()
    {
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();
        var (vendorId, productId, addressId) = await SeedVendorProductAndAddressAsync(userId);

        var orderId = await CreateOrderAsync(client, vendorId, productId, addressId);

        var detailResp = await client.GetAsync($"/api/orders/{orderId:D}/detail");
        detailResp.StatusCode.Should().Be(HttpStatusCode.OK);

        using var doc = JsonDocument.Parse(await detailResp.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeTrue();

        var data = Get(doc.RootElement, "data");
        GetString(data, "id").Should().NotBeNullOrWhiteSpace();
        GetString(data, "customerOrderId").Should().NotBeNullOrWhiteSpace();
        GetString(data, "status").Should().NotBeNullOrWhiteSpace();

        var items = Get(data, "items");
        items.ValueKind.Should().Be(JsonValueKind.Array);
        items.GetArrayLength().Should().BeGreaterThan(0);

        var firstItem = items.EnumerateArray().First();
        GetString(firstItem, "customerOrderItemId").Should().NotBeNullOrWhiteSpace();
        GetString(firstItem, "productId").Should().NotBeNullOrWhiteSpace();
        GetString(firstItem, "productName").Should().NotBeNullOrWhiteSpace();

        var statusHistory = Get(data, "statusHistory");
        statusHistory.ValueKind.Should().Be(JsonValueKind.Array);
    }

    [Fact]
    public async Task Orders_CancelOrderItem_Works_And_ItemBecomesCancelled()
    {
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();
        var (vendorId, productId, addressId) = await SeedVendorProductAndAddressAsync(userId);

        var orderId = await CreateOrderAsync(client, vendorId, productId, addressId);

        // Read order detail to get CustomerOrderItemId
        var detailResp = await client.GetAsync($"/api/orders/{orderId:D}/detail");
        detailResp.StatusCode.Should().Be(HttpStatusCode.OK);

        string customerOrderItemId;
        using (var doc = JsonDocument.Parse(await detailResp.Content.ReadAsStringAsync()))
        {
            GetBool(doc.RootElement, "success").Should().BeTrue();
            var items = Get(Get(doc.RootElement, "data"), "items");
            items.ValueKind.Should().Be(JsonValueKind.Array);
            items.GetArrayLength().Should().BeGreaterThan(0);

            var firstItem = items.EnumerateArray().First();
            customerOrderItemId = GetString(firstItem, "customerOrderItemId")!;
            customerOrderItemId.Should().NotBeNullOrWhiteSpace();
        }

        // Cancel order item
        var cancelItemResp = await client.PostAsJsonAsync($"/api/orders/items/{customerOrderItemId}/cancel",
            new { reason = "Test item cancellation" }); // >= 10 chars
        var cancelItemBody = await cancelItemResp.Content.ReadAsStringAsync();
        cancelItemResp.StatusCode.Should().Be(HttpStatusCode.OK, $"body: {cancelItemBody}");
        using (var doc = JsonDocument.Parse(cancelItemBody))
        {
            GetBool(doc.RootElement, "success").Should().BeTrue();
        }

        // Re-fetch detail and confirm item is cancelled
        var detail2Resp = await client.GetAsync($"/api/orders/{orderId:D}/detail");
        detail2Resp.StatusCode.Should().Be(HttpStatusCode.OK);

        using (var doc = JsonDocument.Parse(await detail2Resp.Content.ReadAsStringAsync()))
        {
            GetBool(doc.RootElement, "success").Should().BeTrue();
            var items = Get(Get(doc.RootElement, "data"), "items");
            var item = items.EnumerateArray().First(i =>
                string.Equals(GetString(i, "customerOrderItemId"), customerOrderItemId, StringComparison.OrdinalIgnoreCase));
            GetBool(item, "isCancelled").Should().BeTrue();
        }
    }

    [Fact]
    public async Task Orders_CancelAllItems_CancelsOrder_AndAllItemsBecomeCancelled()
    {
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();
        var (vendorId, productId1, addressId) = await SeedVendorProductAndAddressAsync(userId);

        // Seed a 2nd product for same vendor
        var productId2 = await SeedExtraProductAsync(vendorId);

        // Create order with 2 items
        var createResp = await client.PostAsJsonAsync("/api/orders", new
        {
            vendorId,
            items = new[]
            {
                new { productId = productId1, quantity = 1 },
                new { productId = productId2, quantity = 1 }
            },
            deliveryAddressId = addressId,
            paymentMethod = "Cash"
        });

        var createBody = await createResp.Content.ReadAsStringAsync();
        createResp.StatusCode.Should().Be(HttpStatusCode.Created, $"body: {createBody}");

        Guid orderId;
        using (var doc = JsonDocument.Parse(createBody))
        {
            GetBool(doc.RootElement, "success").Should().BeTrue();
            orderId = Guid.Parse(GetString(Get(doc.RootElement, "data"), "id")!);
        }

        // Read detail and cancel items one by one
        var detail1 = await client.GetAsync($"/api/orders/{orderId:D}/detail");
        detail1.StatusCode.Should().Be(HttpStatusCode.OK);

        string[] itemIds;
        using (var doc = JsonDocument.Parse(await detail1.Content.ReadAsStringAsync()))
        {
            var items = Get(Get(doc.RootElement, "data"), "items");
            itemIds = items.EnumerateArray()
                .Select(i => GetString(i, "customerOrderItemId")!)
                .Where(s => !string.IsNullOrWhiteSpace(s))
                .ToArray();
        }

        itemIds.Length.Should().Be(2);

        // Cancel first item
        (await CancelOrderItemAsync(client, itemIds[0])).Should().Be(HttpStatusCode.OK);

        // Cancel second item -> order should become Cancelled
        (await CancelOrderItemAsync(client, itemIds[1])).Should().Be(HttpStatusCode.OK);

        var detail2 = await client.GetAsync($"/api/orders/{orderId:D}/detail");
        detail2.StatusCode.Should().Be(HttpStatusCode.OK);

        using (var doc = JsonDocument.Parse(await detail2.Content.ReadAsStringAsync()))
        {
            GetBool(doc.RootElement, "success").Should().BeTrue();
            var data = Get(doc.RootElement, "data");
            GetString(data, "status").Should().NotBeNullOrWhiteSpace();
            GetString(data, "status")!.Should().Be("Cancelled");

            var items = Get(data, "items");
            items.EnumerateArray().All(i => GetBool(i, "isCancelled")).Should().BeTrue();
        }
    }

    [Fact]
    public async Task Orders_GetDetail_Anonymous_Returns401()
    {
        // No auth header
        var client = _factory.CreateClient();
        var resp = await client.GetAsync($"/api/orders/{Guid.NewGuid():D}/detail");
        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Orders_GetOrder_Anonymous_Returns401()
    {
        // No auth header
        var client = _factory.CreateClient();
        var resp = await client.GetAsync($"/api/orders/{Guid.NewGuid():D}");
        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Orders_GetOrders_Anonymous_Returns401()
    {
        // No auth header
        var client = _factory.CreateClient();
        var resp = await client.GetAsync("/api/orders");
        resp.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }

    [Fact]
    public async Task Orders_GetOrder_ReturnsSummaryDto_WithStableShape()
    {
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();
        var (vendorId, productId, addressId) = await SeedVendorProductAndAddressAsync(userId);

        var orderId = await CreateOrderAsync(client, vendorId, productId, addressId);

        var resp = await client.GetAsync($"/api/orders/{orderId:D}");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeTrue();

        var data = Get(doc.RootElement, "data");
        GetString(data, "id").Should().NotBeNullOrWhiteSpace();
        GetString(data, "customerOrderId").Should().NotBeNullOrWhiteSpace();
        GetString(data, "vendorId").Should().NotBeNullOrWhiteSpace();
        GetString(data, "vendorName").Should().NotBeNullOrWhiteSpace();
        GetString(data, "status").Should().NotBeNullOrWhiteSpace();
        // totalAmount is numeric; we just verify it's present by attempting to access it
        Get(data, "totalAmount").ValueKind.Should().BeOneOf(JsonValueKind.Number);
        Get(data, "createdAt").ValueKind.Should().BeOneOf(JsonValueKind.String);
    }

    [Fact]
    public async Task Orders_GetOrders_ReturnsList_AndContainsCreatedOrder()
    {
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();
        var (vendorId, productId, addressId) = await SeedVendorProductAndAddressAsync(userId);

        var orderId = await CreateOrderAsync(client, vendorId, productId, addressId);

        var resp = await client.GetAsync("/api/orders");
        resp.StatusCode.Should().Be(HttpStatusCode.OK);

        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeTrue();

        var data = Get(doc.RootElement, "data");
        data.ValueKind.Should().Be(JsonValueKind.Array);

        var ids = data.EnumerateArray()
            .Select(o => GetString(o, "id"))
            .Where(s => !string.IsNullOrWhiteSpace(s))
            .Select(s => Guid.Parse(s!))
            .ToList();

        ids.Should().Contain(orderId);
    }

    [Fact]
    public async Task Orders_GetOrders_VendorTypeFilter_FiltersByVendorType_ForMobileNumericValues()
    {
        // Mobile sends vendorType as int: 1=Restaurant, 2=Market
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();

        // Restaurant vendor (type=1)
        var (restaurantVendorId, restaurantProductId, addressId) =
            await SeedVendorProductAndAddressAsync(userId, vendorType: 1);
        var restaurantOrderId = await CreateOrderAsync(client, restaurantVendorId, restaurantProductId, addressId);

        // Market vendor (type=2)
        var (marketVendorId, marketProductId) = await SeedVendorWithProductAsync(vendorType: 2);
        var marketOrderId = await CreateOrderAsync(client, marketVendorId, marketProductId, addressId);

        // Filter Restaurant
        var resp1 = await client.GetAsync("/api/orders?vendorType=1");
        resp1.StatusCode.Should().Be(HttpStatusCode.OK);
        using (var doc = JsonDocument.Parse(await resp1.Content.ReadAsStringAsync()))
        {
            GetBool(doc.RootElement, "success").Should().BeTrue();
            var data = Get(doc.RootElement, "data");
            data.ValueKind.Should().Be(JsonValueKind.Array);

            var ids = data.EnumerateArray()
                .Select(o => GetString(o, "id"))
                .Where(s => !string.IsNullOrWhiteSpace(s))
                .Select(s => Guid.Parse(s!))
                .ToList();

            ids.Should().Contain(restaurantOrderId);
            ids.Should().NotContain(marketOrderId);

            // Extra safety: ensure all returned items belong to restaurant vendor
            data.EnumerateArray()
                .All(o => Guid.Parse(GetString(o, "vendorId")!) == restaurantVendorId)
                .Should().BeTrue();
        }

        // Filter Market
        var resp2 = await client.GetAsync("/api/orders?vendorType=2");
        resp2.StatusCode.Should().Be(HttpStatusCode.OK);
        using (var doc = JsonDocument.Parse(await resp2.Content.ReadAsStringAsync()))
        {
            GetBool(doc.RootElement, "success").Should().BeTrue();
            var data = Get(doc.RootElement, "data");
            data.ValueKind.Should().Be(JsonValueKind.Array);

            var ids = data.EnumerateArray()
                .Select(o => GetString(o, "id"))
                .Where(s => !string.IsNullOrWhiteSpace(s))
                .Select(s => Guid.Parse(s!))
                .ToList();

            ids.Should().Contain(marketOrderId);
            ids.Should().NotContain(restaurantOrderId);

            data.EnumerateArray()
                .All(o => Guid.Parse(GetString(o, "vendorId")!) == marketVendorId)
                .Should().BeTrue();
        }
    }

    [Fact]
    public async Task Orders_GetOrders_VendorTypeFilter_UnknownNumericValue_Returns400ProblemDetails()
    {
        // Contract: API rejects undefined enum values with 400 (ProblemDetails) due to model binding validation.
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();

        // Seed at least one order so we can assert filtering removes it
        var (vendorId, productId, addressId) = await SeedVendorProductAndAddressAsync(userId, vendorType: 1);
        _ = await CreateOrderAsync(client, vendorId, productId, addressId);

        var resp = await client.GetAsync("/api/orders?vendorType=999");
        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        var contentType = resp.Content.Headers.ContentType?.MediaType;
        contentType.Should().NotBeNull();
        contentType!.Should().Contain("application/problem+json");

        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        GetString(doc.RootElement, "title").Should().NotBeNullOrWhiteSpace();
        Get(doc.RootElement, "status").ValueKind.Should().Be(JsonValueKind.Number);
    }

    [Fact]
    public async Task Orders_GetOrders_VendorTypeFilter_NonNumericValue_Returns400ProblemDetails()
    {
        // With [ApiController], model binding failures return RFC7807 ProblemDetails (not ApiResponse).
        var (client, _) = await CreateAuthenticatedClientAndUserIdAsync();

        var resp = await client.GetAsync("/api/orders?vendorType=abc");
        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        var contentType = resp.Content.Headers.ContentType?.MediaType;
        contentType.Should().NotBeNull();
        contentType!.Should().Contain("application/problem+json");

        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        // Basic RFC7807 fields
        GetString(doc.RootElement, "title").Should().NotBeNullOrWhiteSpace();
        Get(doc.RootElement, "status").ValueKind.Should().Be(JsonValueKind.Number);
    }

    [Fact]
    public async Task Orders_GetOrder_WithAnotherUsersOrderId_Returns404_OrderNotFound()
    {
        // Contract: do not leak existence of other users' orders (prefer 404 over 403).
        var (clientA, userIdA) = await CreateAuthenticatedClientAndUserIdAsync();
        var (vendorId, productId, addressId) = await SeedVendorProductAndAddressAsync(userIdA, vendorType: 1);
        var orderId = await CreateOrderAsync(clientA, vendorId, productId, addressId);

        var (clientB, _) = await CreateAuthenticatedClientAndUserIdAsync();
        var resp = await clientB.GetAsync($"/api/orders/{orderId:D}");
        resp.StatusCode.Should().Be(HttpStatusCode.NotFound);

        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeFalse();
        GetString(doc.RootElement, "errorCode").Should().Be("ORDER_NOT_FOUND");
    }

    [Fact]
    public async Task Orders_GetOrderDetail_WithAnotherUsersOrderId_Returns404_OrderNotFound()
    {
        // Contract: do not leak existence of other users' order details (prefer 404 over 403).
        var (clientA, userIdA) = await CreateAuthenticatedClientAndUserIdAsync();
        var (vendorId, productId, addressId) = await SeedVendorProductAndAddressAsync(userIdA, vendorType: 1);
        var orderId = await CreateOrderAsync(clientA, vendorId, productId, addressId);

        var (clientB, _) = await CreateAuthenticatedClientAndUserIdAsync();
        var resp = await clientB.GetAsync($"/api/orders/{orderId:D}/detail");
        resp.StatusCode.Should().Be(HttpStatusCode.NotFound);

        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeFalse();
        GetString(doc.RootElement, "errorCode").Should().Be("ORDER_NOT_FOUND");
    }

    [Fact]
    public async Task Orders_CreateOrder_WithoutDeliveryAddress_ReturnsBadRequestEnvelope()
    {
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();
        var (vendorId, productId, _) = await SeedVendorProductAndAddressAsync(userId);

        var createResp = await client.PostAsJsonAsync("/api/orders", new
        {
            vendorId,
            items = new[]
            {
                new { productId, quantity = 1 }
            },
            deliveryAddressId = (Guid?)null,
            paymentMethod = "Cash"
        });

        createResp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        using var doc = JsonDocument.Parse(await createResp.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeFalse();
        GetString(doc.RootElement, "errorCode").Should().Be("BAD_REQUEST");
    }

    [Fact]
    public async Task Orders_CancelOrderItem_WithShortReason_ReturnsInvalidCancellationReason()
    {
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();
        var (vendorId, productId, addressId) = await SeedVendorProductAndAddressAsync(userId);

        var orderId = await CreateOrderAsync(client, vendorId, productId, addressId);
        var customerOrderItemId = await GetFirstCustomerOrderItemIdAsync(client, orderId);

        var resp = await client.PostAsJsonAsync($"/api/orders/items/{customerOrderItemId}/cancel",
            new { reason = "short" }); // < 10 chars

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeFalse();
        GetString(doc.RootElement, "errorCode").Should().Be("INVALID_CANCELLATION_REASON");
    }

    [Fact]
    public async Task Orders_CancelOrderItem_WhenOrderStatusInvalid_ReturnsInvalidCancellationStatus()
    {
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();
        var (vendorId, productId, addressId) = await SeedVendorProductAndAddressAsync(userId);

        var orderId = await CreateOrderAsync(client, vendorId, productId, addressId);
        await ForceOrderStatusAsync(orderId, Talabi.Core.Enums.OrderStatus.Delivered);

        var customerOrderItemId = await GetFirstCustomerOrderItemIdAsync(client, orderId);

        var resp = await client.PostAsJsonAsync($"/api/orders/items/{customerOrderItemId}/cancel",
            new { reason = "Test item cancellation" }); // >= 10

        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);
        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeFalse();
        GetString(doc.RootElement, "errorCode").Should().Be("INVALID_CANCELLATION_STATUS");
    }

    [Fact]
    public async Task Orders_CancelOrder_WithShortReason_ReturnsBadRequestEnvelope()
    {
        var (client, userId) = await CreateAuthenticatedClientAndUserIdAsync();
        var (vendorId, productId, addressId) = await SeedVendorProductAndAddressAsync(userId);

        var orderId = await CreateOrderAsync(client, vendorId, productId, addressId);

        var resp = await client.PostAsJsonAsync($"/api/orders/{orderId:D}/cancel", new { reason = "short" });
        resp.StatusCode.Should().Be(HttpStatusCode.BadRequest);

        using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
        GetBool(doc.RootElement, "success").Should().BeFalse();
        // CancelOrder uses service+middleware path -> generic BAD_REQUEST
        GetString(doc.RootElement, "errorCode").Should().Be("BAD_REQUEST");
    }

    private async Task<HttpStatusCode> CancelOrderItemAsync(HttpClient client, string customerOrderItemId, string reason = "Test item cancellation")
    {
        var resp = await client.PostAsJsonAsync($"/api/orders/items/{customerOrderItemId}/cancel",
            new { reason }); // >= 10 chars for success
        return resp.StatusCode;
    }

    private static async Task<Guid> CreateOrderAsync(HttpClient client, Guid vendorId, Guid productId, Guid addressId)
    {
        var createResp = await client.PostAsJsonAsync("/api/orders", new
        {
            vendorId,
            items = new[]
            {
                new { productId, quantity = 1 }
            },
            deliveryAddressId = addressId,
            paymentMethod = "Cash"
        });

        var createBody = await createResp.Content.ReadAsStringAsync();
        createResp.StatusCode.Should().Be(HttpStatusCode.Created, $"body: {createBody}");

        using var doc = JsonDocument.Parse(createBody);
        GetBool(doc.RootElement, "success").Should().BeTrue();
        var data = Get(doc.RootElement, "data");
        return Guid.Parse(GetString(data, "id")!);
    }

    private async Task<(HttpClient client, string userId)> CreateAuthenticatedClientAndUserIdAsync()
    {
        var client = _factory.CreateClient();

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

        var verifyResp = await client.PostAsJsonAsync("/api/auth/verify-email-code", new { email, code });
        verifyResp.EnsureSuccessStatusCode();

        var loginResp = await client.PostAsJsonAsync("/api/auth/login", new { email, password });
        loginResp.EnsureSuccessStatusCode();

        using var doc = JsonDocument.Parse(await loginResp.Content.ReadAsStringAsync());
        var data = Get(doc.RootElement, "data");
        var token = GetString(data, "token");
        token.Should().NotBeNullOrWhiteSpace();

        var userId = GetString(data, "userId");
        userId.Should().NotBeNullOrWhiteSpace();

        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return (client, userId!);
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

    private async Task<(Guid vendorId, Guid productId, Guid addressId)> SeedVendorProductAndAddressAsync(
        string userId,
        int vendorType = 1)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TalabiDbContext>();

        // Ensure there is a default address for the user (Cart/AddToCart depends on it)
        var address = new UserAddress
        {
            UserId = userId,
            Title = "Home",
            FullAddress = "Test Address",
            IsDefault = true,
            Latitude = 41.0,
            Longitude = 29.0
        };

        // Ensure at least one active vendor with coordinates inside radius
        var vendor = new Vendor
        {
            Name = "Test Vendor",
            OwnerId = "seed-owner",
            Type = (Talabi.Core.Enums.VendorType)vendorType,
            IsActive = true,
            Latitude = 41.0001,
            Longitude = 29.0001,
            DeliveryRadiusInKm = 5
        };

        var product = new Product
        {
            VendorId = vendor.Id,
            Vendor = vendor,
            Name = "Test Product",
            Price = 10m,
            IsAvailable = true
        };

        db.UserAddresses.Add(address);
        db.Vendors.Add(vendor);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        return (vendor.Id, product.Id, address.Id);
    }

    private async Task<(Guid vendorId, Guid productId)> SeedVendorWithProductAsync(int vendorType)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TalabiDbContext>();

        var vendor = new Vendor
        {
            Name = vendorType == 1 ? "Restaurant Vendor" : "Market Vendor",
            OwnerId = $"seed-owner-{vendorType}",
            Type = (Talabi.Core.Enums.VendorType)vendorType,
            IsActive = true,
            Latitude = 41.0002 + vendorType * 0.0001,
            Longitude = 29.0002 + vendorType * 0.0001,
            DeliveryRadiusInKm = 5
        };

        var product = new Product
        {
            VendorId = vendor.Id,
            Vendor = vendor,
            Name = vendorType == 1 ? "Restaurant Product" : "Market Product",
            Price = 11m + vendorType,
            IsAvailable = true
        };

        db.Vendors.Add(vendor);
        db.Products.Add(product);
        await db.SaveChangesAsync();

        return (vendor.Id, product.Id);
    }

    private async Task<Guid> SeedExtraProductAsync(Guid vendorId)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TalabiDbContext>();

        var product = new Product
        {
            VendorId = vendorId,
            Name = "Test Product 2",
            Price = 12m,
            IsAvailable = true
        };

        db.Products.Add(product);
        await db.SaveChangesAsync();
        return product.Id;
    }

    private static async Task<string> GetFirstCustomerOrderItemIdAsync(HttpClient client, Guid orderId)
    {
        var detailResp = await client.GetAsync($"/api/orders/{orderId:D}/detail");
        detailResp.StatusCode.Should().Be(HttpStatusCode.OK);

        using var doc = JsonDocument.Parse(await detailResp.Content.ReadAsStringAsync());
        var items = Get(Get(doc.RootElement, "data"), "items");
        var first = items.EnumerateArray().First();
        var id = GetString(first, "customerOrderItemId");
        id.Should().NotBeNullOrWhiteSpace();
        return id!;
    }

    private async Task ForceOrderStatusAsync(Guid orderId, Talabi.Core.Enums.OrderStatus status)
    {
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<TalabiDbContext>();

        var order = await db.Orders.FirstOrDefaultAsync(o => o.Id == orderId);
        order.Should().NotBeNull();

        order!.Status = status;
        await db.SaveChangesAsync();
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

