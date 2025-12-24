using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Portal.Models;
using Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

[Authorize]
public class ProductsController : Controller
{
    private readonly IProductService _productService;
    private readonly ILocalizationService _localizationService;
    private readonly ILogger<ProductsController> _logger;

    public ProductsController(
        IProductService productService, 
        ILocalizationService localizationService,
        ILogger<ProductsController> logger)
    {
        _productService = productService;
        _localizationService = localizationService;
        _logger = logger;
    }

    public IActionResult Index()
    {
        return View();
    }

    [HttpGet]
    public async Task<IActionResult> GetList(int start = 0, int length = 10, int draw = 1)
    {
        try
        {
            // DataTable parameters
            var searchValue = Request.Query["search[value]"].FirstOrDefault();
            var sortColumnIndex = Request.Query["order[0][column]"].FirstOrDefault();
            var sortDirection = Request.Query["order[0][dir]"].FirstOrDefault() ?? "asc";
            var categoryFilter = Request.Query["category"].FirstOrDefault();
            var statusFilter = Request.Query["status"].FirstOrDefault();

            // Map sort column
            string? sortBy = null;
            if (sortColumnIndex != null && int.TryParse(sortColumnIndex, out int colIndex))
            {
                var columnName = Request.Query[$"columns[{colIndex}][data]"].FirstOrDefault();
                if (!string.IsNullOrEmpty(columnName))
                {
                    // Map js column names to valid API sort fields if needed, 
                    // assuming JS uses same names as DTO properties (lowercase first char usually in JS)
                    sortBy = columnName switch
                    {
                        "name" => "Name",
                        "price" => "Price",
                        "stock" => "Stock",
                        "category" => "Category",
                        "isAvailable" => "IsAvailable",
                        _ => null
                    };
                }
            }

            int page = (start / length) + 1;
            bool? isAvailable = null;
            if (!string.IsNullOrEmpty(statusFilter))
            {
                if (statusFilter == "active") isAvailable = true;
                else if (statusFilter == "inactive") isAvailable = false;
            }

            var result = await _productService.GetProductsAsync(page, length, categoryFilter, isAvailable, searchValue, sortBy, sortDirection);

            if (result == null)
            {
                 return Json(new 
                 { 
                     draw = draw, 
                     recordsTotal = 0, 
                     recordsFiltered = 0, 
                     data = Array.Empty<object>() 
                 });
            }

            return Json(new
            {
                draw = draw,
                recordsTotal = result.TotalCount,
                recordsFiltered = result.TotalCount, // API returns total filtered count in TotalCount usually
                data = result.Items
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching product list");
            return Json(new { draw = draw, recordsTotal = 0, recordsFiltered = 0, error = "Error loading data" });
        }
    }

    [HttpGet]
    public async Task<IActionResult> Get(Guid id)
    {
        var product = await _productService.GetProductAsync(id);
        if (product == null) return NotFound();
        return Json(product);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateProductDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var success = await _productService.CreateProductAsync(dto);
        if (success)
            return Json(new { success = true });
        
        return Json(new { success = false, message = "Ürün oluşturulamadı." });
    }

    [HttpPost]
    public async Task<IActionResult> Update([FromBody] UpdateProductDto dto)
    {
        // For update, we might need ID in URL or Body. DTO acts as Body usually. 
        // But usually Update needs ID. I'll read ID from Query or DTO wrapper?
        // Wait, standard Update is typically PUT with ID.
        // But for AJAX form post, passing ID inside DTO or separate arg is fine.
        // Let's assume the JS sends ID in the URL for the Put request proxy, OR I use Route.
        // Let's use Route for ID or expect it in DTO? 
        // UpdateProductEndpoint is `api/vendor/products/{id}`
        // JS will call `Products/Update?id=...` or I can make a wrapper.
        // Let's make: Products/Update/{id}
        return BadRequest("Use Update/{id}");
    }
    
    [HttpPut] // Using PUT to match semantic
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateProductDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var success = await _productService.UpdateProductAsync(id, dto);
        if (success)
            return Json(new { success = true });

        return Json(new { success = false, message = "Ürün güncellenemedi." });
    }

    [HttpPost] // Using POST for delete if JS library prefers, or DELETE
    public async Task<IActionResult> Delete(Guid id)
    {
        var success = await _productService.DeleteProductAsync(id);
        if (success)
            return Json(new { success = true });

        return Json(new { success = false, message = "Ürün silinemedi." });
    }

    [HttpPost]
    public async Task<IActionResult> ToggleStatus(Guid id, bool isAvailable)
    {
        var success = await _productService.UpdateAvailabilityAsync(id, isAvailable);
        if (success)
            return Json(new { success = true });

        return Json(new { success = false, message = "Durum güncellenemedi." });
    }

    [HttpGet]
    public async Task<IActionResult> GetCategories()
    {
        var categories = await _productService.GetCategoriesAsync();
        return Json(categories);
    }
}
