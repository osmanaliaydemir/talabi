using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Models;
using System.Security.Claims;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CampaignsController(IUnitOfWork unitOfWork, IRuleValidatorService ruleValidator) : ControllerBase
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

        // Validate campaign is active and within date range
        if (!campaign.IsActive || campaign.StartDate > DateTime.UtcNow || campaign.EndDate < DateTime.UtcNow)
        {
            return NotFound(new { message = $"Campaign with ID {id} is not currently active." });
        }

        // Build validation context
        var context = new RuleValidationContext
        {
            RequestTime = DateTime.UtcNow
        };

        // Check for authenticated user
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userIdString != null && Guid.TryParse(userIdString, out var userId))
        {
            context.UserId = userId;
            context.IsFirstOrder = !await unitOfWork.Orders.Query().AnyAsync(o => o.CustomerId == userIdString);
        }
        else
        {
            context.IsFirstOrder = true;
        }

        // Validate campaign rules
        if (!ruleValidator.ValidateCampaign(campaign, context, out var failureReason))
        {
            return NotFound(new { message = $"Campaign with ID {id} is not valid for current context: {failureReason}" });
        }

        return Ok(campaign);
    }
}
