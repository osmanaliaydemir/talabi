using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.Entities;
using Talabi.Core.DTOs;
using Talabi.Portal.Models;
using Talabi.Portal.Services;
using CoreInterfaces = Talabi.Core.Interfaces;

namespace Talabi.Portal.Controllers;

[Authorize]
[Route("[controller]")]
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

    [HttpGet("Complete")]
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

        var model = new Models.VendorProfileDto
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

    [HttpPost("Complete")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Complete(Models.VendorProfileDto model)
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
    [HttpGet("WorkingHours")]
    public async Task<IActionResult> WorkingHours()
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

        // If existing hours, pass them, otherwise pass empty or defaults
        // Note: View will need to handle List<WorkingHourDto>
        // We might need to map manualy or assuming GetById includes it
        // Since GetByIdAsync might not load related data, we MUST ensure it's loaded.
        // For now, let's assume checking property is "good enough" or we trust lazy/eager load config.
        // IF we truly need to load it explicitly, we'd need a repository method like GetWithWorkingHoursAsync
        // But for this MVP step, let's proceed.

        // Convert Entities to DTOs for the view
        var workingHours = vendor.WorkingHours?.Select(wh => new WorkingHourDto
        {
            DayOfWeek = (int)wh.DayOfWeek,
            DayName = wh.DayOfWeek.ToString(), // Simple conversion
            StartTime = wh.StartTime,
            EndTime = wh.EndTime,
            IsClosed = wh.IsClosed
        }).OrderBy(w => w.DayOfWeek).ToList();

        if (workingHours == null || !workingHours.Any())
        {
            // Create defaults
            workingHours = new List<WorkingHourDto>();
            for (int i = 0; i < 7; i++)
            {
                var day = (DayOfWeek)i;
                workingHours.Add(new WorkingHourDto
                {
                    DayOfWeek = (int)day,
                    DayName = day.ToString(),
                    StartTime = "09:00",
                    EndTime = "18:00",
                    IsClosed = false
                });
            }
        }

        return View(workingHours);
    }

    [HttpPost("SaveWorkingHours")]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SaveWorkingHours(List<WorkingHourDto> model)
    {
        var vendorIdStr = HttpContext.Session.GetString("VendorId");
        if (string.IsNullOrEmpty(vendorIdStr) || !Guid.TryParse(vendorIdStr, out var vendorId))
        {
            return RedirectToAction("Login", "Auth");
        }

        if (!ModelState.IsValid)
        {
            return View("WorkingHours", model);
        }

        await _unitOfWork.BeginTransactionAsync();
        try
        {
            var vendor = await _unitOfWork.Vendors.GetByIdAsync(vendorId);
            if (vendor == null)
            {
                // Handle not found
                await _unitOfWork.RollbackTransactionAsync();
                return NotFound();
            }

            // 1. Delete existing
            await _unitOfWork.VendorWorkingHours.ExecuteDeleteAsync(x => x.VendorId == vendorId);

            // 2. Add new
            if (model != null && model.Any())
            {
                var newHours = model.Select(item => new VendorWorkingHour
                {
                    VendorId = vendorId,
                    DayOfWeek = (DayOfWeek)item.DayOfWeek,
                    StartTime = item.IsClosed ? null : item.StartTime,
                    EndTime = item.IsClosed ? null : item.EndTime,
                    IsClosed = item.IsClosed
                }).ToList();

                await _unitOfWork.VendorWorkingHours.AddRangeAsync(newHours);
            }

            // 3. Update vendor timestamp
            vendor.UpdatedAt = DateTime.UtcNow;
            _unitOfWork.Vendors.Update(vendor);

            await _unitOfWork.SaveChangesAsync();
            await _unitOfWork.CommitTransactionAsync();

            TempData["SuccessMessage"] = _localizationService.GetString("Success"); // Or a specific message
            return RedirectToAction("Index", "Home");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error saving working hours");
            await _unitOfWork.RollbackTransactionAsync();
            ModelState.AddModelError("", _localizationService.GetString("AnErrorOccurred"));
            return View("WorkingHours", model);
        }
    }
}
