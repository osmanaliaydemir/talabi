using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Core.DTOs;
using Talabi.Portal.Models;
using PortalServices = Talabi.Portal.Services;

namespace Talabi.Portal.Controllers;

[Authorize]
public class PaymentsController(
    IWalletService walletService,
    IUserContextService userContextService,
    PortalServices.ILocalizationService localizationService)
    : Controller
{
    [HttpGet]
    public async Task<IActionResult> Index(DateTime? startDate, DateTime? endDate)
    {
        var userId = userContextService.GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return RedirectToAction("Login", "Auth");
        }

        var wallet = await walletService.GetWalletByUserIdAsync(userId);
        var transactions = await walletService.GetTransactionsAsync(userId, 1, 500); // Get recent transactions

        // Filter valid dates
        if (startDate.HasValue)
            transactions = transactions.Where(t => t.TransactionDate.Date >= startDate.Value.Date).ToList();

        if (endDate.HasValue)
            transactions = transactions.Where(t => t.TransactionDate.Date <= endDate.Value.Date).ToList();

        // Calculate periodic earnings from 'Earning' type transactions
        var today = DateTime.UtcNow.Date;
        var startOfWeek = today.AddDays(-(int)today.DayOfWeek + (int)DayOfWeek.Monday);
        var startOfMonth = new DateTime(today.Year, today.Month, 1);

        var earningTransactions = transactions.Where(t => t.TransactionType == TransactionType.Earning).ToList();

        decimal dailyEarnings = earningTransactions.Where(t => t.TransactionDate.Date == today).Sum(t => t.Amount);
        decimal weeklyEarnings =
            earningTransactions.Where(t => t.TransactionDate.Date >= startOfWeek).Sum(t => t.Amount);
        decimal monthlyEarnings =
            earningTransactions.Where(t => t.TransactionDate.Date >= startOfMonth).Sum(t => t.Amount);

        // Map transactions to DTO for view compatibility
        var transactionDtos = transactions.Select(t => new OrderDto
        {
            // We reuse OrderDto for list display for now to match View expecting 'Transactions' list
            // Ideally create a WalletTransactionDto
            CustomerOrderId = t.ReferenceId ?? "-",
            CreatedAt = t.TransactionDate,
            TotalAmount = t.Amount,
            Status = t.TransactionType.ToString() // Use Status field for TransactionType
        }).ToList();

        var viewModel = new PaymentsViewModel
        {
            TotalEarnings =
                wallet.Balance, // Show Current Balance as 'Total Earnings' card for now, or fetch total lifetime earnings
            DailyEarnings = dailyEarnings,
            WeeklyEarnings = weeklyEarnings,
            MonthlyEarnings = monthlyEarnings,
            Transactions = transactionDtos,
            BankAccounts = await walletService.GetBankAccountsAsync(userId),
            WithdrawalRequests = await walletService.GetWithdrawalRequestsAsync(userId)
        };

        // viewModel.TotalEarnings = lifetimeEarnings; 

        // Let's stick to Balance for the main card as it's more useful for a 'Wallet' concept.
        // But the View Label says "Total Earnings". We might want to pass Balance separately.
        // For now, let's map Balance to TotalEarnings property or update ViewModel.

        return View(viewModel);
    }

    [HttpPost]
    public async Task<IActionResult> Deposit(decimal amount)
    {
        var userId = userContextService.GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return RedirectToAction("Login", "Auth");
        }

        if (amount <= 0)
        {
            TempData["Error"] = localizationService.GetString("InvalidAmount");
            return RedirectToAction(nameof(Index));
        }

        // Mock Payment Gateway integration here
        // For now, we simulate a successful payment
        await walletService.DepositAsync(userId, amount, "Kredi Kartı ile Yükleme",
            "REF-" + Guid.NewGuid().ToString().Substring(0, 8));

        TempData["Success"] = localizationService.GetString("DepositSuccessful");
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> Withdraw(decimal amount, string iban, string accountName)
    {
        var userId = userContextService.GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return RedirectToAction("Login", "Auth");
        }

        if (amount <= 0)
        {
            TempData["Error"] = localizationService.GetString("InvalidAmount");
            return RedirectToAction(nameof(Index));
        }

        try
        {
            await walletService.CreateWithdrawalRequestAsync(userId, amount, iban, accountName,
                "Portal üzerinden talep edildi.");
            TempData["Success"] = localizationService.GetString("WithdrawRequestCreated");
        }
        catch (InvalidOperationException)
        {
            TempData["Error"] = localizationService.GetString("InsufficientBalance");
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpGet]
    public async Task<IActionResult> Export(DateTime? startDate, DateTime? endDate)
    {
        var userId = userContextService.GetUserId();
        if (string.IsNullOrEmpty(userId))
        {
            return RedirectToAction("Login", "Auth");
        }

        var transactions = await walletService.GetTransactionsAsync(userId, 1, 1000);

        if (startDate.HasValue)
            transactions = transactions.Where(t => t.TransactionDate.Date >= startDate.Value.Date).ToList();

        if (endDate.HasValue)
            transactions = transactions.Where(t => t.TransactionDate.Date <= endDate.Value.Date).ToList();

        var builder = new System.Text.StringBuilder();
        // Add header
        builder.AppendLine("Referans No;Tarih;Tutar;Islem Tipi;Aciklama");

        foreach (var t in transactions)
        {
            builder.AppendLine(
                $"{t.ReferenceId};{t.TransactionDate:yyyy-MM-dd HH:mm};{t.Amount:F2};{t.TransactionType};{t.Description}");
        }

        // Return as CSV file with UTF8 BOM for Excel compatibility
        var bytes = System.Text.Encoding.UTF8.GetPreamble()
            .Concat(System.Text.Encoding.UTF8.GetBytes(builder.ToString())).ToArray();
        return File(bytes, "text/csv", $"cuzdan_hareketleri_{DateTime.Now:yyyyMMdd}.csv");
    }

    [HttpPost]
    public async Task<IActionResult> AddBankAccount(CreateBankAccountRequest request)
    {
        var userId = userContextService.GetUserId();
        if (string.IsNullOrEmpty(userId)) return RedirectToAction("Login", "Auth");

        if (string.IsNullOrEmpty(request.AccountName) || string.IsNullOrEmpty(request.Iban))
        {
            TempData["Error"] = localizationService.GetString("AllFieldsRequired");
            return RedirectToAction(nameof(Index));
        }

        try
        {
            await walletService.AddBankAccountAsync(userId, request);
            TempData["Success"] = localizationService.GetString("BankAccountAdded");
        }
        catch (Exception)
        {
            TempData["Error"] = localizationService.GetString("ErrorAddingBankAccount"); // Generic error message
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> DeleteBankAccount(Guid id)
    {
        var userId = userContextService.GetUserId();
        if (string.IsNullOrEmpty(userId)) return RedirectToAction("Login", "Auth");

        try
        {
            await walletService.DeleteBankAccountAsync(userId, id);
            TempData["Success"] = localizationService.GetString("BankAccountDeleted");
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> SetDefaultBankAccount(Guid id)
    {
        var userId = userContextService.GetUserId();
        if (string.IsNullOrEmpty(userId)) return RedirectToAction("Login", "Auth");

        try
        {
            await walletService.SetDefaultBankAccountAsync(userId, id);
            TempData["Success"] = localizationService.GetString("DefaultAccountUpdated");
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }
}
