using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Talabi.Portal.Controllers;

[Authorize]
public class ReportsController : Controller
{
    private readonly ILogger<ReportsController> _logger;

    public ReportsController(ILogger<ReportsController> logger)
    {
        _logger = logger;
    }

    public IActionResult Index()
    {
        return View();
    }
}
