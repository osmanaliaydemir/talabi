using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using PortalServices = Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

[Authorize(Roles = "Admin")]
public class WithdrawalRequestsController(
    IWalletService walletService,
    PortalServices.ILocalizationService localizationService,
    IUserContextService userContextService) : Controller
{
    public async Task<IActionResult> Index(WithdrawalStatus? status)
    {
        var requests = await walletService.GetWithdrawalRequestsAsync(status: status);
        return View(requests);
    }

    [HttpPost]
    public async Task<IActionResult> Approve(Guid id, string? adminNote)
    {
        var adminId = userContextService.GetUserId();
        if (string.IsNullOrEmpty(adminId)) return RedirectToAction("Login", "Auth");

        try
        {
            await walletService.UpdateWithdrawalStatusAsync(id, WithdrawalStatus.Approved, adminId, adminNote);
            TempData["SuccessMessage"] = localizationService.GetString("WithdrawalApproved");
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> Reject(Guid id, string adminNote)
    {
        if (string.IsNullOrEmpty(adminNote))
        {
            TempData["ErrorMessage"] = localizationService.GetString("ReasonRequired");
            return RedirectToAction(nameof(Index));
        }

        var adminId = userContextService.GetUserId();
        if (string.IsNullOrEmpty(adminId)) return RedirectToAction("Login", "Auth");

        try
        {
            await walletService.UpdateWithdrawalStatusAsync(id, WithdrawalStatus.Rejected, adminId, adminNote);
            TempData["SuccessMessage"] = localizationService.GetString("WithdrawalRejected");
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> Complete(Guid id, string? adminNote)
    {
        var adminId = userContextService.GetUserId();
        if (string.IsNullOrEmpty(adminId)) return RedirectToAction("Login", "Auth");

        try
        {
            await walletService.UpdateWithdrawalStatusAsync(id, WithdrawalStatus.Completed, adminId, adminNote);
            TempData["SuccessMessage"] = localizationService.GetString("WithdrawalCompleted");
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }
}
