using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class OrdersController : Controller
{
    private readonly IOrderService _orderService;
    private readonly ILogger<OrdersController> _logger;

    /// <summary>
    /// OrdersController constructor
    /// </summary>
    /// <param name="orderService">Sipariş servisi</param>
    /// <param name="logger">Logger instance</param>
    public OrdersController(IOrderService orderService, ILogger<OrdersController> logger)
    {
        _orderService = orderService;
        _logger = logger;
    }

    /// <summary>
    /// Sipariş listesini göster
    /// </summary>
    /// <param name="page">Sayfa numarası</param>
    /// <param name="status">Sipariş durumu</param>
    /// <returns>Sipariş listesi sayfası</returns>
    public async Task<IActionResult> Index(int page = 1, string? status = null)
    {
        try
        {
            var orders = await _orderService.GetOrdersAsync(page, 20, status);
            ViewBag.CurrentStatus = status;
            
            if (orders == null || orders.Items == null)
            {
                orders = new PagedResult<OrderResponse>
                {
                    Items = new List<OrderResponse>(),
                    TotalCount = 0,
                    Page = page,
                    PageSize = 20,
                    TotalPages = 0
                };
            }
            
            return View(orders);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in Orders Index action");
            ViewBag.CurrentStatus = status;
            
            var emptyOrders = new PagedResult<OrderResponse>
            {
                Items = new List<OrderResponse>(),
                TotalCount = 0,
                Page = page,
                PageSize = 20,
                TotalPages = 0
            };
            
            return View(emptyOrders);
        }
    }

    /// <summary>
    /// Bekleyen siparişleri göster
    /// </summary>
    /// <param name="page">Sayfa numarası</param>
    /// <returns>Bekleyen siparişler sayfası</returns>
    public async Task<IActionResult> Pending(int page = 1)
    {
        var orders = await _orderService.GetPendingOrdersAsync(page, 20);
        
        // View'ın beklediği List<OrderResponse> tipine çevir
        var orderList = orders?.Items ?? new List<OrderResponse>();
        return View(orderList);
    }

    /// <summary>
    /// Sipariş detaylarını göster
    /// </summary>
    /// <param name="id">Sipariş ID</param>
    /// <returns>Sipariş detay sayfası veya 404</returns>
    [HttpGet]
    public async Task<IActionResult> Details(Guid id)
    {
        var order = await _orderService.GetOrderDetailsAsync(id);
        
        if (order == null)
        {
            return NotFound();
        }

        return View(order);
    }

    /// <summary>
    /// Sipariş durumunu güncelle
    /// </summary>
    /// <param name="id">Sipariş ID</param>
    /// <param name="status">Yeni durum</param>
    /// <param name="notes">Notlar</param>
    /// <returns>Sipariş detay sayfasına yönlendirme</returns>
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateStatus(Guid id, string status, string? notes = null)
    {
        var request = new UpdateOrderStatusRequest
        {
            Status = status,
            Notes = notes
        };

        var result = await _orderService.UpdateOrderStatusAsync(id, request);

        if (result)
        {
            TempData["SuccessMessage"] = "Sipariş durumu güncellendi";
        }
        else
        {
            TempData["ErrorMessage"] = "Sipariş durumu güncellenirken bir hata oluştu";
        }

        return RedirectToAction(nameof(Details), new { id });
    }
}

