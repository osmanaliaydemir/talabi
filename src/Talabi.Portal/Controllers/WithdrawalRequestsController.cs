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
    IUserContextService userContextService,
    INotificationService notificationService)
    : Controller
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
            var request = await walletService.GetWithdrawalRequestByIdAsync(id);
            if (request is null)
            {
                TempData["ErrorMessage"] = localizationService.GetString("RequestNotFound");
                return RedirectToAction(nameof(Index));
            }

            await walletService.UpdateWithdrawalStatusAsync(id, WithdrawalStatus.Approved, adminId, adminNote);

            // Send notification to user
            try
            {
                await notificationService.SendNotificationAsync(
                    request.AppUserId,
                    localizationService.GetString("WithdrawalRequestApprovedTitle"),
                    string.Format(localizationService.GetString("WithdrawalRequestApprovedMessage"),
                        request.Amount.ToString("C2")),
                    new { type = "withdrawal_approved", id, amount = request.Amount }
                );
            }
            catch (Exception ex)
            {
                // Log notification error but don't fail the request
                Console.WriteLine($"Notification error: {ex.Message}");
            }

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
            var request = await walletService.GetWithdrawalRequestByIdAsync(id);
            if (request is null)
            {
                TempData["ErrorMessage"] = localizationService.GetString("RequestNotFound");
                return RedirectToAction(nameof(Index));
            }

            await walletService.UpdateWithdrawalStatusAsync(id, WithdrawalStatus.Rejected, adminId, adminNote);

            // Send notification to user
            try
            {
                await notificationService.SendNotificationAsync(
                    request.AppUserId,
                    localizationService.GetString("WithdrawalRequestRejectedTitle"),
                    string.Format(localizationService.GetString("WithdrawalRequestRejectedMessage"), adminNote),
                    new { type = "withdrawal_rejected", id, reason = adminNote }
                );
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Notification error: {ex.Message}");
            }

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
            var request = await walletService.GetWithdrawalRequestByIdAsync(id);
            if (request is null)
            {
                TempData["ErrorMessage"] = localizationService.GetString("RequestNotFound");
                return RedirectToAction(nameof(Index));
            }

            await walletService.UpdateWithdrawalStatusAsync(id, WithdrawalStatus.Completed, adminId, adminNote);

            // Send notification to user
            try
            {
                await notificationService.SendNotificationAsync(
                    request.AppUserId,
                    localizationService.GetString("WithdrawalTransferCompletedTitle"),
                    string.Format(localizationService.GetString("WithdrawalTransferCompletedMessage"),
                        request.Amount.ToString("C2")),
                    new { type = "withdrawal_completed", id, amount = request.Amount }
                );
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Notification error: {ex.Message}");
            }

            TempData["SuccessMessage"] = localizationService.GetString("WithdrawalCompleted");
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }
}
