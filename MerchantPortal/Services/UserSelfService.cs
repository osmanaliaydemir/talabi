using Getir.MerchantPortal.Models;
using Microsoft.AspNetCore.WebUtilities;

namespace Getir.MerchantPortal.Services;

public class UserSelfService : IUserSelfService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<UserSelfService> _logger;

    public UserSelfService(IApiClient apiClient, ILogger<UserSelfService> logger)
    {
        _apiClient = apiClient;
        _logger = logger;
    }

    public async Task<UserProfileResponse?> GetProfileAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<UserProfileResponse>>("api/v1/User/profile", ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch user profile");
            return null;
        }
    }

    public async Task<UserProfileResponse?> UpdateProfileAsync(UpdateUserProfileRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PutAsync<ApiResponse<UserProfileResponse>>("api/v1/User/profile", request, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update user profile");
            return null;
        }
    }

    public async Task<UserNotificationPreferencesResponse?> GetNotificationPreferencesAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<UserNotificationPreferencesResponse>>("api/v1/User/notification-preferences", ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch notification preferences");
            return null;
        }
    }

    public async Task<bool> UpdateNotificationPreferencesAsync(UpdateUserNotificationPreferencesRequestModel request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PutAsync<ApiResponse<UserNotificationPreferencesResponse>>("api/v1/User/notification-preferences", request, ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update notification preferences");
            return false;
        }
    }

    public async Task<List<AddressResponse>> GetAddressesAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<List<AddressResponse>>>("api/v1/User/addresses", ct);
            return response?.Data ?? new List<AddressResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch addresses");
            return new List<AddressResponse>();
        }
    }

    public async Task<AddressResponse?> CreateAddressAsync(CreateAddressRequestModel request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<AddressResponse>>("api/v1/User/addresses", request, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create address");
            return null;
        }
    }

    public async Task<AddressResponse?> UpdateAddressAsync(Guid addressId, UpdateAddressRequestModel request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PutAsync<ApiResponse<AddressResponse>>($"api/v1/User/addresses/{addressId}", request, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update address {AddressId}", addressId);
            return null;
        }
    }

    public async Task<bool> DeleteAddressAsync(Guid addressId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.DeleteAsync<ApiResponse<object>>($"api/v1/User/addresses/{addressId}", ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to delete address {AddressId}", addressId);
            return false;
        }
    }

    public async Task<bool> SetDefaultAddressAsync(Guid addressId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PutAsync<ApiResponse<object>>($"api/v1/User/addresses/{addressId}/set-default", new { }, ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to set default address {AddressId}", addressId);
            return false;
        }
    }

    public async Task<PagedResult<FavoriteProductResponse>?> GetFavoritesAsync(PaginationQueryRequest request, CancellationToken ct = default)
    {
        try
        {
            var query = new Dictionary<string, string?>
            {
                ["page"] = request.Page.ToString(),
                ["pageSize"] = request.PageSize.ToString()
            };
            var url = QueryHelpers.AddQueryString("api/v1/User/favorites", query);
            var response = await _apiClient.GetAsync<ApiResponse<PagedResult<FavoriteProductResponse>>>(url, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch favorites");
            return null;
        }
    }

    public async Task<bool> AddFavoriteAsync(Guid productId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<object>>("api/v1/User/favorites", new AddToFavoritesRequestModel { ProductId = productId }, ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to add favorite {ProductId}", productId);
            return false;
        }
    }

    public async Task<bool> RemoveFavoriteAsync(Guid productId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.DeleteAsync<ApiResponse<object>>($"api/v1/User/favorites/{productId}", ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to remove favorite {ProductId}", productId);
            return false;
        }
    }

    public async Task<PagedResult<OrderResponseModel>?> GetOrdersAsync(PaginationQueryRequest request, CancellationToken ct = default)
    {
        try
        {
            var query = new Dictionary<string, string?>
            {
                ["page"] = request.Page.ToString(),
                ["pageSize"] = request.PageSize.ToString()
            };
            var url = QueryHelpers.AddQueryString("api/v1/User/orders", query);
            var response = await _apiClient.GetAsync<ApiResponse<PagedResult<OrderResponseModel>>>(url, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch orders");
            return null;
        }
    }

    public async Task<OrderDetailsResponseModel?> GetOrderDetailsAsync(Guid orderId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<OrderDetailsResponseModel>>($"api/v1/User/orders/{orderId}", ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch order details for {OrderId}", orderId);
            return null;
        }
    }

    public async Task<bool> CancelOrderAsync(Guid orderId, CancelOrderRequestModel request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<OrderResponseModel>>($"api/v1/User/orders/{orderId}/cancel", request, ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to cancel order {OrderId}", orderId);
            return false;
        }
    }

    public async Task<OrderResponseModel?> ReorderAsync(Guid orderId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<OrderResponseModel>>($"api/v1/User/orders/{orderId}/reorder", new { }, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to reorder {OrderId}", orderId);
            return null;
        }
    }

    public async Task<List<UserLocationResponseModel>> GetLocationHistoryAsync(PaginationQueryRequest request, CancellationToken ct = default)
    {
        try
        {
            var query = new Dictionary<string, string?>
            {
                ["page"] = request.Page.ToString(),
                ["pageSize"] = request.PageSize.ToString()
            };
            var url = QueryHelpers.AddQueryString("api/v1/geo/location/history", query);
            var response = await _apiClient.GetAsync<ApiResponse<PagedResult<UserLocationResponseModel>>>(url, ct);
            return response?.Data?.Items ?? new List<UserLocationResponseModel>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch location history");
            return new List<UserLocationResponseModel>();
        }
    }

    public async Task<bool> SaveUserLocationAsync(SaveUserLocationRequestModel request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<object>>("api/v1/geo/location", request, ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to save user location");
            return false;
        }
    }
}


