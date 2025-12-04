using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Değerlendirme (review) işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class ReviewsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly UserManager<AppUser> _userManager;

    /// <summary>
    /// ReviewsController constructor
    /// </summary>
    public ReviewsController(IUnitOfWork unitOfWork, UserManager<AppUser> userManager)
    {
        _unitOfWork = unitOfWork;
        _userManager = userManager;
    }

    private string? TryGetUserId() =>
        User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
        ?? User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value;

    /// <summary>
    /// Yeni değerlendirme oluşturur
    /// </summary>
    /// <param name="dto">Değerlendirme bilgileri</param>
    /// <returns>Oluşturulan değerlendirme</returns>
    [HttpPost]
    [Authorize]
    public async Task<ActionResult<ApiResponse<ReviewDto>>> CreateReview(CreateReviewDto dto)
    {
        var userId = TryGetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<ReviewDto>("Kullanıcı kimliği belirlenemedi", "USER_IDENTITY_NOT_FOUND"));
        }
        var user = await _userManager.FindByIdAsync(userId);
        if (user == null)
        {
            return Unauthorized(new ApiResponse<ReviewDto>("Kullanıcı bulunamadı", "USER_NOT_FOUND"));
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
            var product = await _unitOfWork.Products.GetByIdAsync(dto.TargetId);
            if (product == null)
            {
                return NotFound(new ApiResponse<ReviewDto>("Ürün bulunamadı", "PRODUCT_NOT_FOUND"));
            }

            // Kullanıcının bu ürüne daha önce review verip vermediğini kontrol et
            var existingReview = await _unitOfWork.Reviews.Query()
                .FirstOrDefaultAsync(r => r.UserId == userId && r.ProductId == dto.TargetId);

            if (existingReview != null)
            {
                return BadRequest(new ApiResponse<ReviewDto>(
                    "Bu ürüne zaten değerlendirme yaptınız. Başka bir değerlendirme oluşturamazsınız.",
                    "REVIEW_ALREADY_EXISTS"
                ));
            }

            review.ProductId = dto.TargetId;
            // Product review'ları otomatik onaylanır
            review.IsApproved = true;
        }
        else if (dto.TargetType.Equals("Vendor", StringComparison.OrdinalIgnoreCase))
        {
            var vendor = await _unitOfWork.Vendors.Query()
                .Include(v => v.Products)
                .FirstOrDefaultAsync(v => v.Id == dto.TargetId);
            if (vendor == null)
            {
                return NotFound(new ApiResponse<ReviewDto>("Satıcı bulunamadı", "VENDOR_NOT_FOUND"));
            }

            // Vendor review'ı için o vendor'ın bir ürününe de review atanmalı
            var firstProduct = vendor.Products?.FirstOrDefault();
            if (firstProduct == null)
            {
                return BadRequest(new ApiResponse<ReviewDto>(
                    "Satıcının ürünü yok. Ürün olmadan satıcı değerlendirmesi oluşturulamaz.",
                    "VENDOR_HAS_NO_PRODUCTS"
                ));
            }

            // Kullanıcının bu vendor'a ait ürüne daha önce review verip vermediğini kontrol et
            var existingReview = await _unitOfWork.Reviews.Query()
                .FirstOrDefaultAsync(r => r.UserId == userId && r.ProductId == firstProduct.Id);

            if (existingReview != null)
            {
                return BadRequest(new ApiResponse<ReviewDto>(
                    "Bu satıcının bir ürününe zaten değerlendirme yaptınız. Başka bir değerlendirme oluşturamazsınız.",
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
            return BadRequest(new ApiResponse<ReviewDto>(
                "Geçersiz hedef tipi. 'Product' veya 'Vendor' olmalıdır.",
                "INVALID_TARGET_TYPE"
            ));
        }

        await _unitOfWork.Reviews.AddAsync(review);
        await _unitOfWork.SaveChangesAsync();

        var reviewDto = new ReviewDto
        {
            Id = review.Id,
            UserId = review.UserId,
            UserFullName = user.FullName,
            Rating = review.Rating,
            Comment = review.Comment,
            CreatedAt = review.CreatedAt,
            IsApproved = review.IsApproved
        };

        if (review.ProductId.HasValue)
        {
            return CreatedAtAction(
                nameof(GetProductReviews),
                new { productId = review.ProductId.Value },
                new ApiResponse<ReviewDto>(reviewDto, "Değerlendirme başarıyla oluşturuldu"));
        }

        if (review.VendorId.HasValue)
        {
            return CreatedAtAction(
                nameof(GetVendorReviews),
                new { vendorId = review.VendorId.Value },
                new ApiResponse<ReviewDto>(reviewDto, "Değerlendirme başarıyla oluşturuldu"));
        }

        // Fallback - should not happen because product or vendor is required
        return Ok(new ApiResponse<ReviewDto>(reviewDto, "Değerlendirme başarıyla oluşturuldu"));
    }

    /// <summary>
    /// Ürün değerlendirmelerini getirir
    /// </summary>
    /// <param name="productId">Ürün ID'si</param>
    /// <returns>Değerlendirme listesi</returns>
    [HttpGet("products/{productId}")]
    public async Task<ActionResult<ApiResponse<List<ReviewDto>>>> GetProductReviews(Guid productId)
    {
        IQueryable<Review> query = _unitOfWork.Reviews.Query()
            .Include(r => r.User)
            .Where(r => r.ProductId == productId && r.IsApproved);

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

        return Ok(new ApiResponse<List<ReviewDto>>(reviews, "Ürün değerlendirmeleri başarıyla getirildi"));
    }

    /// <summary>
    /// Satıcı değerlendirmelerini getirir
    /// </summary>
    /// <param name="vendorId">Satıcı ID'si</param>
    /// <returns>Değerlendirme listesi</returns>
    [HttpGet("vendors/{vendorId}")]
    public async Task<ActionResult<ApiResponse<List<ReviewDto>>>> GetVendorReviews(Guid vendorId)
    {
        IQueryable<Review> query = _unitOfWork.Reviews.Query()
            .Include(r => r.User)
            .Where(r => r.VendorId == vendorId);

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

        return Ok(new ApiResponse<List<ReviewDto>>(reviews, "Satıcı değerlendirmeleri başarıyla getirildi"));
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
        var userId = TryGetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<object>("Kullanıcı kimliği belirlenemedi", "USER_IDENTITY_NOT_FOUND"));
        }

        var review = await _unitOfWork.Reviews.Query()
            .Include(r => r.Vendor)
            .FirstOrDefaultAsync(r => r.Id == reviewId);

        if (review == null)
        {
            return NotFound(new ApiResponse<object>("Değerlendirme bulunamadı", "REVIEW_NOT_FOUND"));
        }

        // Sadece vendor owner'ı kendi vendor'ının review'larını onaylayabilir
        if (review.VendorId.HasValue && review.Vendor != null)
        {
            if (review.Vendor.OwnerId != userId)
            {
                return StatusCode(403, new ApiResponse<object>(
                    "Sadece satıcı sahibi kendi satıcısının değerlendirmelerini onaylayabilir.",
                    "FORBIDDEN"
                ));
            }
        }
        else
        {
            return BadRequest(new ApiResponse<object>(
                "Bu değerlendirme bir satıcıyla ilişkili değil.",
                "REVIEW_NOT_ASSOCIATED_WITH_VENDOR"
            ));
        }

        review.IsApproved = true;
        review.UpdatedAt = DateTime.UtcNow;
        _unitOfWork.Reviews.Update(review);
        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Değerlendirme başarıyla onaylandı"));
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
        var userId = TryGetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<object>("Kullanıcı kimliği belirlenemedi", "USER_IDENTITY_NOT_FOUND"));
        }

        var review = await _unitOfWork.Reviews.Query()
            .Include(r => r.Vendor)
            .FirstOrDefaultAsync(r => r.Id == reviewId);

        if (review == null)
        {
            return NotFound(new ApiResponse<object>("Değerlendirme bulunamadı", "REVIEW_NOT_FOUND"));
        }

        // Sadece vendor owner'ı kendi vendor'ının review'larını reddedebilir
        if (review.VendorId.HasValue && review.Vendor != null)
        {
            if (review.Vendor.OwnerId != userId)
            {
                return StatusCode(403, new ApiResponse<object>(
                    "Sadece satıcı sahibi kendi satıcısının değerlendirmelerini reddedebilir.",
                    "FORBIDDEN"
                ));
            }
        }
        else
        {
            return BadRequest(new ApiResponse<object>(
                "Bu değerlendirme bir satıcıyla ilişkili değil.",
                "REVIEW_NOT_ASSOCIATED_WITH_VENDOR"
            ));
        }

        // Review'ı sil veya reddedildi olarak işaretle
        _unitOfWork.Reviews.Remove(review);
        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Değerlendirme başarıyla reddedildi ve silindi"));
    }

    /// <summary>
    /// Bekleyen değerlendirmeleri getirir (Sadece satıcı sahibi)
    /// </summary>
    /// <returns>Bekleyen değerlendirme listesi</returns>
    [HttpGet("pending")]
    [Authorize]
    public async Task<ActionResult<ApiResponse<List<ReviewDto>>>> GetPendingReviews()
    {
        var userId = TryGetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized(new ApiResponse<List<ReviewDto>>("Kullanıcı kimliği belirlenemedi", "USER_IDENTITY_NOT_FOUND"));
        }

        // Vendor owner'ının bekleyen review'larını getir
        var vendor = await _unitOfWork.Vendors.Query()
            .FirstOrDefaultAsync(v => v.OwnerId == userId);

        if (vendor == null)
        {
            return NotFound(new ApiResponse<List<ReviewDto>>("Bu kullanıcı için satıcı bulunamadı", "VENDOR_NOT_FOUND"));
        }

        IQueryable<Review> query = _unitOfWork.Reviews.Query()
            .Include(r => r.User)
            .Where(r => r.VendorId == vendor.Id && !r.IsApproved);

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

        return Ok(new ApiResponse<List<ReviewDto>>(reviews, "Bekleyen değerlendirmeler başarıyla getirildi"));
    }
}
