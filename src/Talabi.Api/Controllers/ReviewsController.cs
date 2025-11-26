using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ReviewsController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public ReviewsController(TalabiDbContext context)
    {
        _context = context;
    }

    private string? TryGetUserId() =>
        User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
        ?? User.FindFirst(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub)?.Value;

    [HttpPost]
    [Authorize]
    public async Task<ActionResult<ReviewDto>> CreateReview(CreateReviewDto dto)
    {
        var userId = TryGetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized("User identity could not be determined.");
        }
        var user = await _context.Users.FindAsync(userId);
        if (user == null) return Unauthorized();

        var review = new Review
        {
            UserId = userId,
            Rating = dto.Rating,
            Comment = dto.Comment,
            CreatedAt = DateTime.UtcNow
        };

        if (dto.TargetType.Equals("Product", StringComparison.OrdinalIgnoreCase))
        {
            var product = await _context.Products.FindAsync(dto.TargetId);
            if (product == null) return NotFound("Product not found");
            
            // Kullanıcının bu ürüne daha önce review verip vermediğini kontrol et
            var existingReview = await _context.Reviews
                .FirstOrDefaultAsync(r => r.UserId == userId && r.ProductId == dto.TargetId);
            
            if (existingReview != null)
            {
                return BadRequest("You have already reviewed this product. You cannot create another review.");
            }
            
            review.ProductId = dto.TargetId;
            // Product review'ları otomatik onaylanır
            review.IsApproved = true;
        }
        else if (dto.TargetType.Equals("Vendor", StringComparison.OrdinalIgnoreCase))
        {
            var vendor = await _context.Vendors
                .Include(v => v.Products)
                .FirstOrDefaultAsync(v => v.Id == dto.TargetId);
            if (vendor == null) return NotFound("Vendor not found");
            
            // Vendor review'ı için o vendor'ın bir ürününe de review atanmalı
            var firstProduct = vendor.Products?.FirstOrDefault();
            if (firstProduct == null)
            {
                return BadRequest("Vendor has no products. Cannot create vendor review without a product.");
            }
            
            // Kullanıcının bu vendor'a ait ürüne daha önce review verip vermediğini kontrol et
            var existingReview = await _context.Reviews
                .FirstOrDefaultAsync(r => r.UserId == userId && r.ProductId == firstProduct.Id);
            
            if (existingReview != null)
            {
                return BadRequest("You have already reviewed a product from this vendor. You cannot create another review.");
            }
            
            review.VendorId = dto.TargetId;
            review.ProductId = firstProduct.Id;
            
            // Vendor review'ları varsayılan olarak onaylanmamış olarak oluşturulur
            review.IsApproved = false;
        }
        else
        {
            return BadRequest("Invalid target type. Must be 'Product' or 'Vendor'.");
        }

        _context.Reviews.Add(review);
        await _context.SaveChangesAsync();

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
                reviewDto);
        }

        if (review.VendorId.HasValue)
        {
            return CreatedAtAction(
                nameof(GetVendorReviews),
                new { vendorId = review.VendorId.Value },
                reviewDto);
        }

        // Fallback - should not happen because product or vendor is required
        return Ok(reviewDto);
    }

    [HttpGet("products/{productId}")]
    public async Task<ActionResult<List<ReviewDto>>> GetProductReviews(int productId)
    {
        var reviews = await _context.Reviews
            .Include(r => r.User)
            .Where(r => r.ProductId == productId && r.IsApproved)
            .OrderByDescending(r => r.CreatedAt)
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

        return Ok(reviews);
    }

    [HttpGet("vendors/{vendorId}")]
    public async Task<ActionResult<List<ReviewDto>>> GetVendorReviews(int vendorId)
    {
        var reviews = await _context.Reviews
            .Include(r => r.User)
            .Where(r => r.VendorId == vendorId)
            .OrderByDescending(r => r.CreatedAt)
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

        return Ok(reviews);
    }

    [HttpPatch("{reviewId}/approve")]
    [Authorize]
    public async Task<ActionResult> ApproveReview(int reviewId)
    {
        var userId = TryGetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized("User identity could not be determined.");
        }

        var review = await _context.Reviews
            .Include(r => r.Vendor)
            .FirstOrDefaultAsync(r => r.Id == reviewId);

        if (review == null)
        {
            return NotFound("Review not found.");
        }

        // Sadece vendor owner'ı kendi vendor'ının review'larını onaylayabilir
        if (review.VendorId.HasValue && review.Vendor != null)
        {
            if (review.Vendor.OwnerId != userId)
            {
                return Forbid("Only the vendor owner can approve reviews for their vendor.");
            }
        }
        else
        {
            return BadRequest("This review is not associated with a vendor.");
        }

        review.IsApproved = true;
        review.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(new { message = "Review approved successfully." });
    }

    [HttpPatch("{reviewId}/reject")]
    [Authorize]
    public async Task<ActionResult> RejectReview(int reviewId)
    {
        var userId = TryGetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized("User identity could not be determined.");
        }

        var review = await _context.Reviews
            .Include(r => r.Vendor)
            .FirstOrDefaultAsync(r => r.Id == reviewId);

        if (review == null)
        {
            return NotFound("Review not found.");
        }

        // Sadece vendor owner'ı kendi vendor'ının review'larını reddedebilir
        if (review.VendorId.HasValue && review.Vendor != null)
        {
            if (review.Vendor.OwnerId != userId)
            {
                return Forbid("Only the vendor owner can reject reviews for their vendor.");
            }
        }
        else
        {
            return BadRequest("This review is not associated with a vendor.");
        }

        // Review'ı sil veya reddedildi olarak işaretle
        _context.Reviews.Remove(review);
        await _context.SaveChangesAsync();

        return Ok(new { message = "Review rejected and removed successfully." });
    }

    [HttpGet("pending")]
    [Authorize]
    public async Task<ActionResult<List<ReviewDto>>> GetPendingReviews()
    {
        var userId = TryGetUserId();
        if (string.IsNullOrWhiteSpace(userId))
        {
            return Unauthorized("User identity could not be determined.");
        }

        // Vendor owner'ının bekleyen review'larını getir
        var vendor = await _context.Vendors
            .FirstOrDefaultAsync(v => v.OwnerId == userId);

        if (vendor == null)
        {
            return NotFound("Vendor not found for this user.");
        }

        var reviews = await _context.Reviews
            .Include(r => r.User)
            .Where(r => r.VendorId == vendor.Id && !r.IsApproved)
            .OrderByDescending(r => r.CreatedAt)
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

        return Ok(reviews);
    }
}
