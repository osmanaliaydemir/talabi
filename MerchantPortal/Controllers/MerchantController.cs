using System.Linq;
using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class MerchantController : Controller
{
    private readonly IMerchantService _merchantService;
    private readonly IWorkingHoursService _workingHoursService;
    private readonly IServiceCategoryDirectory _serviceCategoryDirectory;
    private readonly ILogger<MerchantController> _logger;

    /// <summary>
    /// MerchantController constructor
    /// </summary>
    /// <param name="merchantService">Merchant servisi</param>
    /// <param name="workingHoursService">Çalışma saatleri servisi</param>
    /// <param name="logger">Logger instance</param>
    public MerchantController(IMerchantService merchantService, IWorkingHoursService workingHoursService, IServiceCategoryDirectory serviceCategoryDirectory, ILogger<MerchantController> logger)
    {
        _merchantService = merchantService;
        _workingHoursService = workingHoursService;
        _serviceCategoryDirectory = serviceCategoryDirectory;
        _logger = logger;
    }

    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Directory(string? categoryType = null, bool onlyActive = false, int page = 1)
    {
        const int pageSize = 20;

        PagedResult<MerchantResponse>? merchants;
        if (!string.IsNullOrWhiteSpace(categoryType))
        {
            if (onlyActive)
            {
                var active = await _merchantService.GetActiveMerchantsByCategoryTypeAsync(categoryType) ?? new List<MerchantResponse>();
                merchants = new PagedResult<MerchantResponse>
                {
                    Items = active,
                    Page = 1,
                    PageSize = active.Count,
                    TotalCount = active.Count,
                    TotalPages = 1
                };
            }
            else
            {
                merchants = await _merchantService.GetMerchantsByCategoryTypeAsync(categoryType, page, pageSize);
            }
        }
        else
        {
            merchants = await _merchantService.GetMerchantsAsync(page, pageSize);
            if (onlyActive && merchants != null)
            {
                merchants.Items = merchants.Items.Where(m => m.IsActive).ToList();
                merchants.TotalCount = merchants.Items.Count;
                merchants.TotalPages = 1;
                merchants.Page = 1;
                merchants.PageSize = merchants.Items.Count;
            }
        }

        var serviceCategories = await _serviceCategoryDirectory.GetServiceCategoriesAsync() ?? Array.Empty<ServiceCategoryResponse>();

        var viewModel = new MerchantListViewModel
        {
            Merchants = merchants ?? new PagedResult<MerchantResponse>(),
            Filter = new MerchantListFilter
            {
                CategoryType = categoryType,
                OnlyActive = onlyActive,
                Page = page
            },
            ServiceCategories = serviceCategories
        };

        return View(viewModel);
    }

    [Authorize(Roles = "Admin")]
    [HttpGet]
    public async Task<IActionResult> Create()
    {
        var categories = await _serviceCategoryDirectory.GetServiceCategoriesAsync() ?? Array.Empty<ServiceCategoryResponse>();
        var model = new MerchantCreateViewModel
        {
            ServiceCategories = categories
        };
        return View(model);
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(MerchantCreateViewModel model)
    {
        model.ServiceCategories = await _serviceCategoryDirectory.GetServiceCategoriesAsync() ?? Array.Empty<ServiceCategoryResponse>();

        if (!ModelState.IsValid)
        {
            return View(model);
        }

        var request = new CreateMerchantRequest
        {
            Name = model.Input.Name,
            Description = model.Input.Description,
            ServiceCategoryId = model.Input.ServiceCategoryId,
            Address = model.Input.Address,
            Latitude = model.Input.Latitude,
            Longitude = model.Input.Longitude,
            PhoneNumber = model.Input.PhoneNumber,
            Email = model.Input.Email,
            MinimumOrderAmount = model.Input.MinimumOrderAmount,
            DeliveryFee = model.Input.DeliveryFee
        };

        var created = await _merchantService.CreateMerchantAsync(request);
        if (created == null)
        {
            ModelState.AddModelError(string.Empty, "Mağaza oluşturulamadı. Lütfen bilgileri kontrol edin.");
            return View(model);
        }

        TempData["SuccessMessage"] = "Mağaza başarıyla oluşturuldu.";
        return RedirectToAction(nameof(Directory));
    }

    [Authorize(Roles = "Admin")]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(Guid id)
    {
        var success = await _merchantService.DeleteMerchantAsync(id);
        TempData[success ? "SuccessMessage" : "ErrorMessage"] = success
            ? "Mağaza silindi."
            : "Mağaza silme işlemi başarısız oldu.";
        return RedirectToAction(nameof(Directory));
    }

    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> Details(Guid id)
    {
        var merchant = await _merchantService.GetMerchantByIdAsync(id);
        if (merchant == null)
        {
            TempData["ErrorMessage"] = "Mağaza bulunamadı.";
            return RedirectToAction(nameof(Directory));
        }

        var categories = await _serviceCategoryDirectory.GetServiceCategoriesAsync() ?? Array.Empty<ServiceCategoryResponse>();
        var viewModel = new MerchantDetailViewModel
        {
            Merchant = merchant,
            ServiceCategories = categories
        };

        return View(viewModel);
    }

    /// <summary>
    /// Merchant profil sayfasını göster
    /// </summary>
    /// <returns>Profil düzenleme sayfasına yönlendirme</returns>
    public IActionResult Profile()
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
        {
            TempData["ErrorMessage"] = "Merchant bilgisi bulunamadı";
            return RedirectToAction("Index", "Dashboard");
        }

        // Get merchant from session or API (implement later)
        // For now, redirect to edit with merchantId
        return RedirectToAction(nameof(Edit), new { id = merchantId });
    }

    /// <summary>
    /// Merchant düzenleme sayfasını göster
    /// </summary>
    /// <param name="id">Merchant ID</param>
    /// <returns>Merchant düzenleme sayfası veya yönlendirme</returns>
    [HttpGet]
    public async Task<IActionResult> Edit(Guid id)
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var sessionMerchantId))
        {
            return RedirectToAction("Login", "Auth");
        }

        // Security check - can only edit own merchant
        if (id != sessionMerchantId)
        {
            TempData["ErrorMessage"] = "Bu işlemi yapmaya yetkiniz yok";
            return RedirectToAction("Index", "Dashboard");
        }

        // Get merchant details from API
        var merchant = await _merchantService.GetMyMerchantAsync();
        
        if (merchant == null)
        {
            TempData["ErrorMessage"] = "Mağaza bilgileri yüklenemedi";
            return RedirectToAction("Index", "Dashboard");
        }

        var model = new UpdateMerchantRequest
        {
            Name = merchant.Name,
            Description = merchant.Description,
            Address = merchant.Address,
            Latitude = merchant.Latitude,
            Longitude = merchant.Longitude,
            PhoneNumber = merchant.PhoneNumber,
            Email = merchant.Email,
            MinimumOrderAmount = merchant.MinimumOrderAmount,
            DeliveryFee = merchant.DeliveryFee,
            AverageDeliveryTime = merchant.AverageDeliveryTime,
            IsActive = merchant.IsActive,
            IsBusy = merchant.IsBusy,
            LogoUrl = merchant.LogoUrl,
            CoverImageUrl = merchant.CoverImageUrl
        };

        ViewBag.MerchantId = id;
        ViewBag.MerchantName = merchant.Name;
        return View(model);
    }

    /// <summary>
    /// Merchant bilgilerini güncelle
    /// </summary>
    /// <param name="id">Merchant ID</param>
    /// <param name="model">Güncellenecek bilgiler</param>
    /// <returns>Merchant düzenleme sayfası veya yönlendirme</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(Guid id, UpdateMerchantRequest model)
    {
        if (!ModelState.IsValid)
        {
            ViewBag.MerchantId = id;
            return View(model);
        }

        var result = await _merchantService.UpdateMerchantAsync(id, model);

        if (result == null)
        {
            ModelState.AddModelError(string.Empty, "Profil güncellenirken bir hata oluştu");
            ViewBag.MerchantId = id;
            return View(model);
        }

        TempData["SuccessMessage"] = "Profil başarıyla güncellendi";
        return RedirectToAction(nameof(Edit), new { id });
    }

    /// <summary>
    /// Çalışma saatleri sayfasını göster
    /// </summary>
    /// <returns>Çalışma saatleri sayfası veya giriş sayfasına yönlendirme</returns>
    [HttpGet]
    public async Task<IActionResult> WorkingHours()
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
        {
            return RedirectToAction("Login", "Auth");
        }

        // Get working hours from API
        var workingHours = await _workingHoursService.GetWorkingHoursByMerchantAsync(merchantId);
        
        // If no working hours exist, create default schedule
        if (workingHours == null || !workingHours.Any())
        {
            workingHours = new List<WorkingHoursResponse>
            {
                new() { Id = Guid.Empty, MerchantId = merchantId, DayOfWeek = "Monday", OpenTime = new TimeSpan(9, 0, 0), CloseTime = new TimeSpan(18, 0, 0), IsClosed = false, IsOpen24Hours = false },
                new() { Id = Guid.Empty, MerchantId = merchantId, DayOfWeek = "Tuesday", OpenTime = new TimeSpan(9, 0, 0), CloseTime = new TimeSpan(18, 0, 0), IsClosed = false, IsOpen24Hours = false },
                new() { Id = Guid.Empty, MerchantId = merchantId, DayOfWeek = "Wednesday", OpenTime = new TimeSpan(9, 0, 0), CloseTime = new TimeSpan(18, 0, 0), IsClosed = false, IsOpen24Hours = false },
                new() { Id = Guid.Empty, MerchantId = merchantId, DayOfWeek = "Thursday", OpenTime = new TimeSpan(9, 0, 0), CloseTime = new TimeSpan(18, 0, 0), IsClosed = false, IsOpen24Hours = false },
                new() { Id = Guid.Empty, MerchantId = merchantId, DayOfWeek = "Friday", OpenTime = new TimeSpan(9, 0, 0), CloseTime = new TimeSpan(18, 0, 0), IsClosed = false, IsOpen24Hours = false },
                new() { Id = Guid.Empty, MerchantId = merchantId, DayOfWeek = "Saturday", OpenTime = new TimeSpan(10, 0, 0), CloseTime = new TimeSpan(16, 0, 0), IsClosed = false, IsOpen24Hours = false },
                new() { Id = Guid.Empty, MerchantId = merchantId, DayOfWeek = "Sunday", OpenTime = new TimeSpan(0, 0, 0), CloseTime = new TimeSpan(0, 0, 0), IsClosed = true, IsOpen24Hours = false }
            };
        }

        ViewBag.MerchantId = merchantId;
        return View(workingHours);
    }

    /// <summary>
    /// Çalışma saatlerini güncelle
    /// </summary>
    /// <param name="workingHours">Çalışma saatleri listesi</param>
    /// <returns>Çalışma saatleri sayfasına yönlendirme</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateWorkingHours(List<UpdateWorkingHoursRequest> workingHours)
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
        {
            return RedirectToAction("Login", "Auth");
        }

        // Call API to update working hours
        var result = await _workingHoursService.BulkUpdateWorkingHoursAsync(merchantId, workingHours);

        if (result)
        {
            TempData["SuccessMessage"] = "Çalışma saatleri başarıyla güncellendi";
        }
        else
        {
            TempData["ErrorMessage"] = "Çalışma saatleri güncellenirken bir hata oluştu";
        }
        
        return RedirectToAction(nameof(WorkingHours));
    }

    /// <summary>
    /// Ayarlar sayfasını göster
    /// </summary>
    /// <returns>Ayarlar sayfası veya giriş sayfasına yönlendirme</returns>
    [HttpGet]
    public IActionResult Settings()
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
        {
            return RedirectToAction("Login", "Auth");
        }

        ViewBag.MerchantId = merchantId;
        return View();
    }
}

