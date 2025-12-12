using System.ComponentModel.DataAnnotations;

namespace Getir.MerchantPortal.Models;

public class UserSelfServiceViewModel
{
    public UserProfileResponse? Profile { get; set; }
    public UserNotificationPreferencesResponse? NotificationPreferences { get; set; }
    public List<AddressResponse> Addresses { get; set; } = new();
    public PagedResult<FavoriteProductResponse>? Favorites { get; set; }
    public PagedResult<OrderResponseModel>? Orders { get; set; }
    public List<UserLocationResponseModel> LocationHistory { get; set; } = new();

    public UpdateProfileFormModel ProfileForm { get; set; } = new();
    public UpdateNotificationPreferencesFormModel NotificationForm { get; set; } = new();
    public CreateAddressFormModel AddressForm { get; set; } = new();
}

public class UpdateProfileFormModel
{
    [Required, Display(Name = "FirstName")]
    public string FirstName { get; set; } = string.Empty;

    [Required, Display(Name = "LastName")]
    public string LastName { get; set; } = string.Empty;

    [Phone, Display(Name = "PhoneNumber")]
    public string? PhoneNumber { get; set; }
}

public class UpdateNotificationPreferencesFormModel
{
    public bool EmailEnabled { get; set; }
    public bool EmailOrderUpdates { get; set; }
    public bool EmailPromotions { get; set; }
    public bool EmailNewsletter { get; set; }
    public bool EmailSecurityAlerts { get; set; }
    public bool SmsEnabled { get; set; }
    public bool SmsOrderUpdates { get; set; }
    public bool SmsPromotions { get; set; }
    public bool SmsSecurityAlerts { get; set; }
    public bool PushEnabled { get; set; }
    public bool PushOrderUpdates { get; set; }
    public bool PushPromotions { get; set; }
    public bool PushMerchantUpdates { get; set; }
    public bool PushSecurityAlerts { get; set; }
    public bool SoundEnabled { get; set; }
    public bool DesktopNotifications { get; set; }
    public bool NewOrderNotifications { get; set; }
    public bool StatusChangeNotifications { get; set; }
    public bool CancellationNotifications { get; set; }
    public bool RespectQuietHours { get; set; }
    public TimeSpan? QuietStartTime { get; set; }
    public TimeSpan? QuietEndTime { get; set; }
    public string NotificationSound { get; set; } = "default";
    public string Language { get; set; } = "tr-TR";
}

public class CreateAddressFormModel
{
    public Guid? Id { get; set; }

    [Required, Display(Name = "AddressTitle")]
    public string Title { get; set; } = string.Empty;

    [Required, Display(Name = "FullAddress")]
    public string FullAddress { get; set; } = string.Empty;

    [Required, Display(Name = "City")]
    public string City { get; set; } = string.Empty;

    [Required, Display(Name = "District")]
    public string District { get; set; } = string.Empty;

    [Display(Name = "Latitude")]
    public decimal Latitude { get; set; }

    [Display(Name = "Longitude")]
    public decimal Longitude { get; set; }
}

public class UserOrderDetailViewModel
{
    public OrderDetailsResponseModel? Order { get; set; }
}


