using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class UserSelfServiceController : Controller
{
    private readonly IUserSelfService _userSelfService;
    private readonly ILocalizationService _localizationService;
    private readonly ILogger<UserSelfServiceController> _logger;

    public UserSelfServiceController(
        IUserSelfService userSelfService,
        ILocalizationService localizationService,
        ILogger<UserSelfServiceController> logger)
    {
        _userSelfService = userSelfService;
        _localizationService = localizationService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> Index(int ordersPage = 1, int favoritesPage = 1)
    {
        var profile = await _userSelfService.GetProfileAsync();
        var preferences = await _userSelfService.GetNotificationPreferencesAsync();
        var addresses = await _userSelfService.GetAddressesAsync();

        var orders = await _userSelfService.GetOrdersAsync(new PaginationQueryRequest
        {
            Page = Math.Max(1, ordersPage),
            PageSize = 10
        });

        var favorites = await _userSelfService.GetFavoritesAsync(new PaginationQueryRequest
        {
            Page = Math.Max(1, favoritesPage),
            PageSize = 12
        });

        var locationHistory = await _userSelfService.GetLocationHistoryAsync(new PaginationQueryRequest
        {
            Page = 1,
            PageSize = 10
        });

        var viewModel = new UserSelfServiceViewModel
        {
            Profile = profile,
            NotificationPreferences = preferences,
            Addresses = addresses,
            Orders = orders,
            Favorites = favorites,
            LocationHistory = locationHistory,
            ProfileForm = profile != null
                ? new UpdateProfileFormModel
                {
                    FirstName = profile.FirstName,
                    LastName = profile.LastName,
                    PhoneNumber = profile.PhoneNumber
                }
                : new UpdateProfileFormModel(),
            NotificationForm = MapPreferencesToForm(preferences),
            AddressForm = new CreateAddressFormModel()
        };

        ViewData["Title"] = _localizationService.GetString("UserSelfService");
        return View(viewModel);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateProfile(UpdateProfileFormModel model)
    {
        if (!ModelState.IsValid)
        {
            TempData["Error"] = _localizationService.GetString("FormValidationError");
            return RedirectToAction(nameof(Index));
        }

        var request = new UpdateUserProfileRequest
        {
            FirstName = model.FirstName,
            LastName = model.LastName,
            PhoneNumber = model.PhoneNumber
        };

        var updated = await _userSelfService.UpdateProfileAsync(request);
        TempData[updated != null ? "Success" : "Error"] = updated != null
            ? _localizationService.GetString("ProfileUpdated")
            : _localizationService.GetString("ProfileUpdateFailed");

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateNotificationPreferences(UpdateNotificationPreferencesFormModel model)
    {
        if (!ModelState.IsValid)
        {
            TempData["Error"] = _localizationService.GetString("FormValidationError");
            return RedirectToAction(nameof(Index));
        }

        var request = new UpdateUserNotificationPreferencesRequestModel
        {
            EmailEnabled = model.EmailEnabled,
            EmailOrderUpdates = model.EmailOrderUpdates,
            EmailPromotions = model.EmailPromotions,
            EmailNewsletter = model.EmailNewsletter,
            EmailSecurityAlerts = model.EmailSecurityAlerts,
            SmsEnabled = model.SmsEnabled,
            SmsOrderUpdates = model.SmsOrderUpdates,
            SmsPromotions = model.SmsPromotions,
            SmsSecurityAlerts = model.SmsSecurityAlerts,
            PushEnabled = model.PushEnabled,
            PushOrderUpdates = model.PushOrderUpdates,
            PushPromotions = model.PushPromotions,
            PushMerchantUpdates = model.PushMerchantUpdates,
            PushSecurityAlerts = model.PushSecurityAlerts,
            SoundEnabled = model.SoundEnabled,
            DesktopNotifications = model.DesktopNotifications,
            NotificationSound = model.NotificationSound,
            NewOrderNotifications = model.NewOrderNotifications,
            StatusChangeNotifications = model.StatusChangeNotifications,
            CancellationNotifications = model.CancellationNotifications,
            RespectQuietHours = model.RespectQuietHours,
            QuietStartTime = model.QuietStartTime,
            QuietEndTime = model.QuietEndTime,
            Language = model.Language
        };

        var success = await _userSelfService.UpdateNotificationPreferencesAsync(request);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("NotificationPreferencesUpdated")
            : _localizationService.GetString("NotificationPreferencesUpdateFailed");

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CreateAddress(CreateAddressFormModel model)
    {
        if (!ModelState.IsValid)
        {
            TempData["Error"] = _localizationService.GetString("FormValidationError");
            return RedirectToAction(nameof(Index));
        }

        var request = new CreateAddressRequestModel
        {
            Title = model.Title,
            FullAddress = model.FullAddress,
            City = model.City,
            District = model.District,
            Latitude = model.Latitude,
            Longitude = model.Longitude
        };

        var created = await _userSelfService.CreateAddressAsync(request);
        TempData[created != null ? "Success" : "Error"] = created != null
            ? _localizationService.GetString("AddressCreated")
            : _localizationService.GetString("AddressCreateFailed");

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateAddress(CreateAddressFormModel model)
    {
        if (model.Id == null)
        {
            TempData["Error"] = _localizationService.GetString("AddressNotFound");
            return RedirectToAction(nameof(Index));
        }

        if (!ModelState.IsValid)
        {
            TempData["Error"] = _localizationService.GetString("FormValidationError");
            return RedirectToAction(nameof(Index));
        }

        var request = new UpdateAddressRequestModel
        {
            Title = model.Title,
            FullAddress = model.FullAddress,
            City = model.City,
            District = model.District,
            Latitude = model.Latitude,
            Longitude = model.Longitude
        };

        var updated = await _userSelfService.UpdateAddressAsync(model.Id.Value, request);
        TempData[updated != null ? "Success" : "Error"] = updated != null
            ? _localizationService.GetString("AddressUpdated")
            : _localizationService.GetString("AddressUpdateFailed");

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteAddress(Guid addressId)
    {
        var success = await _userSelfService.DeleteAddressAsync(addressId);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("AddressDeleted")
            : _localizationService.GetString("AddressDeleteFailed");
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SetDefaultAddress(Guid addressId)
    {
        var success = await _userSelfService.SetDefaultAddressAsync(addressId);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("AddressSetDefault")
            : _localizationService.GetString("AddressSetDefaultFailed");
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> AddFavorite(Guid productId)
    {
        var success = await _userSelfService.AddFavoriteAsync(productId);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("FavoriteAdded")
            : _localizationService.GetString("FavoriteAddFailed");
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> RemoveFavorite(Guid productId)
    {
        var success = await _userSelfService.RemoveFavoriteAsync(productId);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("FavoriteRemoved")
            : _localizationService.GetString("FavoriteRemoveFailed");
        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> OrderDetails(Guid id)
    {
        var details = await _userSelfService.GetOrderDetailsAsync(id);
        if (details == null)
        {
            TempData["Error"] = _localizationService.GetString("OrderNotFound");
            return RedirectToAction(nameof(Index));
        }

        var viewModel = new UserOrderDetailViewModel
        {
            Order = details
        };

        ViewData["Title"] = _localizationService.GetString("OrderDetails");
        return View(viewModel);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> CancelOrder(Guid orderId, string reason)
    {
        if (string.IsNullOrWhiteSpace(reason))
        {
            TempData["Error"] = _localizationService.GetString("CancelOrderReasonRequired");
            return RedirectToAction(nameof(OrderDetails), new { id = orderId });
        }

        var success = await _userSelfService.CancelOrderAsync(orderId, new CancelOrderRequestModel
        {
            OrderId = orderId,
            Reason = reason
        });

        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("OrderCancelled")
            : _localizationService.GetString("OrderCancelFailed");

        return RedirectToAction(nameof(OrderDetails), new { id = orderId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Reorder(Guid orderId)
    {
        var order = await _userSelfService.ReorderAsync(orderId);
        TempData[order != null ? "Success" : "Error"] = order != null
            ? _localizationService.GetString("OrderRecreated")
            : _localizationService.GetString("OrderRecreateFailed");

        return order != null
            ? RedirectToAction(nameof(OrderDetails), new { id = order.Id })
            : RedirectToAction(nameof(OrderDetails), new { id = orderId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SaveLocation(double latitude, double longitude, string? address)
    {
        var success = await _userSelfService.SaveUserLocationAsync(new SaveUserLocationRequestModel
        {
            Latitude = latitude,
            Longitude = longitude,
            Address = address
        });

        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("LocationSaved")
            : _localizationService.GetString("LocationSaveFailed");

        return RedirectToAction(nameof(Index));
    }

    private static UpdateNotificationPreferencesFormModel MapPreferencesToForm(UserNotificationPreferencesResponse? preferences)
    {
        if (preferences == null)
        {
            return new UpdateNotificationPreferencesFormModel();
        }

        return new UpdateNotificationPreferencesFormModel
        {
            EmailEnabled = preferences.EmailEnabled,
            EmailOrderUpdates = preferences.EmailOrderUpdates,
            EmailPromotions = preferences.EmailPromotions,
            EmailNewsletter = preferences.EmailNewsletter,
            EmailSecurityAlerts = preferences.EmailSecurityAlerts,
            SmsEnabled = preferences.SmsEnabled,
            SmsOrderUpdates = preferences.SmsOrderUpdates,
            SmsPromotions = preferences.SmsPromotions,
            SmsSecurityAlerts = preferences.SmsSecurityAlerts,
            PushEnabled = preferences.PushEnabled,
            PushOrderUpdates = preferences.PushOrderUpdates,
            PushPromotions = preferences.PushPromotions,
            PushMerchantUpdates = preferences.PushMerchantUpdates,
            PushSecurityAlerts = preferences.PushSecurityAlerts,
            SoundEnabled = preferences.SoundEnabled,
            DesktopNotifications = preferences.DesktopNotifications,
            NotificationSound = preferences.NotificationSound,
            NewOrderNotifications = preferences.NewOrderNotifications,
            StatusChangeNotifications = preferences.StatusChangeNotifications,
            CancellationNotifications = preferences.CancellationNotifications,
            RespectQuietHours = preferences.RespectQuietHours,
            QuietStartTime = preferences.QuietStartTime,
            QuietEndTime = preferences.QuietEndTime,
            Language = preferences.Language
        };
    }
}


