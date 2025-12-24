using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Models;
using System.Security.Claims;

using AutoMapper;
using Talabi.Core.DTOs;
using Talabi.Core.Enums;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CampaignsController(IUnitOfWork unitOfWork, IRuleValidatorService ruleValidator, IMapper mapper) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Campaign>>> GetCampaigns(
        [FromQuery] Guid? cityId,
        [FromQuery] Guid? districtId,
        [FromQuery] int? vendorType)
    {
        var campaigns = await unitOfWork.Campaigns.Query()
            .Include(c => c.CampaignCities)
            .Include(c => c.CampaignDistricts)
            .Include(c => c.CampaignCategories)
            .Include(c => c.CampaignProducts)
            .Where(c => c.IsActive && c.StartDate <= DateTime.UtcNow && c.EndDate > DateTime.UtcNow)
            .ToListAsync();

        var context = new RuleValidationContext
        {
            RequestTime = DateTime.UtcNow,
            CityId = cityId,
            DistrictId = districtId
        };

        // Check for authenticated user to determine First Order status
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userIdString != null && Guid.TryParse(userIdString, out var userId))
        {
            context.UserId = userId;
            context.IsFirstOrder = !await unitOfWork.Orders.Query().AnyAsync(o => o.CustomerId == userIdString);
        }
        else
        {
            // Anonymous user -> assume First Order for display purposes?
            // Usually yes, to entice them.
            context.IsFirstOrder = true;
        }

        var validCampaigns = new List<Campaign>();

        foreach (var campaign in campaigns)
        {
            // App Mode Filter: If app is in Restaurant mode (1), don't show Market (2) campaigns.
            if (vendorType.HasValue && campaign.VendorType.HasValue && campaign.VendorType != vendorType.Value)
            {
                continue;
            }

            if (ruleValidator.ValidateCampaign(campaign, context, out _))
            {
                validCampaigns.Add(campaign);
            }
        }

        return validCampaigns
            .OrderBy(c => c.Priority)
            .ThenByDescending(c => c.CreatedAt)
            .ToList();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Campaign>> GetCampaignById(Guid id)
    {
        var campaign = await unitOfWork.Campaigns.Query()
            .Include(c => c.CampaignCities)
            .Include(c => c.CampaignDistricts)
            .Include(c => c.CampaignCategories)
            .Include(c => c.CampaignProducts)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (campaign == null)
        {
            return NotFound(new { message = $"Campaign with ID {id} not found." });
        }

        // Just return the campaign details without validation
        // Mobile app needs this to display campaign info even if it's expired or inactive
        return Ok(campaign);
    }

    /// <summary>
    /// Kampanyaya dahil olan ürünleri getirir.
    /// </summary>
    [HttpGet("{id}/products")]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetCampaignProducts(Guid id)
    {
        var campaign = await unitOfWork.Campaigns.Query()
            .Include(c => c.CampaignCategories)
            .Include(c => c.CampaignProducts)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (campaign == null)
        {
            return NotFound(new { message = "Campaign not found" });
        }

        var query = unitOfWork.Products.Query()
            .Include(p => p.Vendor)
            .Where(p => p.IsAvailable && p.Vendor!.IsActive);

        // Vendor Type Filter
        if (campaign.VendorType.HasValue)
        {
            query = query.Where(p => p.VendorType == (VendorType)campaign.VendorType || (p.Vendor != null && p.Vendor.Type == (VendorType)campaign.VendorType));
        }

        // Product/Category Filter
        var productIds = campaign.CampaignProducts.Select(cp => cp.ProductId).ToList();
        var categoryIds = campaign.CampaignCategories.Select(cc => cc.CategoryId).ToList();

        if (productIds.Any() || categoryIds.Any())
        {
            query = query.Where(p => productIds.Contains(p.Id) || (p.CategoryId.HasValue && categoryIds.Contains(p.CategoryId.Value)));
        }
        else
        {
            // If no specific inclusions, and it's a "General" campaign (e.g. "All Store"),
            // checking simple limits like StartDate/EndDate might be enough?
            // But usually we don't want to dump DB.
            // Let's limit to 50 "Featured" or random products?
            // Or if VendorType is set, it's effectively "All Restaurant Products".
            // That's fine, but paginate.
        }

        var products = await query.Take(50).ToListAsync();

        var productDtos = mapper.Map<List<ProductDto>>(products);

        return Ok(productDtos);
    }
}
