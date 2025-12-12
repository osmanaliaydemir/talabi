using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Talabi.Portal.Models;
using Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

public class AuthController : Controller
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    [HttpGet]
    public IActionResult Login(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true)
        {
            return RedirectToAction("Index", "Home");
        }

        ViewData["ReturnUrl"] = returnUrl;
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginRequest request, string? returnUrl = null)
    {
        if (!ModelState.IsValid)
        {
            return View(request);
        }

        var response = await _authService.LoginAsync(request);

        if (response != null)
        {
            // Identity SignInManager has already signed the user in with default claims.
            // We can add extra things to session if needed.

            HttpContext.Session.SetString("UserId", response.UserId.ToString());
            if (response.VendorId.HasValue)
            {
                HttpContext.Session.SetString("VendorId", response.VendorId.Value.ToString());
            }

            _logger.LogInformation("User {Email} logged in successfully via Identity.", response.Email);

            if (!string.IsNullOrEmpty(returnUrl) && Url.IsLocalUrl(returnUrl))
            {
                return Redirect(returnUrl);
            }

            return RedirectToAction("Index", "Home");
        }

        ModelState.AddModelError(string.Empty, "Giriş başarısız. Lütfen bilgilerinizi kontrol edin.");
        return View(request);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Logout()
    {
        await _authService.LogoutAsync();

        // Clear session
        HttpContext.Session.Clear();

        _logger.LogInformation("User logged out.");

        return RedirectToAction("Login");
    }
}
