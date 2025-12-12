using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize(Roles = "MerchantOwner,Admin")]
public class InventoryController : Controller
{
    private readonly IInventoryService _inventoryService;
    private readonly ILogger<InventoryController> _logger;

    public InventoryController(
        IInventoryService inventoryService,
        ILogger<InventoryController> logger)
    {
        _inventoryService = inventoryService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> Index(
        DateTime? fromDate = null,
        DateTime? toDate = null,
        int slowThreshold = 45,
        string valuationMethod = "FIFO",
        bool includeVariants = true)
    {
        var (hasMerchant, merchantId) = TryGetMerchantId();
        if (!hasMerchant)
        {
            return RedirectToAction("Login", "Auth");
        }

        var today = DateTime.UtcNow.Date;
        var defaultFrom = today.AddDays(-30);
        var filterFrom = fromDate ?? defaultFrom;
        var filterTo = toDate ?? today;

        var viewModel = new InventoryDashboardViewModel
        {
            FromDate = filterFrom,
            ToDate = filterTo,
            SlowMovingThresholdDays = slowThreshold < 1 ? 30 : slowThreshold,
            ValuationMethod = valuationMethod,
            IncludeVariants = includeVariants
        };

        try
        {
            var levelsTask = _inventoryService.GetInventoryLevelsAsync(includeVariants);
            var turnoverTask = _inventoryService.GetInventoryTurnoverAsync(filterFrom, filterTo);
            var slowMovingTask = _inventoryService.GetSlowMovingInventoryAsync(viewModel.SlowMovingThresholdDays);
            var valuationTask = _inventoryService.GetInventoryValuationAsync(viewModel.ValuationMethod);
            var countHistoryTask = _inventoryService.GetInventoryCountHistoryAsync(filterFrom, filterTo);
            var discrepancyTask = _inventoryService.GetInventoryDiscrepanciesAsync(filterFrom);

            await Task.WhenAll(levelsTask, turnoverTask, slowMovingTask, valuationTask, countHistoryTask, discrepancyTask);

            viewModel.InventoryLevels = levelsTask.Result ?? new List<InventoryLevelModel>();
            viewModel.Turnover = turnoverTask.Result;
            viewModel.SlowMovingItems = slowMovingTask.Result ?? new List<SlowMovingInventoryModel>();
            viewModel.Valuation = valuationTask.Result;
            viewModel.CountHistory = countHistoryTask.Result ?? new List<InventoryCountModel>();
            viewModel.Discrepancies = discrepancyTask.Result ?? new List<InventoryDiscrepancyModel>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error loading inventory dashboard");
            TempData["Error"] = "İnteraktif envanter verileri yüklenirken bir hata oluştu.";
        }

        return View(viewModel);
    }

    private (bool HasMerchant, Guid MerchantId) TryGetMerchantId()
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
        {
            return (false, Guid.Empty);
        }

        return (true, merchantId);
    }

}

