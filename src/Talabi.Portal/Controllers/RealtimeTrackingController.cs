using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Talabi.Portal.Controllers;

[Authorize]
public class RealtimeTrackingController : Controller
{
    private readonly ILogger<RealtimeTrackingController> _logger;

    public RealtimeTrackingController(ILogger<RealtimeTrackingController> logger)
    {
        _logger = logger;
    }

    public IActionResult Index()
    {
        return View();
    }
}
