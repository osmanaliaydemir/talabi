using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IUserSelfService
{
    Task<UserProfileResponse?> GetProfileAsync(CancellationToken ct = default);
    Task<UserProfileResponse?> UpdateProfileAsync(UpdateUserProfileRequest request, CancellationToken ct = default);

    Task<UserNotificationPreferencesResponse?> GetNotificationPreferencesAsync(CancellationToken ct = default);
    Task<bool> UpdateNotificationPreferencesAsync(UpdateUserNotificationPreferencesRequestModel request, CancellationToken ct = default);

    Task<List<AddressResponse>> GetAddressesAsync(CancellationToken ct = default);
    Task<AddressResponse?> CreateAddressAsync(CreateAddressRequestModel request, CancellationToken ct = default);
    Task<AddressResponse?> UpdateAddressAsync(Guid addressId, UpdateAddressRequestModel request, CancellationToken ct = default);
    Task<bool> DeleteAddressAsync(Guid addressId, CancellationToken ct = default);
    Task<bool> SetDefaultAddressAsync(Guid addressId, CancellationToken ct = default);

    Task<PagedResult<FavoriteProductResponse>?> GetFavoritesAsync(PaginationQueryRequest request, CancellationToken ct = default);
    Task<bool> AddFavoriteAsync(Guid productId, CancellationToken ct = default);
    Task<bool> RemoveFavoriteAsync(Guid productId, CancellationToken ct = default);

    Task<PagedResult<OrderResponseModel>?> GetOrdersAsync(PaginationQueryRequest request, CancellationToken ct = default);
    Task<OrderDetailsResponseModel?> GetOrderDetailsAsync(Guid orderId, CancellationToken ct = default);
    Task<bool> CancelOrderAsync(Guid orderId, CancelOrderRequestModel request, CancellationToken ct = default);
    Task<OrderResponseModel?> ReorderAsync(Guid orderId, CancellationToken ct = default);

    Task<List<UserLocationResponseModel>> GetLocationHistoryAsync(PaginationQueryRequest request, CancellationToken ct = default);
    Task<bool> SaveUserLocationAsync(SaveUserLocationRequestModel request, CancellationToken ct = default);
}


