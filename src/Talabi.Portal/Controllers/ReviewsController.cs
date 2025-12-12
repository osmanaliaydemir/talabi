using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

[Authorize]
public class ReviewsController : Controller
{
    private readonly IReviewService _reviewService;
    private readonly ILocalizationService _localizationService;
    private readonly ILogger<ReviewsController> _logger;

    public ReviewsController(
        IReviewService reviewService,
        ILocalizationService localizationService,
        ILogger<ReviewsController> logger)
    {
        _reviewService = reviewService;
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
            var sortDirection = Request.Query["order[0][dir]"].FirstOrDefault() ?? "desc";
            var ratingFilter = Request.Query["rating"].FirstOrDefault();

            string? sortBy = null;
            if (sortColumnIndex != null && int.TryParse(sortColumnIndex, out int colIndex))
            {
                var columnName = Request.Query[$"columns[{colIndex}][data]"].FirstOrDefault();
                if (!string.IsNullOrEmpty(columnName))
                {
                    sortBy = columnName switch
                    {
                        "rating" => "rating",
                        "createdAt" => "date",
                        "customerName" => "customerName",
                        "productName" => "productName",
                        _ => null
                    };
                }
            }

            int page = (start / length) + 1;
            int? rating = null;
            if (!string.IsNullOrEmpty(ratingFilter) && int.TryParse(ratingFilter, out int parsedRating))
            {
                rating = parsedRating;
            }

            var result = await _reviewService.GetReviewsAsync(page, length, rating, searchValue, sortBy, sortDirection);

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
            _logger.LogError(ex, "Error fetching review list");
            return Json(new { draw = draw, recordsTotal = 0, recordsFiltered = 0, error = "Error loading data" });
        }
    }
}
