using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using AutoMapper;
using Talabi.Core.Enums;

namespace Talabi.Api.Controllers;

/// <summary>
/// Değerlendirme (review) işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class ReviewsController : BaseController
{
    private readonly UserManager<AppUser> _userManager;
    private readonly IMapper _mapper;
    private const string ResourceName = "ReviewResources";

    /// <summary>
    /// ReviewsController constructor
    /// </summary>
    public ReviewsController(
        IUnitOfWork unitOfWork,
        ILogger<ReviewsController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        UserManager<AppUser> userManager,
        IMapper mapper)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _userManager = userManager;
        _mapper = mapper;
    }

    /// <summary>
    /// Yeni değerlendirme oluşturur
    /// </summary>
    /// <param name="dto">Değerlendirme bilgileri</param>
    /// <returns>Oluşturulan değerlendirme</returns>
    [HttpPost]
    [Authorize]
    public async Task<ActionResult<ApiResponse<ReviewDto>>> CreateReview(CreateReviewDto dto)
    {

        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<ReviewDto>(
                LocalizationService.GetLocalizedString(ResourceName, "UserIdentityNotFound", CurrentCulture),
                "USER_IDENTITY_NOT_FOUND"));
        }
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
        {
            return Unauthorized(new ApiResponse<ReviewDto>(
                LocalizationService.GetLocalizedString(ResourceName, "UserNotFound", CurrentCulture),
                "USER_NOT_FOUND"));
        }

        var review = new Review
        {
            UserId = userId,
            Rating = dto.Rating,
            Comment = dto.Comment,
            CreatedAt = DateTime.UtcNow
        };

        if (dto.TargetType.Equals("Product", StringComparison.OrdinalIgnoreCase))
        {
            var product = await UnitOfWork.Products.GetByIdAsync(dto.TargetId);
            if (product == null)
            {
                return NotFound(new ApiResponse<ReviewDto>(
                    LocalizationService.GetLocalizedString(ResourceName, "ProductNotFound", CurrentCulture),
                    "PRODUCT_NOT_FOUND"));
            }

            // Kullanıcının bu ürüne daha önce review verip vermediğini kontrol et
            var existingReview = await UnitOfWork.Reviews.Query()
                .FirstOrDefaultAsync(r => r.UserId == userId && r.ProductId == dto.TargetId);

            if (existingReview != null)
            {
                return BadRequest(new ApiResponse<ReviewDto>(
                    LocalizationService.GetLocalizedString(ResourceName, "ReviewAlreadyExists", CurrentCulture),
                    "REVIEW_ALREADY_EXISTS"
                ));
            }

            review.ProductId = dto.TargetId;
            // Product review'ları vendor onayı bekler
            review.IsApproved = false;
        }
        else if (dto.TargetType.Equals("Vendor", StringComparison.OrdinalIgnoreCase))
        {
            var vendor = await UnitOfWork.Vendors.Query()
                .Include(v => v.Products)
                .FirstOrDefaultAsync(v => v.Id == dto.TargetId);
            if (vendor == null)
            {
                return NotFound(new ApiResponse<ReviewDto>(
                    LocalizationService.GetLocalizedString(ResourceName, "VendorNotFound", CurrentCulture),
                    "VENDOR_NOT_FOUND"));
            }

            // Vendor review'ı için o vendor'ın bir ürününe de review atanmalı
            var firstProduct = vendor.Products?.FirstOrDefault();
            if (firstProduct == null)
            {
                return BadRequest(new ApiResponse<ReviewDto>(
                    LocalizationService.GetLocalizedString(ResourceName, "VendorHasNoProducts", CurrentCulture),
                    "VENDOR_HAS_NO_PRODUCTS"
                ));
            }

            // Kullanıcının bu vendor'a ait ürüne daha önce review verip vermediğini kontrol et
            var existingReview = await UnitOfWork.Reviews.Query()
                .FirstOrDefaultAsync(r => r.UserId == userId && r.ProductId == firstProduct.Id);

            if (existingReview != null)
            {
                return BadRequest(new ApiResponse<ReviewDto>(
                    LocalizationService.GetLocalizedString(ResourceName, "VendorReviewAlreadyExists", CurrentCulture),
                    "REVIEW_ALREADY_EXISTS"
                ));
            }

            review.VendorId = dto.TargetId;
            review.ProductId = firstProduct.Id;

            // Vendor review'ları varsayılan olarak onaylanmamış olarak oluşturulur
            review.IsApproved = false;
        }
        else
        {
            return BadRequest(new ApiResponse<ReviewDto>(LocalizationService.GetLocalizedString(ResourceName, "InvalidTargetType", CurrentCulture),
                "INVALID_TARGET_TYPE"
            ));
        }

        await UnitOfWork.Reviews.AddAsync(review);
        await UnitOfWork.SaveChangesAsync();

        // Reload review with related entities for mapping
        var reviewWithRelations = await UnitOfWork.Reviews.Query()
            .Include(r => r.User)
            .Include(r => r.Product)
                .ThenInclude(p => p.Vendor)
            .Include(r => r.Vendor)
            .FirstOrDefaultAsync(r => r.Id == review.Id);

        var reviewDto = _mapper.Map<ReviewDto>(reviewWithRelations ?? review);

        if (review.ProductId.HasValue)
        {
            return CreatedAtAction(nameof(GetProductReviews), new { productId = review.ProductId.Value },
                new ApiResponse<ReviewDto>(reviewDto, LocalizationService.GetLocalizedString(ResourceName, "ReviewCreatedSuccessfully", CurrentCulture)));
        }

        if (review.VendorId.HasValue)
        {
            return CreatedAtAction(
                nameof(GetVendorReviews),
                new { vendorId = review.VendorId.Value },
                new ApiResponse<ReviewDto>(
                    reviewDto,
                    LocalizationService.GetLocalizedString(ResourceName, "ReviewCreatedSuccessfully", CurrentCulture)));
        }

        // Fallback - should not happen because product or vendor is required
        return Ok(new ApiResponse<ReviewDto>(reviewDto,
            LocalizationService.GetLocalizedString(ResourceName, "ReviewCreatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Sipariş için toplu değerlendirme gönderir
    /// </summary>
    /// <param name="dto">Değerlendirme detayları</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("order-feedback")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<object>>> SubmitOrderFeedback(SubmitOrderFeedbackDto dto)
    {
        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "UserIdentityNotFound", CurrentCulture),
                "USER_IDENTITY_NOT_FOUND"));
        }

        // 1. Validate Order
        var order = await UnitOfWork.Orders.Query()
            .Include(o => o.OrderItems)
            .Include(o => o.OrderCouriers)
            .FirstOrDefaultAsync(o => o.Id == dto.OrderId);

        // Manually populate active courier if not mapped
        if (order != null && order.ActiveOrderCourier == null)
        {
            order.ActiveOrderCourier = order.OrderCouriers.FirstOrDefault(oc => oc.IsActive);
        }

        if (order == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "OrderNotFound", CurrentCulture),
                "ORDER_NOT_FOUND"));
        }

        if (order.CustomerId != userId)
        {
            return StatusCode(403, new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "Forbidden", CurrentCulture),
                "FORBIDDEN"));
        }

        if (order.Status != OrderStatus.Delivered)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "OrderNotDelivered", CurrentCulture),
                "ORDER_NOT_DELIVERED"));
        }

        // 2. Check for duplicate feedback for this order
        var existingReview = await UnitOfWork.Reviews.Query()
            .AnyAsync(r => r.OrderId == dto.OrderId);

        if (existingReview)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "OrderAlreadyReviewed", CurrentCulture),
                "ORDER_ALREADY_REVIEWED"));
        }

        var now = DateTime.UtcNow;

        // 3. Create Reviews
        var reviewsToAdd = new List<Review>();

        // 3.1 Courier Review
        if (order.ActiveOrderCourier != null)
        {
            reviewsToAdd.Add(new Review
            {
                UserId = userId,
                CourierId = order.ActiveOrderCourier.CourierId,
                OrderId = order.Id,
                Rating = dto.CourierRating,
                Comment = "", // Kurye yorumu istenmedi
                CreatedAt = now,
                IsApproved = true // Kurye puanı otomatik onaylı
            });
        }

        // 3.2 Vendor Review
        reviewsToAdd.Add(new Review
        {
            UserId = userId,
            VendorId = order.VendorId,
            OrderId = order.Id,
            Rating = dto.VendorFeedback.Rating,
            Comment = dto.VendorFeedback.Comment ?? "",
            CreatedAt = now,
            IsApproved = false // Vendor yorumları onay bekler
        });

        // 3.3 Product Reviews
        foreach (var itemFeedback in dto.ProductFeedbacks)
        {
            // Verify product belongs to order
            if (order.OrderItems.Any(oi => oi.ProductId == itemFeedback.ProductId))
            {
                reviewsToAdd.Add(new Review
                {
                    UserId = userId,
                    ProductId = itemFeedback.ProductId,
                    OrderId = order.Id,
                    Rating = itemFeedback.Rating,
                    Comment = itemFeedback.Comment ?? "",
                    CreatedAt = now,
                    IsApproved = false // Ürün yorumları onay bekler
                });
            }
        }

        if (reviewsToAdd.Count > 0)
        {
            await UnitOfWork.Reviews.AddRangeAsync(reviewsToAdd);
            await UnitOfWork.SaveChangesAsync();
        }

        return Ok(new ApiResponse<object>(new { },
            LocalizationService.GetLocalizedString(ResourceName, "FeedbackSubmittedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Ürün değerlendirmelerini getirir
    /// </summary>
    /// <param name="productId">Ürün ID'si</param>
    /// <returns>Değerlendirme listesi</returns>
    [HttpGet("products/{productId}")]
    public async Task<ActionResult<ApiResponse<ProductReviewsSummaryDto>>> GetProductReviews(Guid productId)
    {

        IQueryable<Review> query = UnitOfWork.Reviews.Query()
            .Include(r => r.User)
            .Include(r => r.Product)
                .ThenInclude(p => p!.Vendor)
            .Where(r => r.ProductId == productId && r.IsApproved);

        // Ortalama rating ve toplam sayıları hesapla
        var totalRatings = await query.CountAsync();
        var averageRating = totalRatings > 0
            ? await query.AverageAsync(r => (double)r.Rating)
            : 0.0;
        var totalComments = await query.CountAsync(r => !string.IsNullOrWhiteSpace(r.Comment));

        IOrderedQueryable<Review> orderedQuery = query.OrderByDescending(r => r.CreatedAt);

        var reviews = await orderedQuery
            .Include(r => r.User)
            .Include(r => r.Product)
                .ThenInclude(p => p.Vendor)
            .Include(r => r.Vendor)
            .ToListAsync();

        var reviewDtos = _mapper.Map<List<ReviewDto>>(reviews);

        var summary = new ProductReviewsSummaryDto
        {
            AverageRating = Math.Round(averageRating, 1),
            TotalRatings = totalRatings,
            TotalComments = totalComments,
            Reviews = reviewDtos
        };

        return Ok(new ApiResponse<ProductReviewsSummaryDto>(summary,
            LocalizationService.GetLocalizedString(ResourceName, "ProductReviewsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Satıcı değerlendirmelerini getirir
    /// </summary>
    /// <param name="vendorId">Satıcı ID'si</param>
    /// <returns>Değerlendirme listesi</returns>
    [HttpGet("vendors/{vendorId}")]
    public async Task<ActionResult<ApiResponse<List<ReviewDto>>>> GetVendorReviews(Guid vendorId)
    {

        IQueryable<Review> query = UnitOfWork.Reviews.Query()
            .Include(r => r.User)
            .Include(r => r.Vendor)
            .Include(r => r.Product)
                .ThenInclude(p => p.Vendor)
            .Where(r => r.VendorId == vendorId);

        IOrderedQueryable<Review> orderedQuery = query.OrderByDescending(r => r.CreatedAt);

        var reviews = await orderedQuery.ToListAsync();
        var reviewDtos = _mapper.Map<List<ReviewDto>>(reviews);

        return Ok(new ApiResponse<List<ReviewDto>>(
            reviewDtos,
            LocalizationService.GetLocalizedString(ResourceName, "VendorReviewsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Değerlendirmeyi onaylar (Sadece satıcı sahibi)
    /// </summary>
    /// <param name="reviewId">Değerlendirme ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPatch("{reviewId}/approve")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<object>>> ApproveReview(Guid reviewId)
    {

        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "UserIdentityNotFound", CurrentCulture),
                "USER_IDENTITY_NOT_FOUND"));
        }

        var review = await UnitOfWork.Reviews.Query()
            .Include(r => r.Vendor)
            .Include(r => r.Product)
                .ThenInclude(p => p!.Vendor)
            .FirstOrDefaultAsync(r => r.Id == reviewId);

        if (review == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "ReviewNotFound", CurrentCulture),
                "REVIEW_NOT_FOUND"));
        }

        bool isAuthorized = false;

        // Vendor review'ı kontrolü
        if (review.VendorId.HasValue && review.Vendor != null)
        {
            if (review.Vendor.OwnerId == userId)
            {
                isAuthorized = true;
            }
        }
        // Product review'ı kontrolü - product'ın vendor'ı kontrol et
        else if (review.ProductId.HasValue && review.Product != null && review.Product.Vendor != null)
        {
            if (review.Product.Vendor.OwnerId == userId)
            {
                isAuthorized = true;
            }
        }

        if (!isAuthorized)
        {
            return StatusCode(403, new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "ForbiddenApprove", CurrentCulture),
                "FORBIDDEN"
            ));
        }

        review.IsApproved = true;
        review.UpdatedAt = DateTime.UtcNow;
        UnitOfWork.Reviews.Update(review);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(
            new { },
            LocalizationService.GetLocalizedString(ResourceName, "ReviewApprovedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Değerlendirmeyi reddeder ve siler (Sadece satıcı sahibi)
    /// </summary>
    /// <param name="reviewId">Değerlendirme ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPatch("{reviewId}/reject")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<object>>> RejectReview(Guid reviewId)
    {

        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "UserIdentityNotFound", CurrentCulture),
                "USER_IDENTITY_NOT_FOUND"));
        }

        var review = await UnitOfWork.Reviews.Query()
            .Include(r => r.Vendor)
            .Include(r => r.Product)
                .ThenInclude(p => p!.Vendor)
            .FirstOrDefaultAsync(r => r.Id == reviewId);

        if (review == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "ReviewNotFound", CurrentCulture),
                "REVIEW_NOT_FOUND"));
        }

        bool isAuthorized = false;

        // Vendor review'ı kontrolü
        if (review.VendorId.HasValue && review.Vendor != null)
        {
            if (review.Vendor.OwnerId == userId)
            {
                isAuthorized = true;
            }
        }
        // Product review'ı kontrolü - product'ın vendor'ı kontrol et
        else if (review.ProductId.HasValue && review.Product != null && review.Product.Vendor != null)
        {
            if (review.Product.Vendor.OwnerId == userId)
            {
                isAuthorized = true;
            }
        }

        if (!isAuthorized)
        {
            return StatusCode(403, new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "ForbiddenReject", CurrentCulture),
                "FORBIDDEN"
            ));
        }

        // Review'ı sil veya reddedildi olarak işaretle
        UnitOfWork.Reviews.Remove(review);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "ReviewRejectedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Bekleyen değerlendirmeleri getirir (Sadece satıcı sahibi)
    /// </summary>
    /// <returns>Bekleyen değerlendirme listesi</returns>
    [HttpGet("pending")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<List<ReviewDto>>>> GetPendingReviews()
    {
        var userId = UserContext.GetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<List<ReviewDto>>(
                LocalizationService.GetLocalizedString(ResourceName, "UserIdentityNotFound", CurrentCulture),
                "USER_IDENTITY_NOT_FOUND"));
        }

        // Vendor owner'ının bekleyen review'larını getir
        var vendor = await UnitOfWork.Vendors.Query()
            .FirstOrDefaultAsync(v => v.OwnerId == userId);

        if (vendor == null)
        {
            return NotFound(new ApiResponse<List<ReviewDto>>(LocalizationService.GetLocalizedString(ResourceName,
                "VendorNotFoundForUser", CurrentCulture), "VENDOR_NOT_FOUND"));
        }

        // Vendor'ın ürün ID'lerini al
        var vendorProductIds = await UnitOfWork.Products.Query()
            .Where(p => p.VendorId == vendor.Id)
            .Select(p => p.Id)
            .ToListAsync();

        // Bekleyen review'ları getir: hem vendor review'ları hem de vendor'ın ürünlerinin review'ları
        IQueryable<Review> query = UnitOfWork.Reviews.Query().Include(r => r.User).Where(r => !r.IsApproved &&
            (
                (r.VendorId == vendor.Id) ||
                (r.ProductId.HasValue && vendorProductIds.Contains(r.ProductId.Value))
            ));

        IOrderedQueryable<Review> orderedQuery = query.OrderByDescending(r => r.CreatedAt);

        var reviews = await orderedQuery
            .Select(r => new ReviewDto
            {
                Id = r.Id,
                UserId = r.UserId,
                UserFullName = r.User != null ? r.User.FullName : "Anonymous",
                Rating = r.Rating,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt,
                IsApproved = r.IsApproved
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<ReviewDto>>(reviews, LocalizationService.GetLocalizedString(ResourceName, "PendingReviewsRetrievedSuccessfully", CurrentCulture)));
    }
}
