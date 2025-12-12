using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class SpecialHolidaysController : Controller
{
    private readonly ISpecialHolidayService _holidayService;
    private readonly IMerchantService _merchantService;
    private readonly ILogger<SpecialHolidaysController> _logger;

    public SpecialHolidaysController(
        ISpecialHolidayService holidayService,
        IMerchantService merchantService,
        ILogger<SpecialHolidaysController> logger)
    {
        _holidayService = holidayService;
        _merchantService = merchantService;
        _logger = logger;
    }

    public async Task<IActionResult> Index(bool includeInactive = false)
    {
        var merchantId = await ResolveMerchantIdAsync();
        if (merchantId == Guid.Empty)
        {
            TempData["ErrorMessage"] = "Merchant bilgisi alınamadı.";
            return RedirectToAction("Index", "Dashboard");
        }

        var holidays = await _holidayService.GetHolidaysAsync(merchantId, includeInactive) ?? new List<SpecialHolidayResponse>();
        var upcoming = await _holidayService.GetUpcomingAsync(merchantId) ?? new List<SpecialHolidayResponse>();
        var availability = await _holidayService.CheckAvailabilityAsync(merchantId);

        var model = new SpecialHolidayListViewModel
        {
            Holidays = holidays.OrderByDescending(h => h.StartDate).ToList(),
            Upcoming = upcoming.OrderBy(h => h.StartDate).ToList(),
            IncludeInactive = includeInactive,
            MerchantId = merchantId,
            Availability = availability
        };

        return View(model);
    }

    [HttpGet]
    public async Task<IActionResult> Create()
    {
        var merchantId = await ResolveMerchantIdAsync();
        if (merchantId == Guid.Empty)
        {
            TempData["ErrorMessage"] = "Merchant bilgisi alınamadı.";
            return RedirectToAction(nameof(Index));
        }

        var model = new SpecialHolidayFormViewModel
        {
            MerchantId = merchantId,
            StartDate = DateTime.Today,
            EndDate = DateTime.Today.AddDays(1),
            IsActive = true
        };

        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(SpecialHolidayFormViewModel model)
    {
        var merchantId = await ResolveMerchantIdAsync();
        if (merchantId == Guid.Empty)
        {
            TempData["ErrorMessage"] = "Merchant bilgisi alınamadı.";
            return RedirectToAction(nameof(Index));
        }

        model.MerchantId = merchantId;
        await ValidateSpecialHolidayAsync(model);

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var request = new CreateSpecialHolidayRequest
        {
            MerchantId = merchantId,
            Title = model.Title,
            Description = model.Description,
            StartDate = model.StartDate,
            EndDate = model.EndDate,
            IsClosed = model.IsClosed,
            SpecialOpenTime = model.IsClosed ? null : ParseTime(model.SpecialOpenTime),
            SpecialCloseTime = model.IsClosed ? null : ParseTime(model.SpecialCloseTime),
            IsRecurring = model.IsRecurring
        };

        var created = await _holidayService.CreateAsync(request);
        TempData[created != null ? "SuccessMessage" : "ErrorMessage"] = created != null
            ? "Özel tatil başarıyla oluşturuldu."
            : "Özel tatil oluşturulamadı.";

        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Edit(Guid id)
    {
        var holiday = await _holidayService.GetByIdAsync(id);
        if (holiday == null)
        {
            TempData["ErrorMessage"] = "Özel tatil bulunamadı.";
            return RedirectToAction(nameof(Index));
        }

        var model = new SpecialHolidayFormViewModel
        {
            Id = holiday.Id,
            MerchantId = holiday.MerchantId,
            Title = holiday.Title,
            Description = holiday.Description,
            StartDate = holiday.StartDate.Date,
            EndDate = holiday.EndDate.Date,
            IsClosed = holiday.IsClosed,
            IsRecurring = holiday.IsRecurring,
            SpecialOpenTime = holiday.SpecialOpenTime?.ToString(@"hh\:mm"),
            SpecialCloseTime = holiday.SpecialCloseTime?.ToString(@"hh\:mm"),
            IsActive = holiday.IsActive
        };

        return View(model);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(Guid id, SpecialHolidayFormViewModel model)
    {
        if (id != model.Id)
        {
            TempData["ErrorMessage"] = "Geçersiz işlem.";
            return RedirectToAction(nameof(Index));
        }

        await ValidateSpecialHolidayAsync(model);
        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var request = new UpdateSpecialHolidayRequest
        {
            Title = model.Title,
            Description = model.Description,
            StartDate = model.StartDate,
            EndDate = model.EndDate,
            IsClosed = model.IsClosed,
            SpecialOpenTime = model.IsClosed ? null : ParseTime(model.SpecialOpenTime),
            SpecialCloseTime = model.IsClosed ? null : ParseTime(model.SpecialCloseTime),
            IsRecurring = model.IsRecurring,
            IsActive = model.IsActive
        };

        var updated = await _holidayService.UpdateAsync(id, request);
        TempData[updated != null ? "SuccessMessage" : "ErrorMessage"] = updated != null
            ? "Özel tatil güncellendi."
            : "Güncelleme sırasında bir hata oluştu.";

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(Guid id)
    {
        var success = await _holidayService.DeleteAsync(id);
        TempData[success ? "SuccessMessage" : "ErrorMessage"] = success
            ? "Özel tatil silindi."
            : "Özel tatil silinemedi.";
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Toggle(Guid id)
    {
        var success = await _holidayService.ToggleStatusAsync(id);
        TempData[success ? "SuccessMessage" : "ErrorMessage"] = success
            ? "Durum güncellendi."
            : "Durum güncellenemedi.";
        return RedirectToAction(nameof(Index));
    }

    private async Task<Guid> ResolveMerchantIdAsync()
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (!string.IsNullOrEmpty(merchantIdStr) && Guid.TryParse(merchantIdStr, out var merchantId) && merchantId != Guid.Empty)
        {
            return merchantId;
        }

        var myMerchant = await _merchantService.GetMyMerchantAsync();
        if (myMerchant != null && myMerchant.Id != Guid.Empty)
        {
            HttpContext.Session.SetString("MerchantId", myMerchant.Id.ToString());
            return myMerchant.Id;
        }

        return Guid.Empty;
    }

    private async Task ValidateSpecialHolidayAsync(SpecialHolidayFormViewModel model)
    {
        if (model.EndDate < model.StartDate)
        {
            ModelState.AddModelError(nameof(model.EndDate), "Bitiş tarihi başlangıç tarihinden önce olamaz.");
        }

        if (!model.IsClosed)
        {
            if (string.IsNullOrWhiteSpace(model.SpecialOpenTime) || string.IsNullOrWhiteSpace(model.SpecialCloseTime))
            {
                ModelState.AddModelError(nameof(model.SpecialOpenTime), "Özel çalışma saatleri için başlangıç ve bitiş saati gereklidir.");
            }
            else
            {
                var open = ParseTime(model.SpecialOpenTime);
                var close = ParseTime(model.SpecialCloseTime);

                if (open == null || close == null)
                {
                    ModelState.AddModelError(nameof(model.SpecialOpenTime), "Geçerli bir saat girin (HH:mm).");
                }
                else if (open >= close)
                {
                    ModelState.AddModelError(nameof(model.SpecialCloseTime), "Kapanış saati açılış saatinden sonra olmalıdır.");
                }
            }
        }

        // If form invalid, ensure upcoming data to display maybe not required
        await Task.CompletedTask;
    }

    private static TimeSpan? ParseTime(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return null;
        }

        return TimeSpan.TryParse(input, out var timeSpan) ? timeSpan : null;
    }
}

