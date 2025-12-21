using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;
using Talabi.Core.Interfaces;
using Talabi.Core.Models;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CampaignsController : ControllerBase
{
    private readonly TalabiDbContext _context;
    private readonly IRuleValidatorService _ruleValidator;

    public CampaignsController(TalabiDbContext context, IRuleValidatorService ruleValidator)
    {
        _context = context;
        _ruleValidator = ruleValidator;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Campaign>>> GetCampaigns(
        [FromQuery] Guid? cityId, 
        [FromQuery] Guid? districtId, 
        [FromQuery] int? vendorType)
    {
        var campaigns = await _context.Campaigns
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

        var validCampaigns = new List<Campaign>();

        foreach (var campaign in campaigns)
        {
            // App Mode Filter: If app is in Restaurant mode (1), don't show Market (2) campaigns.
            if (vendorType.HasValue && campaign.VendorType.HasValue && campaign.VendorType != vendorType.Value)
            {
                continue;
            }

            if (_ruleValidator.ValidateCampaign(campaign, context, out _))
            {
                validCampaigns.Add(campaign);
            }
        }

        return validCampaigns
            .OrderBy(c => c.Priority)
            .ThenByDescending(c => c.CreatedAt)
            .ToList();
    }
}
