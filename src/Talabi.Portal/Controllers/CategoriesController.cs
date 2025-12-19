using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Portal.Models;
using Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

[Authorize(Roles = "Admin")]
public class CategoriesController : Controller
{
    private readonly ICategoryService _categoryService;
    private readonly ILocalizationService _localizationService;
    private readonly ILogger<CategoriesController> _logger;

    public CategoriesController(
        ICategoryService categoryService,
        ILocalizationService localizationService,
        ILogger<CategoriesController> logger)
    {
        _categoryService = categoryService;
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
            var searchValue = Request.Query["search[value]"].FirstOrDefault();
            var sortColumnIndex = Request.Query["order[0][column]"].FirstOrDefault();
            var sortDirection = Request.Query["order[0][dir]"].FirstOrDefault() ?? "asc";

            string? sortBy = null;
            if (sortColumnIndex != null && int.TryParse(sortColumnIndex, out int colIndex))
            {
                var columnName = Request.Query[$"columns[{colIndex}][data]"].FirstOrDefault();
                sortBy = columnName; // "name" or "productCount"
            }

            int page = (start / length) + 1;

            var result = await _categoryService.GetCategoriesAsync(page, length, searchValue, sortBy, sortDirection);

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
                recordsFiltered = result.TotalCount,
                data = result.Items
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching category list");
            return Json(new { draw = draw, recordsTotal = 0, recordsFiltered = 0, error = "Error loading data" });
        }
    }

    [HttpPost] // or Put
    public async Task<IActionResult> Update([FromBody] UpdateCategoryDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var success = await _categoryService.UpdateCategoryAsync(dto.OldName, dto.NewName);
        if (success)
            return Json(new { success = true });

        return Json(new { success = false, message = "Kategori güncellenemedi veya bulunamadı." });
    }

    [HttpPost]
    public async Task<IActionResult> Delete(string name)
    {
        var success = await _categoryService.DeleteCategoryAsync(name);
        if (success)
            return Json(new { success = true });

        return Json(new { success = false, message = "Kategori silinemedi." });
    }
}
