using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class ProductsController : Controller
{
    private readonly IProductService _productService;
    private readonly IFileService _fileService;
    private readonly ISearchService _searchService;
    private readonly ILogger<ProductsController> _logger;

    /// <summary>
    /// ProductsController constructor
    /// </summary>
    /// <param name="productService">Ürün servisi</param>
    /// <param name="logger">Logger instance</param>
    public ProductsController(IProductService productService, ISearchService searchService, IFileService fileService, ILogger<ProductsController> logger)
    {
        _productService = productService;
        _searchService = searchService;
        _fileService = fileService;
        _logger = logger;
    }

    /// <summary>
    /// Ürün listesini göster
    /// </summary>
    /// <param name="page">Sayfa numarası</param>
    /// <returns>Ürün listesi sayfası</returns>
    public async Task<IActionResult> Index(int page = 1, string? q = null, Guid? categoryId = null)
    {
        var useSearch = !string.IsNullOrWhiteSpace(q) || categoryId.HasValue;
        var products = useSearch
            ? await _searchService.SearchProductsAsync(q, categoryId, page, 20)
            : await _productService.GetProductsAsync(page, 20);

        var categories = await _productService.GetCategoriesAsync();

        ViewBag.Categories = categories ?? new();
        ViewBag.Query = q;
        ViewBag.CategoryId = categoryId;
        
        return View(products);
    }

    /// <summary>
    /// Yeni ürün oluşturma sayfasını göster
    /// </summary>
    /// <returns>Ürün oluşturma sayfası</returns>
    [HttpGet]
    public async Task<IActionResult> Create()
    {
        var categories = await _productService.GetCategoriesAsync();
        ViewBag.Categories = categories ?? new();
        
        return View();
    }

    /// <summary>
    /// Yeni ürün oluştur
    /// </summary>
    /// <param name="model">Ürün bilgileri</param>
    /// <returns>Ürün oluşturma sayfası veya listeye yönlendirme</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Create(CreateProductRequest model, IFormFile? imageFile)
    {
        if (!ModelState.IsValid)
        {
            var categories = await _productService.GetCategoriesAsync();
            ViewBag.Categories = categories ?? new();
            return View(model);
        }

        if (imageFile != null && imageFile.Length > 0)
        {
            using var stream = imageFile.OpenReadStream();
            var upload = await _fileService.UploadMerchantFileAsync(stream, imageFile.FileName, imageFile.ContentType);
            if (!string.IsNullOrWhiteSpace(upload?.BlobUrl))
            {
                model.ImageUrl = upload.BlobUrl;
            }
        }

        var result = await _productService.CreateProductAsync(model);

        if (result == null)
        {
            ModelState.AddModelError(string.Empty, "Ürün oluşturulurken bir hata oluştu");
            var categories = await _productService.GetCategoriesAsync();
            ViewBag.Categories = categories ?? new();
            return View(model);
        }

        TempData["SuccessMessage"] = "Ürün başarıyla oluşturuldu";
        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// Ürün düzenleme sayfasını göster
    /// </summary>
    /// <param name="id">Ürün ID</param>
    /// <returns>Ürün düzenleme sayfası veya 404</returns>
    [HttpGet]
    public async Task<IActionResult> Edit(Guid id)
    {
        var product = await _productService.GetProductByIdAsync(id);
        
        if (product == null)
        {
            return NotFound();
        }

        var categories = await _productService.GetCategoriesAsync();
        ViewBag.Categories = categories ?? new();

        var model = new UpdateProductRequest
        {
            ProductCategoryId = product.ProductCategoryId,
            Name = product.Name,
            Description = product.Description,
            ImageUrl = product.ImageUrl,
            Price = product.Price,
            DiscountedPrice = product.DiscountedPrice,
            StockQuantity = product.StockQuantity,
            Unit = product.Unit,
            IsAvailable = product.IsAvailable,
            IsActive = product.IsActive,
            DisplayOrder = product.DisplayOrder
        };

        return View(model);
    }

    /// <summary>
    /// Ürünü güncelle
    /// </summary>
    /// <param name="id">Ürün ID</param>
    /// <param name="model">Güncellenecek bilgiler</param>
    /// <returns>Ürün düzenleme sayfası veya listeye yönlendirme</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Edit(Guid id, UpdateProductRequest model, IFormFile? imageFile)
    {
        if (!ModelState.IsValid)
        {
            var categories = await _productService.GetCategoriesAsync();
            ViewBag.Categories = categories ?? new();
            return View(model);
        }

        if (imageFile != null && imageFile.Length > 0)
        {
            using var stream = imageFile.OpenReadStream();
            var upload = await _fileService.UploadMerchantFileAsync(stream, imageFile.FileName, imageFile.ContentType);
            if (!string.IsNullOrWhiteSpace(upload?.BlobUrl))
            {
                model.ImageUrl = upload.BlobUrl;
            }
        }

        var result = await _productService.UpdateProductAsync(id, model);

        if (result == null)
        {
            ModelState.AddModelError(string.Empty, "Ürün güncellenirken bir hata oluştu");
            var categories = await _productService.GetCategoriesAsync();
            ViewBag.Categories = categories ?? new();
            return View(model);
        }

        TempData["SuccessMessage"] = "Ürün başarıyla güncellendi";
        return RedirectToAction(nameof(Index));
    }

    /// <summary>
    /// Ürünü sil
    /// </summary>
    /// <param name="id">Ürün ID</param>
    /// <returns>Ürün listesine yönlendirme</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(Guid id)
    {
        var result = await _productService.DeleteProductAsync(id);

        if (result)
        {
            TempData["SuccessMessage"] = "Ürün başarıyla silindi";
        }
        else
        {
            TempData["ErrorMessage"] = "Ürün silinirken bir hata oluştu";
        }

        return RedirectToAction(nameof(Index));
    }
}

