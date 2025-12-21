using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Rendering;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;

namespace Talabi.Portal.Controllers;

[Authorize(Roles = "Admin,Vendor")]
public class CouponsController(IUnitOfWork unitOfWork) : Controller
{
    public async Task<IActionResult> Index()
    {
        var coupons = await unitOfWork.Coupons.Query()
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync();
        return View(coupons);
    }

    public async Task<IActionResult> Create()
    {
        var model = new CouponFormViewModel();
        await PrepareDropDowns(model);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(CouponFormViewModel model)
    {
        if (ModelState.IsValid)
        {
            var coupon = new Coupon
            {
                Id = Guid.NewGuid(),
                Code = model.Code,
                Title = model.Title,
                Description = model.Description,
                DiscountType = model.DiscountType,
                DiscountValue = model.DiscountValue,
                MinCartAmount = model.MinCartAmount,
                ExpirationDate = model.ExpirationDate,
                IsActive = model.IsActive,
                VendorType = model.VendorType,
                VendorId = model.VendorId,
                StartTime = model.StartTime,
                EndTime = model.EndTime,
                CreatedAt = DateTime.UtcNow
            };

            // Relations
            if (model.SelectedCityIds.Any())
            {
                foreach (var cityId in model.SelectedCityIds)
                {
                    coupon.CouponCities.Add(new CouponCity { CouponId = coupon.Id, CityId = cityId });
                }
            }
            if (model.SelectedDistrictIds.Any())
            {
                foreach (var distId in model.SelectedDistrictIds)
                {
                    coupon.CouponDistricts.Add(new CouponDistrict { CouponId = coupon.Id, DistrictId = distId });
                }
            }
            if (model.SelectedCategoryIds.Any())
            {
                foreach (var catId in model.SelectedCategoryIds)
                {
                    coupon.CouponCategories.Add(new CouponCategory { CouponId = coupon.Id, CategoryId = catId });
                }
            }
            if (model.SelectedProductIds.Any())
            {
                foreach (var prodId in model.SelectedProductIds)
                {
                    coupon.CouponProducts.Add(new CouponProduct { CouponId = coupon.Id, ProductId = prodId });
                }
            }

            await unitOfWork.Coupons.AddAsync(coupon);
            await unitOfWork.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }
        
        await PrepareDropDowns(model);
        return View(model);
    }

    public async Task<IActionResult> Edit(Guid? id)
    {
        if (id == null) return NotFound();

        var coupon = await unitOfWork.Coupons.Query()
            .Include(c => c.CouponCities)
            .Include(c => c.CouponDistricts)
            .Include(c => c.CouponCategories)
            .Include(c => c.CouponProducts)
            .FirstOrDefaultAsync(c => c.Id == id);

        if (coupon == null) return NotFound();
        
        var model = new CouponFormViewModel
        {
            Id = coupon.Id,
            Code = coupon.Code,
            Title = coupon.Title,
            Description = coupon.Description,
            DiscountType = coupon.DiscountType,
            DiscountValue = coupon.DiscountValue,
            MinCartAmount = coupon.MinCartAmount,
            ExpirationDate = coupon.ExpirationDate,
            IsActive = coupon.IsActive,
            VendorType = coupon.VendorType,
            VendorId = coupon.VendorId,
            StartTime = coupon.StartTime,
            EndTime = coupon.EndTime,
            
            SelectedCityIds = coupon.CouponCities.Select(x => x.CityId).ToList(),
            SelectedDistrictIds = coupon.CouponDistricts.Select(x => x.DistrictId).ToList(),
            SelectedCategoryIds = coupon.CouponCategories.Select(x => x.CategoryId).ToList(),
            SelectedProductIds = coupon.CouponProducts.Select(x => x.ProductId).ToList()
        };

        await PrepareDropDowns(model);
        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(Guid id, CouponFormViewModel model)
    {
        if (id != model.Id) return NotFound();

        if (ModelState.IsValid)
        {
            try
            {
                var coupon = await unitOfWork.Coupons.Query()
                    .Include(c => c.CouponCities)
                    .Include(c => c.CouponDistricts)
                    .Include(c => c.CouponCategories)
                    .Include(c => c.CouponProducts)
                    .FirstOrDefaultAsync(c => c.Id == id);

                if (coupon == null) return NotFound();

                // Update properties
                coupon.Code = model.Code;
                coupon.Title = model.Title;
                coupon.Description = model.Description;
                coupon.DiscountType = model.DiscountType;
                coupon.DiscountValue = model.DiscountValue;
                coupon.MinCartAmount = model.MinCartAmount;
                coupon.ExpirationDate = model.ExpirationDate;
                coupon.IsActive = model.IsActive;
                coupon.VendorType = model.VendorType;
                coupon.VendorId = model.VendorId;
                coupon.StartTime = model.StartTime;
                coupon.EndTime = model.EndTime;
                coupon.UpdatedAt = DateTime.UtcNow;

                // Update Relations
                // Cities
                coupon.CouponCities.Clear();
                foreach (var cid in model.SelectedCityIds)
                    coupon.CouponCities.Add(new CouponCity { CouponId = coupon.Id, CityId = cid });

                // Districts
                coupon.CouponDistricts.Clear();
                foreach (var did in model.SelectedDistrictIds)
                    coupon.CouponDistricts.Add(new CouponDistrict { CouponId = coupon.Id, DistrictId = did });

                // Categories
                coupon.CouponCategories.Clear();
                foreach (var catId in model.SelectedCategoryIds)
                    coupon.CouponCategories.Add(new CouponCategory { CouponId = coupon.Id, CategoryId = catId });

                // Products
                coupon.CouponProducts.Clear();
                foreach (var pid in model.SelectedProductIds)
                    coupon.CouponProducts.Add(new CouponProduct { CouponId = coupon.Id, ProductId = pid });

                unitOfWork.Coupons.Update(coupon);
                await unitOfWork.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!await CouponExists(model.Id)) return NotFound();
                else throw;
            }
            return RedirectToAction(nameof(Index));
        }
        
        await PrepareDropDowns(model);
        return View(model);
    }
    
    // Simple toggle active status
    [HttpPost]
    public async Task<IActionResult> ToggleStatus(Guid id)
    {
        var coupon = await unitOfWork.Coupons.GetByIdAsync(id);
        if (coupon == null) return NotFound();

        coupon.IsActive = !coupon.IsActive;
        unitOfWork.Coupons.Update(coupon);
        await unitOfWork.SaveChangesAsync();
        
        return RedirectToAction(nameof(Index));
    }

    private async Task<bool> CouponExists(Guid id)
    {
        return await unitOfWork.Coupons.ExistsAsync(e => e.Id == id);
    }

    private async Task PrepareDropDowns(CouponFormViewModel model)
    {
        // Cities
        model.Cities = await unitOfWork.Cities.Query()
            .Select(c => new SelectListItem { Value = c.Id.ToString(), Text = c.NameTr })
            .ToListAsync();
        
        // Districts
        model.Districts = await unitOfWork.Districts.Query()
            .Include(d => d.City)
            .Select(d => new SelectListItem { Value = d.Id.ToString(), Text = $"{d.NameTr} ({d.City!.NameTr})" })
            .ToListAsync();

        model.Categories = await unitOfWork.Categories.Query()
            .Select(c => new SelectListItem { Value = c.Id.ToString(), Text = c.Name })
            .ToListAsync();

        model.Vendors = await unitOfWork.Vendors.Query()
            .Select(v => new SelectListItem { Value = v.Id.ToString(), Text = v.Name })
            .ToListAsync();
            
        // Products - Limit to 500 for perf
        model.Products = await unitOfWork.Products.Query()
            .Take(500)
            .Select(p => new SelectListItem { Value = p.Id.ToString(), Text = p.Name })
            .ToListAsync();
    }
}
