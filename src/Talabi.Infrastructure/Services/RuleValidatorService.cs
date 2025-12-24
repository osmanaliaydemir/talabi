using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Models;
using Microsoft.AspNetCore.Http;
using System.Globalization;

namespace Talabi.Infrastructure.Services;

public class RuleValidatorService : IRuleValidatorService
{
    private readonly ILocalizationService _localizationService;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private const string ResourceName = "ValidationResources";

    public RuleValidatorService(ILocalizationService localizationService, IHttpContextAccessor httpContextAccessor)
    {
        _localizationService = localizationService;
        _httpContextAccessor = httpContextAccessor;
    }

    private string GetLanguageFromRequest()
    {
        var httpContext = _httpContextAccessor.HttpContext;
        if (httpContext == null)
        {
            return "tr"; // Default
        }

        // Check query parameter first
        var languageQuery = httpContext.Request.Query["language"].FirstOrDefault();
        if (!string.IsNullOrWhiteSpace(languageQuery))
        {
            return NormalizeLanguageCode(languageQuery);
        }

        // Check Accept-Language header
        var acceptLanguage = httpContext.Request.Headers["Accept-Language"].FirstOrDefault();
        if (!string.IsNullOrWhiteSpace(acceptLanguage))
        {
            return NormalizeLanguageCode(acceptLanguage);
        }

        return "tr"; // Default fallback
    }

    private string NormalizeLanguageCode(string language)
    {
        if (string.IsNullOrEmpty(language)) return "tr";
        var normalized = language.Split('-')[0].ToLower();
        return normalized switch
        {
            "en" => "en",
            "ar" => "ar",
            _ => "tr"
        };
    }

    private CultureInfo GetCultureInfo(string languageCode)
    {
        try
        {
            return new CultureInfo(languageCode);
        }
        catch (CultureNotFoundException)
        {
            return new CultureInfo("tr");
        }
    }

    public bool ValidateCampaign(Campaign campaign, RuleValidationContext context, out string? failureReason)
    {
        failureReason = null;

        var culture = GetCultureInfo(GetLanguageFromRequest());

        if (!campaign.IsActive)
        {
            failureReason = _localizationService.GetLocalizedString(ResourceName, "CampaignNotActive", culture);
            return false;
        }

        if (campaign.IsFirstOrderOnly && !context.IsFirstOrder)
        {
            failureReason = _localizationService.GetLocalizedString(ResourceName, "CampaignFirstOrderOnly", culture);
            return false;
        }

        // Date Range
        if (context.RequestTime < campaign.StartDate || context.RequestTime > campaign.EndDate)
        {
            failureReason = _localizationService.GetLocalizedString(ResourceName, "CampaignExpiredOrNotStarted", culture);
            return false;
        }

        // Time of Day
        var timeOfDay = context.RequestTime.TimeOfDay;
        if (campaign.StartTime.HasValue && timeOfDay < campaign.StartTime.Value)
        {
            failureReason = _localizationService.GetLocalizedString(ResourceName, "CampaignNotValidAtThisTime", culture);
            return false;
        }
        if (campaign.EndTime.HasValue && timeOfDay > campaign.EndTime.Value)
        {
            failureReason = _localizationService.GetLocalizedString(ResourceName, "CampaignNotValidAtThisTime", culture);
            return false;
        }

        // Location - City
        if (campaign.CampaignCities.Any())
        {
            if (!context.CityId.HasValue || !campaign.CampaignCities.Any(cc => cc.CityId == context.CityId.Value))
            {
                failureReason = _localizationService.GetLocalizedString(ResourceName, "CampaignNotValidInCity", culture);
                return false;
            }
        }

        // Location - District
        if (campaign.CampaignDistricts.Any())
        {
            if (!context.DistrictId.HasValue || !campaign.CampaignDistricts.Any(cd => cd.DistrictId == context.DistrictId.Value))
            {
                failureReason = _localizationService.GetLocalizedString(ResourceName, "CampaignNotValidInDistrict", culture);
                return false;
            }
        }

        // Vendor Type
        if (campaign.VendorType.HasValue)
        {
            // If we have items, check if they match. Match if ANY item matches the vendor type? 
            // Or if logic dictates "For Restaurant Campaigns", usually app is in Restaurant Mode.
            // If context items are empty (browsing), we assume validity or check context intent.
            if (context.Items.Any() && !context.Items.All(i => i.VendorType == campaign.VendorType.Value))
            {
                // Strictly, if campaign is "Market", it shouldn't apply to "Restaurant" items.
                // But mixed carts might be complicated. Assuming single-vendor carts mostly.
                failureReason = "Campaign not valid for these items (Vendor Type mismatch).";
                return false;
            }
        }

        // Cart Amount (only relevant if items exist)
        if (context.Items.Any() && campaign.MinCartAmount.HasValue && context.CartTotal < campaign.MinCartAmount.Value)
        {
            failureReason = _localizationService.GetLocalizedString(ResourceName, "CampaignMinCartAmountRequired", culture, campaign.MinCartAmount);
            return false;
        }

        // Categories & Products inclusions
        // If CampaignProducts is set, at least one product must be in cart? Or ALL?
        // Usually: "Buy X get Y". Here generic campaign: "Valid if cart contains X".
        if (campaign.CampaignProducts.Any() && context.Items.Any())
        {
            var validProductIds = campaign.CampaignProducts.Select(cp => cp.ProductId).ToHashSet();
            if (!context.Items.Any(i => validProductIds.Contains(i.ProductId)))
            {
                failureReason = _localizationService.GetLocalizedString(ResourceName, "CampaignRequiresSpecificProducts", culture);
                return false;
            }
        }

        return true;
    }

    public bool ValidateCoupon(Coupon coupon, RuleValidationContext context, out string? failureReason)
    {
        failureReason = null;

        var culture = GetCultureInfo(GetLanguageFromRequest());

        if (!coupon.IsActive)
        {
            failureReason = _localizationService.GetLocalizedString(ResourceName, "CouponNotActive", culture);
            return false;
        }

        if (coupon.IsFirstOrderOnly && !context.IsFirstOrder)
        {
            failureReason = _localizationService.GetLocalizedString(ResourceName, "CouponFirstOrderOnly", culture);
            return false;
        }

        if (context.RequestTime > coupon.ExpirationDate)
        {
            failureReason = _localizationService.GetLocalizedString(ResourceName, "CouponExpired", culture);
            return false;
        }

        // Time of Day
        var timeOfDay = context.RequestTime.TimeOfDay;
        if (coupon.StartTime.HasValue && timeOfDay < coupon.StartTime.Value)
        {
            failureReason = _localizationService.GetLocalizedString(ResourceName, "CouponNotValidAtThisTime", culture);
            return false;
        }
        if (coupon.EndTime.HasValue && timeOfDay > coupon.EndTime.Value)
        {
            failureReason = _localizationService.GetLocalizedString(ResourceName, "CouponNotValidAtThisTime", culture);
            return false;
        }

        // Vendor Type
        if (coupon.VendorType.HasValue)
        {
            if (context.Items.Any() && !context.Items.All(i => i.VendorType == coupon.VendorType.Value))
            {
                failureReason = "Coupon not valid for these items (Vendor Type mismatch).";
                return false;
            }
        }

        // Vendor Id Specific
        if (coupon.VendorId.HasValue)
        {
            if (context.Items.Any() && !context.Items.Any(i => i.VendorId == coupon.VendorId.Value))
            {
                failureReason = _localizationService.GetLocalizedString(ResourceName, "CouponVendorMismatch", culture);
                return false;
            }
        }

        // Location - City
        if (coupon.CouponCities.Any())
        {
            if (!context.CityId.HasValue || !coupon.CouponCities.Any(cc => cc.CityId == context.CityId.Value))
            {
                failureReason = _localizationService.GetLocalizedString(ResourceName, "CouponNotValidInCity", culture);
                return false;
            }
        }

        // Location - District
        if (coupon.CouponDistricts.Any())
        {
            if (!context.DistrictId.HasValue || !coupon.CouponDistricts.Any(cd => cd.DistrictId == context.DistrictId.Value))
            {
                failureReason = _localizationService.GetLocalizedString(ResourceName, "CouponNotValidInDistrict", culture);
                return false;
            }
        }

        // Categories Check
        if (coupon.CouponCategories.Any() && context.Items.Any())
        {
            var validCategoryIds = coupon.CouponCategories.Select(cc => cc.CategoryId).ToHashSet();
            // If the coupon is specific to categories, usually at least one item must match
            // or maybe ALL items must match? 
            // Sticking to "Requirement to apply": At least one item must be of the category.
            if (!context.Items.Any(i => i.CategoryId.HasValue && validCategoryIds.Contains(i.CategoryId.Value)))
            {
                failureReason = _localizationService.GetLocalizedString(ResourceName, "CouponRequiresSpecificCategories", culture);
                return false;
            }
        }

        // Products Check
        if (coupon.CouponProducts.Any() && context.Items.Any())
        {
            var validProductIds = coupon.CouponProducts.Select(cp => cp.ProductId).ToHashSet();
            if (!context.Items.Any(i => validProductIds.Contains(i.ProductId)))
            {
                failureReason = _localizationService.GetLocalizedString(ResourceName, "CouponRequiresSpecificProducts", culture);
                return false;
            }
        }

        // Min Cart Amount
        // Ensure checked against Applicable Items Only? For now, total cart.
        if (context.CartTotal < coupon.MinCartAmount)
        {
            failureReason = _localizationService.GetLocalizedString(ResourceName, "CouponMinCartAmountRequired", culture, coupon.MinCartAmount);
            return false;
        }

        return true;
    }
}
