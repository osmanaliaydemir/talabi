using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.Entities;
using Talabi.Portal.Models;
using Talabi.Portal.Services;
using CoreInterfaces = Talabi.Core.Interfaces;

namespace Talabi.Portal.Controllers;

[Authorize]
public class ProfileController : Controller
{
    private readonly CoreInterfaces.IUnitOfWork _unitOfWork;
    private readonly ILocalizationService _localizationService;
    private readonly ILogger<ProfileController> _logger;

    public ProfileController(
        CoreInterfaces.IUnitOfWork unitOfWork,
        ILocalizationService localizationService,
        ILogger<ProfileController> logger)
    {
        _unitOfWork = unitOfWork;
        _localizationService = localizationService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> Complete()
    {
        var vendorIdStr = HttpContext.Session.GetString("VendorId");
        if (string.IsNullOrEmpty(vendorIdStr) || !Guid.TryParse(vendorIdStr, out var vendorId))
        {
            return RedirectToAction("Login", "Auth");
        }

        var vendor = await _unitOfWork.Vendors.GetByIdAsync(vendorId);
        if (vendor == null)
        {
            return RedirectToAction("Login", "Auth");
        }

        // If already complete, redirect to home
        var isProfileComplete = !string.IsNullOrWhiteSpace(vendor.Address) &&
                                vendor.Latitude.HasValue &&
                                vendor.Longitude.HasValue &&
                                !string.IsNullOrWhiteSpace(vendor.Name);

        if (isProfileComplete)
        {
            return RedirectToAction("Index", "Home");
        }

        var model = new VendorProfileDto
        {
            Id = vendor.Id,
            Name = vendor.Name,
            Description = vendor.Description,
            Address = vendor.Address,
            Latitude = vendor.Latitude,
            Longitude = vendor.Longitude,
            ImageUrl = vendor.ImageUrl,
            PhoneNumber = vendor.PhoneNumber
        };

        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Complete(VendorProfileDto model)
    {
        var vendorIdStr = HttpContext.Session.GetString("VendorId");
        if (string.IsNullOrEmpty(vendorIdStr) || !Guid.TryParse(vendorIdStr, out var vendorId))
        {
            return RedirectToAction("Login", "Auth");
        }

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        // Validate mandatory fields manually if needed (though DataAnnotations on DTO is better)
        if (string.IsNullOrWhiteSpace(model.Address) || !model.Latitude.HasValue || !model.Longitude.HasValue)
        {
            ModelState.AddModelError("", _localizationService.GetString("AddressAndLocationRequired"));
            return View(model);
        }

        var vendor = await _unitOfWork.Vendors.GetByIdAsync(vendorId);
        if (vendor == null)
        {
            return NotFound();
        }

        // Update vendor
        vendor.Name = model.Name;
        vendor.Description = model.Description;
        vendor.Address = model.Address;
        vendor.Latitude = model.Latitude;
        vendor.Longitude = model.Longitude;
        vendor.PhoneNumber = model.PhoneNumber;

        // Note: Image upload handling would typically be here or handled via a separate service call
        if (!string.IsNullOrEmpty(model.ImageUrl))
        {
            vendor.ImageUrl = model.ImageUrl;
        }

        _unitOfWork.Vendors.Update(vendor);
        await _unitOfWork.SaveChangesAsync();

        return RedirectToAction("Index", "Home");
    }
}
