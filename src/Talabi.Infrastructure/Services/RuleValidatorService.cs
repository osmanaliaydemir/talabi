using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Models;

namespace Talabi.Infrastructure.Services;

public class RuleValidatorService : IRuleValidatorService
{
    public bool ValidateCampaign(Campaign campaign, RuleValidationContext context, out string? failureReason)
    {
        failureReason = null;

        if (!campaign.IsActive)
        {
            failureReason = "Campaign is not active.";
            return false;
        }

        // Date Range
        if (context.RequestTime < campaign.StartDate || context.RequestTime > campaign.EndDate)
        {
            failureReason = "Campaign is expired or not yet started.";
            return false;
        }

        // Time of Day
        var timeOfDay = context.RequestTime.TimeOfDay;
        if (campaign.StartTime.HasValue && timeOfDay < campaign.StartTime.Value)
        {
            failureReason = "Campaign not valid at this time.";
            return false;
        }
        if (campaign.EndTime.HasValue && timeOfDay > campaign.EndTime.Value)
        {
            failureReason = "Campaign not valid at this time.";
            return false;
        }

        // Location - City
        if (campaign.CampaignCities.Any())
        {
            if (!context.CityId.HasValue || !campaign.CampaignCities.Any(cc => cc.CityId == context.CityId.Value))
            {
                failureReason = "Campaign not valid in this city.";
                return false;
            }
        }

        // Location - District
        if (campaign.CampaignDistricts.Any())
        {
            if (!context.DistrictId.HasValue || !campaign.CampaignDistricts.Any(cd => cd.DistrictId == context.DistrictId.Value))
            {
                failureReason = "Campaign not valid in this district.";
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
            failureReason = $"Minimum cart amount of {campaign.MinCartAmount} required.";
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
                failureReason = "Campaign requires specific products.";
                return false;
            }
        }

        return true;
    }

    public bool ValidateCoupon(Coupon coupon, RuleValidationContext context, out string? failureReason)
    {
        failureReason = null;

        if (!coupon.IsActive)
        {
            failureReason = "Coupon is not active.";
            return false;
        }

        if (context.RequestTime > coupon.ExpirationDate)
        {
            failureReason = "Coupon has expired.";
            return false;
        }

        // Time of Day
        var timeOfDay = context.RequestTime.TimeOfDay;
        if (coupon.StartTime.HasValue && timeOfDay < coupon.StartTime.Value)
        {
            failureReason = "Coupon not valid at this time.";
            return false;
        }
        if (coupon.EndTime.HasValue && timeOfDay > coupon.EndTime.Value)
        {
            failureReason = "Coupon not valid at this time.";
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
                failureReason = "Coupon not valid for this vendor.";
                return false;
            }
        }

        // Location - City
        if (coupon.CouponCities.Any())
        {
            if (!context.CityId.HasValue || !coupon.CouponCities.Any(cc => cc.CityId == context.CityId.Value))
            {
                failureReason = "Coupon not valid in this city.";
                return false;
            }
        }

        // Location - District
        if (coupon.CouponDistricts.Any())
        {
            if (!context.DistrictId.HasValue || !coupon.CouponDistricts.Any(cd => cd.DistrictId == context.DistrictId.Value))
            {
                failureReason = "Coupon not valid in this district.";
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
                failureReason = "Coupon requires specific categories.";
                return false;
            }
        }

        // Products Check
        if (coupon.CouponProducts.Any() && context.Items.Any())
        {
            var validProductIds = coupon.CouponProducts.Select(cp => cp.ProductId).ToHashSet();
            if (!context.Items.Any(i => validProductIds.Contains(i.ProductId)))
            {
                failureReason = "Coupon requires specific products.";
                return false;
            }
        }

        // Min Cart Amount
        // Ensure checked against Applicable Items Only? For now, total cart.
        if (context.CartTotal < coupon.MinCartAmount)
        {
            failureReason = $"Minimum cart amount of {coupon.MinCartAmount} required.";
            return false;
        }

        return true;
    }
}
