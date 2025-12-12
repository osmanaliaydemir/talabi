using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class CategoriesController : Controller
{
    private readonly ICategoryService _categoryService;
    private readonly ILogger<CategoriesController> _logger;

    public CategoriesController(ICategoryService categoryService, ILogger<CategoriesController> logger)
    {
        _categoryService = categoryService;
        _logger = logger;
    }

    /// <summary>
    /// Kategori listesini göster
    /// </summary>
    /// <returns>Kategori listesi sayfası</returns>
    public async Task<IActionResult> Index()
    {
        // Standart kategorileri getir (ServiceCategory bazlı)
        var standardCategories = await _categoryService.GetStandardCategoriesAsync();
        
        // Merchant'ın özel kategorilerini getir
        var customCategories = await _categoryService.GetMyCategoriesAsync();
        
        ViewBag.StandardCategories = standardCategories ?? new();
        ViewBag.CustomCategories = customCategories ?? new();
        ViewBag.IsAdmin = IsAdminUser();
        
        return View();
    }

    /// <summary>
    /// Yeni kategori oluşturma sayfasını göster
    /// </summary>
    /// <returns>Kategori oluşturma sayfası</returns>
    [HttpGet]
    public async Task<IActionResult> Create()
    {
        var categories = await _categoryService.GetMyCategoriesAsync();
        ViewBag.Categories = categories ?? new();
        
        return View();
    }

    /// <summary>
    /// Yeni kategori oluştur
    /// </summary>
    /// <param name="model">Kategori bilgileri</param>
    /// <returns>Kategori oluşturma sayfası veya listeye yönlendirme</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(CreateCategoryRequest model)
    {
        if (!ModelState.IsValid)
        {
            var categories = await _categoryService.GetMyCategoriesAsync();
            ViewBag.Categories = categories ?? new();
            return View(model);
        }

        var result = await _categoryService.CreateCategoryAsync(model);

        if (result == null)
        {
            ModelState.AddModelError(string.Empty, "Kategori oluşturulurken bir hata oluştu");
            var categories = await _categoryService.GetMyCategoriesAsync();
            ViewBag.Categories = categories ?? new();
            return View(model);
        }

        TempData["SuccessMessage"] = "Kategori başarıyla oluşturuldu";
        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// Kategori düzenleme sayfasını göster
    /// </summary>
    /// <param name="id">Kategori ID</param>
    /// <returns>Kategori düzenleme sayfası veya 404</returns>
    [HttpGet]
    public async Task<IActionResult> Edit(Guid id)
    {
        var category = await _categoryService.GetCategoryByIdAsync(id);
        
        if (category == null)
        {
            return NotFound();
        }

        // Standart kategorileri düzenleyemez (admin hariç)
        if (category.MerchantId == null && !IsAdminUser())
        {
            TempData["ErrorMessage"] = "Standart kategoriler düzenlenemez";
            return RedirectToAction(nameof(Index));
        }

        var categories = await _categoryService.GetMyCategoriesAsync();
        // Exclude current category and its descendants to prevent circular reference
        ViewBag.Categories = categories?.Where(c => c.Id != id).ToList() ?? new();

        var model = new UpdateCategoryRequest
        {
            ParentCategoryId = category.ParentCategoryId,
            Name = category.Name,
            Description = category.Description,
            ImageUrl = category.ImageUrl,
            DisplayOrder = category.DisplayOrder,
            IsActive = category.IsActive
        };

        return View(model);
    }

    /// <summary>
    /// Kategoriyi güncelle
    /// </summary>
    /// <param name="id">Kategori ID</param>
    /// <param name="model">Güncellenecek bilgiler</param>
    /// <returns>Kategori düzenleme sayfası veya listeye yönlendirme</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(Guid id, UpdateCategoryRequest model)
    {
        if (!ModelState.IsValid)
        {
            var categories = await _categoryService.GetMyCategoriesAsync();
            ViewBag.Categories = categories?.Where(c => c.Id != id).ToList() ?? new();
            return View(model);
        }

        var result = await _categoryService.UpdateCategoryAsync(id, model);

        if (result == null)
        {
            ModelState.AddModelError(string.Empty, "Kategori güncellenirken bir hata oluştu");
            var categories = await _categoryService.GetMyCategoriesAsync();
            ViewBag.Categories = categories?.Where(c => c.Id != id).ToList() ?? new();
            return View(model);
        }

        TempData["SuccessMessage"] = "Kategori başarıyla güncellendi";
        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// Kategoriyi sil
    /// </summary>
    /// <param name="id">Kategori ID</param>
    /// <returns>Kategori listesine yönlendirme</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(Guid id)
    {
        var category = await _categoryService.GetCategoryByIdAsync(id);
        
        if (category == null)
        {
            TempData["ErrorMessage"] = "Kategori bulunamadı";
            return RedirectToAction(nameof(Index));
        }

        // Standart kategorileri silemez (admin hariç)
        if (category.MerchantId == null && !IsAdminUser())
        {
            TempData["ErrorMessage"] = "Standart kategoriler silinemez";
            return RedirectToAction(nameof(Index));
        }

        var result = await _categoryService.DeleteCategoryAsync(id);

        if (result)
        {
            TempData["SuccessMessage"] = "Kategori başarıyla silindi";
        }
        else
        {
            TempData["ErrorMessage"] = "Kategori silinirken bir hata oluştu. Bu kategoriye bağlı ürünler olabilir.";
        }

        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// Kullanıcının admin olup olmadığını kontrol et
    /// </summary>
    /// <returns>Admin durumu</returns>
    private bool IsAdminUser()
    {
        var userRole = HttpContext.Session.GetString("UserRole");
        return userRole == "Admin";
    }

    /// <summary>
    /// Kategori sıralamasını güncelle
    /// </summary>
    /// <param name="updates">Sıralama bilgileri</param>
    /// <returns>JSON sonuç</returns>
    [HttpPost]
    public async Task<IActionResult> UpdateOrder([FromBody] List<CategoryOrderUpdate> updates)
    {
        try
        {
            if (updates == null || !updates.Any())
            {
                return Json(new { success = false, message = "Güncelleme verisi bulunamadı" });
            }

            // Her kategori için DisplayOrder'ı güncelle
            foreach (var update in updates)
            {
                var updateRequest = new UpdateCategoryRequest
                {
                    Name = string.Empty, // Bu değerler güncellenmeyecek, sadece order
                    DisplayOrder = update.DisplayOrder
                };

                var category = await _categoryService.GetCategoryByIdAsync(update.CategoryId);
                if (category != null)
                {
                    // Mevcut değerleri koru, sadece DisplayOrder değiştir
                    updateRequest.Name = category.Name;
                    updateRequest.Description = category.Description;
                    updateRequest.ParentCategoryId = update.ParentCategoryId;
                    updateRequest.IsActive = category.IsActive;
                    updateRequest.ImageUrl = category.ImageUrl;

                    await _categoryService.UpdateCategoryAsync(update.CategoryId, updateRequest);
                }
            }

            return Json(new { success = true, message = "Sıralama başarıyla güncellendi" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating category order");
            return Json(new { success = false, message = "Sıralama güncellenirken hata oluştu: " + ex.Message });
        }
    }
}

public class CategoryOrderUpdate
{
    public Guid CategoryId { get; set; }
    public Guid? ParentCategoryId { get; set; }
    public int DisplayOrder { get; set; }
}

