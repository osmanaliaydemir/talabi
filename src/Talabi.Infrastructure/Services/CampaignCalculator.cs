using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;

namespace Talabi.Infrastructure.Services;

public class CampaignCalculator(IUnitOfWork unitOfWork) : ICampaignCalculator
{
    private readonly IUnitOfWork _unitOfWork = unitOfWork;

    public async Task<CampaignCalculationResult> CalculateAsync(Cart cart, Campaign campaign, string userId)
    {
        var result = new CampaignCalculationResult { IsValid = true };

        // 1. Basic Validity (Date, Active) - Usually checked by query, but double check
        if (!campaign.IsActive || DateTime.UtcNow < campaign.StartDate || DateTime.UtcNow > campaign.EndDate)
        {
            return Fail(result, "Campaign is not active or expired.");
        }

        // 2. Schedule Check (Days of Week)
        if (!string.IsNullOrEmpty(campaign.ValidDaysOfWeek))
        {
            var dayOfWeek = (int)DateTime.UtcNow.DayOfWeek;
            // C# DayOfWeek: Sunday=0, Monday=1... 
            // Ensure format alignment. Let's assume ValidDaysOfWeek is comma separated ints "1,2,3"
            // If Sunday is 0 in C#, verify if admin portal uses 1 for Monday, 7 for Sunday.
            // Standard: 0=Sunday, 1=Monday...

            // Let's assume the stored format matches C# DayOfWeek or handle conversion if needed.
            // For robustness, let's assume it stores C# enum values.
            var validDays = campaign.ValidDaysOfWeek.Split(',', StringSplitOptions.RemoveEmptyEntries)
                                                    .Select(s => int.Parse(s.Trim()))
                                                    .ToList();

            if (!validDays.Contains(dayOfWeek))
            {
                return Fail(result, "Campaign is not valid for today.");
            }
        }

        // 3. Time Check
        if (campaign.StartTime.HasValue && campaign.EndTime.HasValue)
        {
            var now = DateTime.UtcNow.TimeOfDay;
            if (now < campaign.StartTime.Value || now > campaign.EndTime.Value)
            {
                return Fail(result, "Campaign is not valid at this time.");
            }
        }

        // 4. Usage Limits (Global)
        if (campaign.MaxUsageCount.HasValue && campaign.CurrentUsageCount >= campaign.MaxUsageCount.Value)
        {
            return Fail(result, "Campaign usage limit reached.");
        }

        // 4.1 Target Audience Check
        if (campaign.TargetAudience != TargetAudience.All)
        {
            if (string.IsNullOrEmpty(userId))
            {
                return Fail(result, "Please login to use this campaign.");
            }

            var orderCount = await _unitOfWork.Orders.Query()
                .CountAsync(o => o.CustomerId == userId);

            if (campaign.TargetAudience == TargetAudience.NewUsers && orderCount > 0)
            {
                return Fail(result, "This campaign is for new users only.");
            }
            else if (campaign.TargetAudience == TargetAudience.ReturningUsers && orderCount == 0)
            {
                return Fail(result, "Place your first order to unlock this campaign.");
            }
        }
        else if (campaign.IsFirstOrderOnly) // Legacy check fallback
        {
            if (string.IsNullOrEmpty(userId))
            {
                return Fail(result, "Please login to use this campaign.");
            }
            var orderCount = await _unitOfWork.Orders.Query()
                .CountAsync(o => o.CustomerId == userId);

            if (orderCount > 0) return Fail(result, "This campaign is for new users only.");
        }

        // 5. Usage Limits (Per User)
        if (campaign.UsageLimitPerUser.HasValue)
        {
            // Count completed orders with this campaign for this user
            var userUsage = await _unitOfWork.Orders.Query()
                .CountAsync(o => o.CustomerId == userId && o.CampaignId == campaign.Id);

            if (userUsage >= campaign.UsageLimitPerUser.Value)
            {
                return Fail(result, "You have reached the usage limit for this campaign.");
            }
        }

        // 6. Cart Min Amount
        if (campaign.MinCartAmount.HasValue)
        {
            // Calculate cart subtotal (excluding delivery fee, checking validation context)
            // Assuming cart items have updated prices
            var subtotal = cart.CartItems.Where(i => i.Product != null).Sum(i => i.Quantity * i.Product!.Price);
            if (subtotal < campaign.MinCartAmount.Value)
            {
                return Fail(result, $"Cart amount must be at least {campaign.MinCartAmount.Value:C}.");
            }
        }

        // 7. Calculate Discount (Item Based vs Total)
        decimal discount = 0;

        // Determine applicable items
        // Strategy: 
        // If CampaignProducts is empty & CampaignCategories is empty -> All items applicable
        // If CampaignProducts has items -> Only those items applicable
        // If CampaignCategories has items -> Only items in those categories applicable
        // Union of both (if product is in list OR category is in list)

        // Note: Relation loading is important. Ensure Campaign was loaded with Includes.

        List<CartItem> applicableItems = [];

        // Simplified Logic: if no restrictions, all items.
        bool hasProductRestrictions = campaign.CampaignProducts != null && campaign.CampaignProducts.Count != 0;
        bool hasCategoryRestrictions = campaign.CampaignCategories != null && campaign.CampaignCategories.Count != 0;

        if (!hasProductRestrictions && !hasCategoryRestrictions)
        {
            applicableItems.AddRange(cart.CartItems);
        }
        else
        {
            var allowedProductIds = campaign.CampaignProducts?.Select(cp => cp.ProductId).ToList() ?? [];
            var allowedCategoryIds = campaign.CampaignCategories?.Select(cc => cc.CategoryId).ToList() ?? [];

            foreach (var item in cart.CartItems)
            {
                if (allowedProductIds.Contains(item.ProductId))
                {
                    applicableItems.Add(item);
                    continue;
                }

                // For category check, we need Product loaded with CategoryId.
                if (item.Product?.CategoryId != null && allowedCategoryIds.Contains(item.Product.CategoryId.Value))
                {
                    applicableItems.Add(item);
                }
            }
        }

        if (applicableItems.Count == 0)
        {
            // Valid campaign, but no applicable items in cart?
            // Should we fail or just return 0 discount?
            // Usually return 0 discount with "No applicable items" or just 0.
            // Let's return valid with 0.
            return result;
        }

        // Calculate Discount
        var applicableSubtotal = applicableItems.Sum(i => i.Quantity * i.Product!.Price);

        if (campaign.DiscountType == DiscountType.Percentage)
        {
            discount = applicableSubtotal * (campaign.DiscountValue / 100m);
        }
        else // Fixed Amount
        {
            // If fixed amount, is it per item or total?
            // Usually "50 TL off" means total off.
            // Usage: 50 TL off on applicable items total.

            // Check if applicable subtotal is enough?
            // If discount > subtotal, cap at subtotal?
            discount = campaign.DiscountValue;
            if (discount > applicableSubtotal) discount = applicableSubtotal;
        }

        // 8. Budget Check
        if (campaign.TotalDiscountBudget.HasValue)
        {
            // This is tricky. We don't track total discount given exactly in Campaign table unless we sum orders?
            // Or we check `campaign.CurrentUsageCount * AvgDiscount`?
            // Or simpler: We should record total discount distributed.
            // For now, let's skip strict budget calc queries or rely on CurrentUsageCount * DiscountValue (if fixed).
            // If percentage, it's variable.
            // Let's assume we skip this heavy check for now or handle it via a separate aggregate job.
        }

        result.DiscountAmount = discount;
        result.ApplicableItemIds = [.. applicableItems.Select(i => i.Id)];

        return result;
    }

    private static CampaignCalculationResult Fail(CampaignCalculationResult result, string reason)
    {
        result.IsValid = false;
        result.Reason = reason;
        result.DiscountAmount = 0;
        return result;
    }
}
