using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
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
public class FavoritesController : BaseController
{
    private const string ResourceName = "FavoriteResources";

    /// <summary>
    /// FavoritesController constructor
    /// </summary>
    public FavoritesController(
        IUnitOfWork unitOfWork,
        ILogger<FavoritesController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
    }

    /// <summary>
    /// Kullanıcının favori ürünlerini getirir (pagination desteği ile)
    /// </summary>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 20)</param>
    /// <returns>Sayfalanmış favori ürün listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> GetFavorites(
        [FromQuery] int page = 1, 
        [FromQuery] int pageSize = 20)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 20;
        if (pageSize > 100) pageSize = 100; // Max page size limit

        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        IQueryable<FavoriteProduct> query = UnitOfWork.FavoriteProducts.Query()
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

        return Ok(new ApiResponse<PagedResultDto<ProductDto>>(
            result, 
            LocalizationService.GetLocalizedString(ResourceName, "FavoritesRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Ürünü favorilere ekler
    /// </summary>
    /// <param name="productId">Ürün ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("{productId}")]
    public async Task<ActionResult<ApiResponse<object>>> AddToFavorites(Guid productId)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        // Check if product exists
        var product = await UnitOfWork.Products.GetByIdAsync(productId);
        if (product == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "ProductNotFound", CurrentCulture), 
                "PRODUCT_NOT_FOUND"));
        }

        // Check if already favorited
        var exists = await UnitOfWork.FavoriteProducts.Query()
            .AnyAsync(f => f.UserId == userId && f.ProductId == productId);

        if (exists)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "AlreadyInFavorites", CurrentCulture), 
                "ALREADY_IN_FAVORITES"));
        }

        var favorite = new FavoriteProduct
        {
            UserId = userId,
            ProductId = productId
        };

        await UnitOfWork.FavoriteProducts.AddAsync(favorite);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(
            new { }, 
            LocalizationService.GetLocalizedString(ResourceName, "AddedToFavorites", CurrentCulture)));
    }

    /// <summary>
    /// Ürünü favorilerden çıkarır
    /// </summary>
    /// <param name="productId">Ürün ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpDelete("{productId}")]
    public async Task<ActionResult<ApiResponse<object>>> RemoveFromFavorites(Guid productId)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var favorite = await UnitOfWork.FavoriteProducts.Query()
            .FirstOrDefaultAsync(f => f.UserId == userId && f.ProductId == productId);

        if (favorite == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "FavoriteNotFound", CurrentCulture), 
                "FAVORITE_NOT_FOUND"));
        }

        UnitOfWork.FavoriteProducts.Remove(favorite);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(
            new { }, 
            LocalizationService.GetLocalizedString(ResourceName, "RemovedFromFavorites", CurrentCulture)));
    }

    /// <summary>
    /// Ürünün favorilerde olup olmadığını kontrol eder
    /// </summary>
    /// <param name="productId">Ürün ID'si</param>
    /// <returns>Favori durumu</returns>
    [HttpGet("check/{productId}")]
    public async Task<ActionResult<ApiResponse<object>>> IsFavorite(Guid productId)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var isFavorite = await UnitOfWork.FavoriteProducts.Query()
            .AnyAsync(f => f.UserId == userId && f.ProductId == productId);

        return Ok(new ApiResponse<object>(
            new { IsFavorite = isFavorite }, 
            LocalizationService.GetLocalizedString(ResourceName, "FavoriteStatusChecked", CurrentCulture)));
    }
}
