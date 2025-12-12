using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;

    /// <summary>
    /// HomeController constructor
    /// </summary>
    /// <param name="logger">Logger instance</param>
    public HomeController(ILogger<HomeController> logger)
    {
        _logger = logger;
    }

    /// <summary>
    /// Ana sayfayı göster
    /// </summary>
    /// <returns>Ana sayfa</returns>
    public IActionResult Index()
    {
        return View();
    }

    /// <summary>
    /// Gizlilik politikası sayfasını göster
    /// </summary>
    /// <returns>Gizlilik politikası sayfası</returns>
    public IActionResult Privacy()
    {
        return View();
    }

    /// <summary>
    /// Hata sayfasını göster
    /// </summary>
    /// <returns>Hata sayfası</returns>
    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
