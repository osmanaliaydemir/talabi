using Talabi.Core.Entities;

namespace Talabi.Core.Interfaces;

public interface ICampaignCalculator
{
    /// <summary>
    /// Calculates discount for a given cart based on the campaign rules.
    /// </summary>
    /// <param name="cart">The cart to calculate discount for.</param>
    /// <param name="campaign">The campaign to apply.</param>
    /// <param name="userId">The ID of the user (for usage checks).</param>
    /// <returns>Validation result and calculated discount amount.</returns>
    Task<CampaignCalculationResult> CalculateAsync(Cart cart, Campaign campaign, string userId);
}

public class CampaignCalculationResult
{
    public bool IsValid { get; set; }
    public string? Reason { get; set; }
    public decimal DiscountAmount { get; set; }
    public List<Guid> ApplicableItemIds { get; set; } = new();
}
