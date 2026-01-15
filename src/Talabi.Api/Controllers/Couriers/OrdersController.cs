using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using AutoMapper;

namespace Talabi.Api.Controllers.Couriers;

/// <summary>
/// Courier Dashboard - Sipariş yönetimi için controller
/// </summary>
[Route("api/couriers/dashboard/orders")]
[ApiController]
[Authorize(Roles = "Courier")]
public class OrdersController : BaseController
{
    private readonly IMapper _mapper;
    private readonly IOrderAssignmentService _assignmentService;
    private readonly IRepository<SystemSetting> _systemSettingRepository;
    private readonly IRepository<WalletTransaction> _walletTransactionRepository;
    private const string ResourceName = "CourierResources";

    /// <summary>
    /// OrdersController constructor
    /// </summary>
    public OrdersController(
        IUnitOfWork unitOfWork,
        ILogger<OrdersController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        IMapper mapper,
        IOrderAssignmentService assignmentService,
        IRepository<SystemSetting> systemSettingRepository,
        IRepository<WalletTransaction> walletTransactionRepository)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _mapper = mapper;
        _assignmentService = assignmentService;
        _systemSettingRepository = systemSettingRepository;
        _walletTransactionRepository = walletTransactionRepository;
    }

    private async Task<Courier?> GetCurrentCourierAsync()
    {
        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return null;
        }

        var courier = await UnitOfWork.Couriers.Query()
            .FirstOrDefaultAsync(c => c.UserId == userId);
        return courier;
    }

    /// <summary>
    /// Helper to enrich orders with payment info and multi-currency data
    /// </summary>
    private async Task EnrichOrderWithPaymentInfo(List<CourierOrderDto> dtos)
    {
        if (dtos == null || !dtos.Any()) return;

        // 1. Fetch System Settings for Exchange Rates
        decimal rateTl = 450;
        decimal rateUsd = 15000;

        var settings = await _systemSettingRepository.Query()
            .Where(s => s.Key == "ExchangeRate_TL" || s.Key == "ExchangeRate_USD")
            .ToListAsync();

        var setTl = settings.FirstOrDefault(s => s.Key == "ExchangeRate_TL");
        if (setTl != null && decimal.TryParse(setTl.Value, out var parsedTl)) rateTl = parsedTl;

        var setUsd = settings.FirstOrDefault(s => s.Key == "ExchangeRate_USD");
        if (setUsd != null && decimal.TryParse(setUsd.Value, out var parsedUsd)) rateUsd = parsedUsd;

        // 2. Identify Payment Method (Cash vs Online)
        // If there is a WalletTransaction of type Payment for this order, it's Online. Otherwise Cash.
        var orderIds = dtos.Select(d => d.Id.ToString()).ToList();
        var paymentTransactions = await _walletTransactionRepository.Query()
            .Where(t => orderIds.Contains(t.ReferenceId) && t.TransactionType == TransactionType.Payment)
            .Select(t => t.ReferenceId)
            .ToListAsync();

        foreach (var dto in dtos)
        {
            // Determine Payment Method
            bool isOnline = paymentTransactions.Contains(dto.Id.ToString());
            dto.PaymentMethod = isOnline ? "Online" : "Cash";

            // Calculate Multi-Currency if Cash
            if (dto.PaymentMethod == "Cash")
            {
                // Logic: Description says "1 TL'nin SYP karşılığı" (e.g. 450). 
                // So 1 TL = 450 SYP -> AmountTL = TotalAmount / 450? 
                // Wait. If 1 USD = 15000 SYP. 150 USD * 15000 = X SYP.
                // Usually ExchangeRate is "How many BaseUnits is 1 ForeignUnit".
                // Base is SYP. Foreign is USD.
                // So AmountForeign = AmountBase / Rate.

                if (rateTl > 0)
                {
                    dto.TotalAmountTl = Math.Round(dto.TotalAmount / rateTl, 2);
                    dto.ExchangeRateTl = rateTl;
                }

                if (rateUsd > 0)
                {
                    dto.TotalAmountUsd = Math.Round(dto.TotalAmount / rateUsd, 2);
                    dto.ExchangeRateUsd = rateUsd;
                }
            }
        }
    }

    /// <summary>
    /// Kuryenin aktif siparişlerini getirir
    /// </summary>
    /// <returns>Aktif sipariş listesi</returns>
    [HttpGet("active")]
    public async Task<ActionResult<ApiResponse<List<CourierOrderDto>>>> GetActiveOrders()
    {
        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<List<CourierOrderDto>>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        var courierId = courier.Id;

        var orders = await _assignmentService.GetActiveOrdersForCourierAsync(courierId);

        var orderDtos = orders.Select(o =>
        {
            var orderCourier = o.OrderCouriers
                .Where(oc => oc.CourierId == courierId && oc.IsActive)
                .FirstOrDefault();

            var dto = _mapper.Map<CourierOrderDto>(o);

            // OrderCourier bilgilerini ekle
            if (orderCourier != null)
            {
                dto.DeliveryFee = orderCourier.DeliveryFee;
                dto.CourierStatus = orderCourier.Status;
                dto.CourierAssignedAt = orderCourier.CourierAssignedAt;
                dto.CourierAcceptedAt = orderCourier.CourierAcceptedAt;
                dto.CourierRejectedAt = orderCourier.CourierRejectedAt;
                dto.RejectReason = orderCourier.RejectReason;
                dto.PickedUpAt = orderCourier.PickedUpAt;
                dto.OutForDeliveryAt = orderCourier.OutForDeliveryAt;
                dto.DeliveredAt = orderCourier.DeliveredAt;
                dto.CourierTip = orderCourier.CourierTip;
            }

            return dto;
        }).ToList();

        // Enrich with Payment Info & Multi-Currency
        await EnrichOrderWithPaymentInfo(orderDtos);

        return Ok(new ApiResponse<List<CourierOrderDto>>(orderDtos,
            LocalizationService.GetLocalizedString(ResourceName, "ActiveOrdersRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kuryenin sipariş geçmişini getirir
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 20)</param>
    /// <returns>Sayfalanmış sipariş geçmişi</returns>
    [HttpGet("history")]
    public async Task<ActionResult<ApiResponse<object>>> GetOrderHistory([FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        // Get orders through OrderCouriers
        var orderCouriers = await UnitOfWork.OrderCouriers.Query()
            .Include(oc => oc.Order)
            .ThenInclude(o => o!.Vendor)
            .Include(oc => oc.Order)
            .ThenInclude(o => o!.Customer)
            .Include(oc => oc.Order)
            .ThenInclude(o => o!.DeliveryAddress)
            .Include(oc => oc.Order)
            .ThenInclude(o => o!.OrderItems)
            .ThenInclude(oi => oi.Product)
            .Where(oc => oc.CourierId == courier.Id
                         && oc.Order != null
                         && oc.Order.Status == OrderStatus.Delivered
                         && oc.DeliveredAt.HasValue)
            .OrderByDescending(oc => oc.DeliveredAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        var totalCount = await UnitOfWork.OrderCouriers.Query()
            .CountAsync(oc => oc.CourierId == courier.Id
                              && oc.Order != null
                              && oc.Order.Status == OrderStatus.Delivered
                              && oc.DeliveredAt.HasValue);

        var orderDtos =
            _mapper.Map<List<CourierOrderDto>>(orderCouriers.Select(oc => oc.Order).Where(o => o != null).ToList()!);

        // Enrich with Payment Info & Multi-Currency
        await EnrichOrderWithPaymentInfo(orderDtos);

        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
        var result = new
        {
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = totalPages,
            HasNextPage = page < totalPages,
            HasPreviousPage = page > 1,
            items = orderDtos
        };

        return Ok(new ApiResponse<object>(result,
            LocalizationService.GetLocalizedString(ResourceName, "OrderHistoryRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Belirli bir siparişin detaylarını getirir
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>Sipariş detayları</returns>
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<CourierOrderDto>>> GetOrderDetail(Guid id)
    {
        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<CourierOrderDto>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        var courierId = courier.Id;

        // First try to get order if it's currently assigned to this courier
        var order = await UnitOfWork.Orders.Query()
            .Include(o => o.Vendor)
            .Include(o => o.Customer)
            .Include(o => o.DeliveryAddress)
            .Include(o => o.OrderItems)
            .ThenInclude(oi => oi.Product)
            .Include(o => o.DeliveryProof)
            .Include(o => o.OrderCouriers)
            .FirstOrDefaultAsync(o =>
                o.Id == id && o.OrderCouriers.Any(oc => oc.CourierId == courierId && oc.IsActive));

        // If not found, check if this courier has a notification for this order
        if (order == null)
        {
            var hasNotification = await UnitOfWork.CourierNotifications.Query()
                .AnyAsync(n => n.CourierId == courierId && n.OrderId == id);

            if (hasNotification)
            {
                // Get the order even if not currently assigned to this courier
                order = await UnitOfWork.Orders.Query()
                    .Include(o => o.Vendor)
                    .Include(o => o.Customer)
                    .Include(o => o.DeliveryAddress)
                    .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Product)
                    .Include(o => o.DeliveryProof)
                    .FirstOrDefaultAsync(o => o.Id == id);
            }
        }

        if (order == null)
        {
            return NotFound(new ApiResponse<CourierOrderDto>(
                LocalizationService.GetLocalizedString(ResourceName, "OrderNotFoundOrNotAssigned", CurrentCulture),
                "ORDER_NOT_FOUND"));
        }

        var orderCourier = order.OrderCouriers
            .Where(oc => oc.CourierId == courier.Id)
            .OrderByDescending(oc => oc.CreatedAt)
            .FirstOrDefault();

        var orderDto = _mapper.Map<CourierOrderDto>(order);

        // OrderCourier bilgilerini ekle
        if (orderCourier != null)
        {
            orderDto.DeliveryFee = orderCourier.DeliveryFee;
            orderDto.CourierStatus = orderCourier.Status;
            orderDto.CourierAssignedAt = orderCourier.CourierAssignedAt;
            orderDto.CourierAcceptedAt = orderCourier.CourierAcceptedAt;
            orderDto.CourierRejectedAt = orderCourier.CourierRejectedAt;
            orderDto.RejectReason = orderCourier.RejectReason;
            orderDto.PickedUpAt = orderCourier.PickedUpAt;
            orderDto.OutForDeliveryAt = orderCourier.OutForDeliveryAt;
            orderDto.DeliveredAt = orderCourier.DeliveredAt;
            orderDto.CourierTip = orderCourier.CourierTip;
        }

        // Enrich with Payment Info & Multi-Currency
        await EnrichOrderWithPaymentInfo(new List<CourierOrderDto> { orderDto });

        return Ok(new ApiResponse<CourierOrderDto>(orderDto,
            LocalizationService.GetLocalizedString(ResourceName, "OrderDetailsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Siparişi kabul eder
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{id}/accept")]
    public async Task<ActionResult<ApiResponse<object>>> AcceptOrder(Guid id)
    {
        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        var success = await _assignmentService.AcceptOrderAsync(id, courier.Id);
        if (!success)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "FailedToAcceptOrder", CurrentCulture),
                "ORDER_ACCEPT_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { },
            LocalizationService.GetLocalizedString(ResourceName, "OrderAcceptedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Siparişi reddeder
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="dto">Reddetme bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{id}/reject")]
    public async Task<ActionResult<ApiResponse<object>>> RejectOrder(
        Guid id,
        [FromBody] RejectOrderDto dto)
    {
        if (dto == null)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture),
                "INVALID_REQUEST"));
        }

        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        // Validate reject reason
        if (string.IsNullOrWhiteSpace(dto.Reason) || dto.Reason.Trim().Length < 10)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "RejectReasonMustBeAtLeast10Characters",
                    CurrentCulture),
                "INVALID_REJECT_REASON"
            ));
        }

        var success = await _assignmentService.RejectOrderAsync(id, courier.Id, dto.Reason.Trim());
        if (!success)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "FailedToRejectOrder", CurrentCulture),
                "ORDER_REJECT_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { },
            LocalizationService.GetLocalizedString(ResourceName, "OrderRejectedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Siparişi teslim alır
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{id}/pickup")]
    public async Task<ActionResult<ApiResponse<object>>> PickUpOrder(Guid id)
    {
        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        var success = await _assignmentService.PickUpOrderAsync(id, courier.Id);
        if (!success)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "FailedToPickUpOrder", CurrentCulture),
                "ORDER_PICKUP_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { },
            LocalizationService.GetLocalizedString(ResourceName, "OrderPickedUpSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Siparişi teslim eder
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{id}/deliver")]
    public async Task<ActionResult<ApiResponse<object>>> DeliverOrder(Guid id)
    {
        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        var success = await _assignmentService.DeliverOrderAsync(id, courier.Id);
        if (!success)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "FailedToDeliverOrder", CurrentCulture),
                "ORDER_DELIVER_FAILED"));
        }

        return Ok(new ApiResponse<object>(new { },
            LocalizationService.GetLocalizedString(ResourceName, "OrderDeliveredSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Teslimat kanıtı gönderir
    /// </summary>
    /// <param name="id">Sipariş ID'si</param>
    /// <param name="dto">Teslimat kanıtı bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{id}/proof")]
    public async Task<ActionResult<ApiResponse<object>>> SubmitDeliveryProof(Guid id,
        [FromBody] SubmitDeliveryProofDto dto)
    {
        if (dto == null)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture),
                "INVALID_REQUEST"));
        }

        var courier = await GetCurrentCourierAsync();
        if (courier == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CourierProfileNotFound", CurrentCulture),
                "COURIER_PROFILE_NOT_FOUND"));
        }

        var courierId = courier.Id;

        var order = await UnitOfWork.Orders.Query()
            .Include(o => o.DeliveryProof)
            .Include(o => o.OrderCouriers)
            .FirstOrDefaultAsync(o =>
                o.Id == id && o.OrderCouriers.Any(oc => oc.CourierId == courierId && oc.IsActive));

        if (order == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "OrderNotFoundOrNotAssigned", CurrentCulture),
                "ORDER_NOT_FOUND"));
        }

        if (order.Status != OrderStatus.Delivered)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "OrderMustBeDeliveredBeforeSubmittingProof",
                    CurrentCulture), "ORDER_NOT_DELIVERED"));
        }

        // Create or update delivery proof
        if (order.DeliveryProof == null)
        {
            order.DeliveryProof = new DeliveryProof
            {
                OrderId = order.Id,
                PhotoUrl = dto.PhotoUrl,
                SignatureUrl = dto.SignatureUrl,
                Notes = dto.Notes,
                ProofSubmittedAt = DateTime.UtcNow
            };
            await UnitOfWork.DeliveryProofs.AddAsync(order.DeliveryProof);
        }
        else
        {
            order.DeliveryProof.PhotoUrl = dto.PhotoUrl;
            order.DeliveryProof.SignatureUrl = dto.SignatureUrl;
            order.DeliveryProof.Notes = dto.Notes;
            order.DeliveryProof.ProofSubmittedAt = DateTime.UtcNow;
            UnitOfWork.DeliveryProofs.Update(order.DeliveryProof);
        }

        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { },
            LocalizationService.GetLocalizedString(ResourceName, "DeliveryProofSubmittedSuccessfully",
                CurrentCulture)));
    }
}
