using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Extensions;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Favori ürünler için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class FavoritesController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    /// <summary>
    /// FavoritesController constructor
    /// </summary>
    public FavoritesController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    /// <summary>
    /// Kullanıcının favori ürünlerini getirir (pagination desteği ile)
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 20)</param>
    /// <returns>Sayfalanmış favori ürün listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> GetFavorites([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 20;
        if (pageSize > 100) pageSize = 100; // Max page size limit

        var userId = GetUserId();

        IQueryable<FavoriteProduct> query = _unitOfWork.FavoriteProducts.Query()
            .Where(f => f.UserId == userId)
            .Include(f => f.Product);

        // Order by most recently added first
        IOrderedQueryable<FavoriteProduct> orderedQuery = query.OrderByDescending(f => f.Id);

        // Pagination ve DTO mapping
        var pagedResult = await orderedQuery.ToPagedResultAsync(
            f => new ProductDto
            {
                Id = f.Product!.Id,
                VendorId = f.Product.VendorId,
                Name = f.Product.Name,
                Description = f.Product.Description,
                Price = f.Product.Price,
                Currency = f.Product.Currency,
                ImageUrl = f.Product.ImageUrl
            },
            page,
            pageSize);

        // PagedResult'ı PagedResultDto'ya çevir
        var result = new PagedResultDto<ProductDto>
        {
            Items = pagedResult.Items,
            TotalCount = pagedResult.TotalCount,
            Page = pagedResult.Page,
            PageSize = pagedResult.PageSize,
            TotalPages = pagedResult.TotalPages
        };

        return Ok(new ApiResponse<PagedResultDto<ProductDto>>(result, "Favori ürünler başarıyla getirildi"));
    }

    /// <summary>
    /// Ürünü favorilere ekler
    /// </summary>
    /// <param name="productId">Ürün ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{productId}")]
    public async Task<ActionResult<ApiResponse<object>>> AddToFavorites(Guid productId)
    {
        var userId = GetUserId();

        // Check if product exists
        var product = await _unitOfWork.Products.GetByIdAsync(productId);
        if (product == null)
        {
            return NotFound(new ApiResponse<object>("Ürün bulunamadı", "PRODUCT_NOT_FOUND"));
        }

        // Check if already favorited
        var exists = await _unitOfWork.FavoriteProducts.Query()
            .AnyAsync(f => f.UserId == userId && f.ProductId == productId);

        if (exists)
        {
            return BadRequest(new ApiResponse<object>("Ürün zaten favorilerde", "ALREADY_IN_FAVORITES"));
        }

        var favorite = new FavoriteProduct
        {
            UserId = userId,
            ProductId = productId
        };

        await _unitOfWork.FavoriteProducts.AddAsync(favorite);
        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Favorilere eklendi"));
    }

    /// <summary>
    /// Ürünü favorilerden çıkarır
    /// </summary>
    /// <param name="productId">Ürün ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpDelete("{productId}")]
    public async Task<ActionResult<ApiResponse<object>>> RemoveFromFavorites(Guid productId)
    {
        var userId = GetUserId();

        var favorite = await _unitOfWork.FavoriteProducts.Query()
            .FirstOrDefaultAsync(f => f.UserId == userId && f.ProductId == productId);

        if (favorite == null)
        {
            return NotFound(new ApiResponse<object>("Favori bulunamadı", "FAVORITE_NOT_FOUND"));
        }

        _unitOfWork.FavoriteProducts.Remove(favorite);
        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Favorilerden çıkarıldı"));
    }

    /// <summary>
    /// Ürünün favorilerde olup olmadığını kontrol eder
    /// </summary>
    /// <param name="productId">Ürün ID'si</param>
    /// <returns>Favori durumu</returns>
    [HttpGet("check/{productId}")]
    public async Task<ActionResult<ApiResponse<object>>> IsFavorite(Guid productId)
    {
        var userId = GetUserId();

        var isFavorite = await _unitOfWork.FavoriteProducts.Query()
            .AnyAsync(f => f.UserId == userId && f.ProductId == productId);

        return Ok(new ApiResponse<object>(new { IsFavorite = isFavorite }, "Favori durumu kontrol edildi"));
    }
}
