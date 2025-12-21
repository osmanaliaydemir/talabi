using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;

namespace Talabi.Portal.Controllers;

[Authorize(Roles = "Admin,Vendor")]
public class CampaignsController(IUnitOfWork unitOfWork) : Controller
{
    public async Task<IActionResult> Index()
    {
        var campaigns = await unitOfWork.Campaigns.Query()
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync();
        return View(campaigns);
    }

    public async Task<IActionResult> Create()
    {
        var model = new CampaignFormViewModel();
        await PrepareDropDowns(model);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(CampaignFormViewModel model)
    {
        if (ModelState.IsValid)
        {
            var campaign = new Campaign
            {
                Id = Guid.NewGuid(),
                Title = model.Title,
                Description = model.Description,
                ImageUrl = model.ImageUrl,
                StartDate = model.StartDate,
                EndDate = model.EndDate,
                IsActive = model.IsActive,
                ActionUrl = model.ActionUrl,
                Priority = model.Priority,
                VendorType = model.VendorType,
                DiscountType = (DiscountType)model.DiscountType,
                DiscountValue = model.DiscountValue,
                StartTime = model.StartTime,
                EndTime = model.EndTime,
                MinCartAmount = model.MinCartAmount,
                CreatedAt = DateTime.UtcNow
            };

            // Relations
            if (model.SelectedCityIds.Any())
            {
                foreach (var cityId in model.SelectedCityIds)
                {
                    campaign.CampaignCities.Add(new CampaignCity { CampaignId = campaign.Id, CityId = cityId });
                }
            }
            if (model.SelectedDistrictIds.Any())
            {
                foreach (var distId in model.SelectedDistrictIds)
                {
                    campaign.CampaignDistricts.Add(new CampaignDistrict { CampaignId = campaign.Id, DistrictId = distId });
                }
            }
            if (model.SelectedCategoryIds.Any())
            {
                foreach (var catId in model.SelectedCategoryIds)
                {
                    campaign.CampaignCategories.Add(new CampaignCategory { CampaignId = campaign.Id, CategoryId = catId });
                }
            }
            if (model.SelectedProductIds.Any())
            {
                foreach (var prodId in model.SelectedProductIds)
                {
                    campaign.CampaignProducts.Add(new CampaignProduct { CampaignId = campaign.Id, ProductId = prodId });
                }
            }

            await unitOfWork.Campaigns.AddAsync(campaign);
            await unitOfWork.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }
        
        await PrepareDropDowns(model);
        return View(model);
    }

    public async Task<IActionResult> Edit(Guid? id)
    {
        if (id == null) return NotFound();

        var campaign = await unitOfWork.Campaigns.Query()
            .Include(c => c.CampaignCities)
            .Include(c => c.CampaignDistricts)
            .Include(c => c.CampaignCategories)
            .Include(c => c.CampaignProducts)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (campaign == null) return NotFound();
        
        var model = new CampaignFormViewModel
        {
            Id = campaign.Id,
            Title = campaign.Title,
            Description = campaign.Description,
            ImageUrl = campaign.ImageUrl,
            StartDate = campaign.StartDate,
            EndDate = campaign.EndDate,
            IsActive = campaign.IsActive,
            ActionUrl = campaign.ActionUrl,
            Priority = campaign.Priority,
            VendorType = campaign.VendorType,
            DiscountType = (int)campaign.DiscountType,
            DiscountValue = campaign.DiscountValue,
            StartTime = campaign.StartTime,
            EndTime = campaign.EndTime,
            MinCartAmount = campaign.MinCartAmount,
            
            SelectedCityIds = campaign.CampaignCities.Select(x => x.CityId).ToList(),
            SelectedDistrictIds = campaign.CampaignDistricts.Select(x => x.DistrictId).ToList(),
            SelectedCategoryIds = campaign.CampaignCategories.Select(x => x.CategoryId).ToList(),
            SelectedProductIds = campaign.CampaignProducts.Select(x => x.ProductId).ToList()
        };

        await PrepareDropDowns(model);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(Guid id, CampaignFormViewModel model)
    {
        if (id != model.Id) return NotFound();

        if (ModelState.IsValid)
        {
            try
            {
                var campaign = await unitOfWork.Campaigns.Query()
                    .Include(c => c.CampaignCities)
                    .Include(c => c.CampaignDistricts)
                    .Include(c => c.CampaignCategories)
                    .Include(c => c.CampaignProducts)
                    .FirstOrDefaultAsync(c => c.Id == id);

                if (campaign == null) return NotFound();

                // Update properties
                campaign.Title = model.Title;
                campaign.Description = model.Description;
                campaign.ImageUrl = model.ImageUrl;
                campaign.StartDate = model.StartDate;
                campaign.EndDate = model.EndDate;
                campaign.IsActive = model.IsActive;
                campaign.ActionUrl = model.ActionUrl;
                campaign.Priority = model.Priority;
                campaign.VendorType = model.VendorType;
                campaign.DiscountType = (DiscountType)model.DiscountType;
                campaign.DiscountValue = model.DiscountValue;
                campaign.StartTime = model.StartTime;
                campaign.EndTime = model.EndTime;
                campaign.MinCartAmount = model.MinCartAmount;
                campaign.UpdatedAt = DateTime.UtcNow;

                // Update Relations
                // Cities
                campaign.CampaignCities.Clear();
                foreach (var cid in model.SelectedCityIds)
                    campaign.CampaignCities.Add(new CampaignCity { CampaignId = campaign.Id, CityId = cid });

                // Districts
                campaign.CampaignDistricts.Clear();
                foreach (var did in model.SelectedDistrictIds)
                    campaign.CampaignDistricts.Add(new CampaignDistrict { CampaignId = campaign.Id, DistrictId = did });

                // Categories
                campaign.CampaignCategories.Clear();
                foreach (var catId in model.SelectedCategoryIds)
                    campaign.CampaignCategories.Add(new CampaignCategory { CampaignId = campaign.Id, CategoryId = catId });

                // Products
                campaign.CampaignProducts.Clear();
                foreach (var pid in model.SelectedProductIds)
                    campaign.CampaignProducts.Add(new CampaignProduct { CampaignId = campaign.Id, ProductId = pid });

                unitOfWork.Campaigns.Update(campaign);
                await unitOfWork.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!await CampaignExists(model.Id)) return NotFound();
                else throw;
            }
            return RedirectToAction(nameof(Index));
        }
        
        await PrepareDropDowns(model);
        return View(model);
    }
    
    [HttpPost]
    public async Task<IActionResult> ToggleStatus(Guid id)
    {
        var campaign = await unitOfWork.Campaigns.GetByIdAsync(id);
        if (campaign == null) return NotFound();

        campaign.IsActive = !campaign.IsActive;
        unitOfWork.Campaigns.Update(campaign); // Explicit update, though tracking might handle it
        await unitOfWork.SaveChangesAsync();
        
        return RedirectToAction(nameof(Index));
    }

    private async Task<bool> CampaignExists(Guid id)
    {
        return await unitOfWork.Campaigns.ExistsAsync(e => e.Id == id);
    }

    private async Task PrepareDropDowns(CampaignFormViewModel model)
    {
        model.Cities = await unitOfWork.Cities.Query()
            .Select(c => new SelectListItem { Value = c.Id.ToString(), Text = c.NameTr })
            .ToListAsync();
        
        model.Districts = await unitOfWork.Districts.Query()
            .Include(d => d.City)
            .Select(d => new SelectListItem { Value = d.Id.ToString(), Text = $"{d.NameTr} ({d.City!.NameTr})" })
            .ToListAsync();

        model.Categories = await unitOfWork.Categories.Query()
            .Select(c => new SelectListItem { Value = c.Id.ToString(), Text = c.Name })
            .ToListAsync();

        model.Products = await unitOfWork.Products.Query()
            .Take(500)
            .Select(p => new SelectListItem { Value = p.Id.ToString(), Text = p.Name })
            .ToListAsync();
    }
}
