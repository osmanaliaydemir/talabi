using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Satıcı ürün işlemleri için controller
/// </summary>
[Route("api/vendor/products")]
[ApiController]
[Authorize]
public class VendorProductsController : BaseController
{
    private const string ResourceName = "VendorProductResources";

    /// <summary>
    /// VendorProductsController constructor
    /// </summary>
    public VendorProductsController(
        IUnitOfWork unitOfWork,
        ILogger<VendorProductsController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
    }

    private async Task<Guid?> GetVendorIdAsync()
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return null;
        }

        var vendor = await UnitOfWork.Vendors.Query()
            .FirstOrDefaultAsync(v => v.OwnerId == userId);
        return vendor?.Id;
    }

    /// <summary>
    /// Satıcının ürünlerini getirir
    /// </summary>
    /// <param name="category">Kategori filtresi (opsiyonel)</param>
    /// <param name="isAvailable">Müsaitlik filtresi (opsiyonel)</param>
    /// <param name="page">Sayfa numarası (varsayılan: 1)</param>
    /// <param name="pageSize">Sayfa boyutu (varsayılan: 6)</param>
    /// <returns>Sayfalanmış ürün listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResultDto<VendorProductDto>>>> GetProducts(
        [FromQuery] string? category = null,
        [FromQuery] bool? isAvailable = null,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 6)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return NotFound(new ApiResponse<PagedResultDto<VendorProductDto>>(
                LocalizationService.GetLocalizedString(ResourceName, "VendorNotFoundForUser", CurrentCulture),
                "VENDOR_NOT_FOUND"));
        }

        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 6;

        IQueryable<Product> query = UnitOfWork.Products.Query()
            .Where(p => p.VendorId == vendorId.Value);

        if (!string.IsNullOrWhiteSpace(category))
            query = query.Where(p => p.Category == category);

        if (isAvailable.HasValue)
            query = query.Where(p => p.IsAvailable == isAvailable.Value);

        IOrderedQueryable<Product> orderedQuery = query.OrderByDescending(p => p.CreatedAt);

        // Pagination ve DTO mapping - Gelişmiş query helper kullanımı
        var pagedResult = await orderedQuery.ToPagedResultAsync(
            p => new VendorProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                Name = p.Name,
                Description = p.Description,
                Category = p.Category,
                Price = p.Price,
                Currency = p.Currency,
                ImageUrl = p.ImageUrl,
                IsAvailable = p.IsAvailable,
                Stock = p.Stock,
                CategoryId = p.CategoryId,
                PreparationTime = p.PreparationTime,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt
            },
            page,
            pageSize);

        // PagedResult'ı PagedResultDto'ya çevir
        var result = new PagedResultDto<VendorProductDto>
        {
            Items = pagedResult.Items,
            TotalCount = pagedResult.TotalCount,
            Page = pagedResult.Page,
            PageSize = pagedResult.PageSize,
            TotalPages = pagedResult.TotalPages
        };

        return Ok(new ApiResponse<PagedResultDto<VendorProductDto>>(
            result,
            LocalizationService.GetLocalizedString(ResourceName, "VendorProductsRetrievedSuccessfully",
                CurrentCulture)));
    }

    /// <summary>
    /// Belirli bir ürünü getirir
    /// </summary>
    /// <param name="id">Ürün ID'si</param>
    /// <returns>Ürün bilgileri</returns>
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<VendorProductDto>>> GetProduct(Guid id)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return NotFound(new ApiResponse<VendorProductDto>(
                LocalizationService.GetLocalizedString(ResourceName, "VendorNotFoundForUser", CurrentCulture),
                "VENDOR_NOT_FOUND"));
        }

        var product = await UnitOfWork.Products.Query()
            .Where(p => p.Id == id && p.VendorId == vendorId.Value)
            .Select(p => new VendorProductDto
            {
                Id = p.Id,
                VendorId = p.VendorId,
                Name = p.Name,
                Description = p.Description,
                Category = p.Category,
                Price = p.Price,
                Currency = p.Currency,
                ImageUrl = p.ImageUrl,
                IsAvailable = p.IsAvailable,
                Stock = p.Stock,
                CategoryId = p.CategoryId,
                PreparationTime = p.PreparationTime,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt,
                OptionGroups = p.OptionGroups.Select(og => new ProductOptionGroupDto
                {
                    Id = og.Id,
                    Name = og.Name,
                    IsRequired = og.IsRequired,
                    AllowMultiple = og.AllowMultiple,
                    MinSelection = og.MinSelection,
                    MaxSelection = og.MaxSelection,
                    DisplayOrder = og.DisplayOrder,
                    Options = og.Options.Select(ov => new ProductOptionValueDto
                    {
                        Id = ov.Id,
                        Name = ov.Name,
                        PriceAdjustment = ov.PriceAdjustment,
                        IsDefault = ov.IsDefault,
                        DisplayOrder = ov.DisplayOrder
                    }).OrderBy(o => o.DisplayOrder).ToList()
                }).OrderBy(g => g.DisplayOrder).ToList()
            })
            .FirstOrDefaultAsync();

        if (product == null)
        {
            return NotFound(new ApiResponse<VendorProductDto>(
                LocalizationService.GetLocalizedString(ResourceName, "ProductNotFoundOrNoAccess", CurrentCulture),
                "PRODUCT_NOT_FOUND"));
        }

        return Ok(new ApiResponse<VendorProductDto>(
            product,
            LocalizationService.GetLocalizedString(ResourceName, "ProductRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Yeni ürün oluşturur
    /// </summary>
    /// <param name="dto">Ürün bilgileri</param>
    /// <returns>Oluşturulan ürün</returns>
    [HttpPost]
    public async Task<ActionResult<ApiResponse<VendorProductDto>>> CreateProduct(CreateProductDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return NotFound(new ApiResponse<VendorProductDto>(
                LocalizationService.GetLocalizedString(ResourceName, "VendorNotFoundForUser", CurrentCulture),
                "VENDOR_NOT_FOUND"));
        }

        var product = new Product
        {
            VendorId = vendorId.Value,
            Name = dto.Name,
            Description = dto.Description,
            Category = dto.Category,
            CategoryId = dto.CategoryId,
            Price = dto.Price,
            Currency = dto.Currency,
            ImageUrl = dto.ImageUrl,
            IsAvailable = dto.IsAvailable,
            Stock = dto.Stock,
            PreparationTime = dto.PreparationTime,
            OptionGroups = dto.OptionGroups?.Select(g => new ProductOptionGroup
            {
                Name = g.Name,
                IsRequired = g.IsRequired,
                AllowMultiple = g.AllowMultiple,
                MinSelection = g.MinSelection,
                MaxSelection = g.MaxSelection,
                DisplayOrder = g.DisplayOrder,
                Options = g.Options?.Select(o => new ProductOptionValue
                {
                    Name = o.Name,
                    PriceAdjustment = o.PriceAdjustment,
                    IsDefault = o.IsDefault,
                    DisplayOrder = o.DisplayOrder
                }).ToList() ?? new List<ProductOptionValue>()
            }).ToList() ?? new List<ProductOptionGroup>()
        };

        await UnitOfWork.Products.AddAsync(product);
        await UnitOfWork.SaveChangesAsync();

        var result = new VendorProductDto
        {
            Id = product.Id,
            VendorId = product.VendorId,
            Name = product.Name,
            Description = product.Description,
            Category = product.Category,
            Price = product.Price,
            Currency = product.Currency,
            ImageUrl = product.ImageUrl,
            IsAvailable = product.IsAvailable,
            Stock = product.Stock,
            CategoryId = product.CategoryId,
            PreparationTime = product.PreparationTime,
            CreatedAt = product.CreatedAt,
            UpdatedAt = product.UpdatedAt,
            OptionGroups = product.OptionGroups.Select(og => new ProductOptionGroupDto
            {
                Id = og.Id,
                Name = og.Name,
                IsRequired = og.IsRequired,
                AllowMultiple = og.AllowMultiple,
                MinSelection = og.MinSelection,
                MaxSelection = og.MaxSelection,
                DisplayOrder = og.DisplayOrder,
                Options = og.Options.Select(ov => new ProductOptionValueDto
                {
                    Id = ov.Id,
                    Name = ov.Name,
                    PriceAdjustment = ov.PriceAdjustment,
                    IsDefault = ov.IsDefault,
                    DisplayOrder = ov.DisplayOrder
                }).ToList()
            }).ToList()
        };

        return CreatedAtAction(
            nameof(GetProduct),
            new { id = product.Id },
            new ApiResponse<VendorProductDto>(
                result,
                LocalizationService.GetLocalizedString(ResourceName, "ProductCreatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Ürün bilgilerini günceller
    /// </summary>
    /// <param name="id">Ürün ID'si</param>
    /// <param name="dto">Güncellenecek ürün bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateProduct(Guid id, UpdateProductDto dto)
    {
        try
        {
            var vendorId = await GetVendorIdAsync();
            if (vendorId == null)
            {
                return NotFound(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "VendorNotFoundForUser", CurrentCulture),
                    "VENDOR_NOT_FOUND"));
            }

            // Use AsNoTracking to fetch the product. 
            // This prevents EF from tracking it, allowing us to modifying it and call Update() 
            // without "Optimistic Concurrency" issues related to original values.
            var product = await UnitOfWork.Products.Query()
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == id && p.VendorId == vendorId.Value);

            if (product == null)
            {
                return NotFound(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "ProductNotFoundOrNoUpdateAccess",
                        CurrentCulture),
                    "PRODUCT_NOT_FOUND"));
            }

            // Update only provided fields on the detached object
            if (dto.Name != null) product.Name = dto.Name;
            if (dto.Description != null) product.Description = dto.Description;
            if (dto.Category != null) product.Category = dto.Category;
            if (dto.CategoryId.HasValue) product.CategoryId = dto.CategoryId.Value;
            if (dto.Price.HasValue) product.Price = dto.Price.Value;
            if (dto.Currency.HasValue) product.Currency = dto.Currency.Value;
            if (dto.ImageUrl != null) product.ImageUrl = dto.ImageUrl;
            if (dto.IsAvailable.HasValue) product.IsAvailable = dto.IsAvailable.Value;
            if (dto.Stock.HasValue) product.Stock = dto.Stock;
            if (dto.PreparationTime.HasValue) product.PreparationTime = dto.PreparationTime;

            product.UpdatedAt = DateTime.UtcNow;

            // Handle Option Groups
            if (dto.OptionGroups != null)
            {
                // 1. Direct Delete from DB
                await UnitOfWork.ProductOptionGroups.Query()
                    .Where(og => og.ProductId == id)
                    .ExecuteDeleteAsync();

                // 2. Prepare new groups
                var newGroups = new List<ProductOptionGroup>();
                foreach (var groupDto in dto.OptionGroups)
                {
                    var newGroup = new ProductOptionGroup
                    {
                        ProductId = product.Id, // Explicitly set FK
                        Name = groupDto.Name,
                        IsRequired = groupDto.IsRequired,
                        AllowMultiple = groupDto.AllowMultiple,
                        MinSelection = groupDto.MinSelection,
                        MaxSelection = groupDto.MaxSelection,
                        DisplayOrder = groupDto.DisplayOrder,
                        Options = groupDto.Options?.Select(o => new ProductOptionValue
                        {
                            Name = o.Name,
                            PriceAdjustment = o.PriceAdjustment,
                            IsDefault = o.IsDefault,
                            DisplayOrder = o.DisplayOrder
                        }).ToList() ?? new List<ProductOptionValue>()
                    };
                    newGroups.Add(newGroup);
                }

                // 3. Add new groups directly to repository
                if (newGroups.Any())
                {
                    await UnitOfWork.ProductOptionGroups.AddRangeAsync(newGroups);
                }
            }

            // Mark product as Modified. 
            // Since it's detached (AsNoTracking), this forces an update without checking original values (Concurrency-Safe way).
            UnitOfWork.Products.Update(product);

            await UnitOfWork.SaveChangesAsync();

            return Ok(new ApiResponse<object>(
                new { },
                LocalizationService.GetLocalizedString(ResourceName, "ProductUpdatedSuccessfully", CurrentCulture)));
        }
        catch (Exception ex)
        {
            // Return 200 with error details to bypass client-side 500 checks and see the error
            var fullError = $"Message: {ex.Message} | Inner: {ex.InnerException?.Message} | Stack: {ex.StackTrace}";
            return Ok(new ApiResponse<object>(fullError, "UPDATE_FAILED_EXCEPTION"));
        }
    }

    /// <summary>
    /// Ürünü siler
    /// </summary>
    /// <param name="id">Ürün ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteProduct(Guid id)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "VendorNotFoundForUser", CurrentCulture),
                "VENDOR_NOT_FOUND"));
        }

        var product = await UnitOfWork.Products.Query()
            .FirstOrDefaultAsync(p => p.Id == id && p.VendorId == vendorId.Value);

        if (product == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "ProductNotFoundOrNoDeleteAccess", CurrentCulture),
                "PRODUCT_NOT_FOUND"));
        }

        UnitOfWork.Products.Remove(product);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(
            new { },
            LocalizationService.GetLocalizedString(ResourceName, "ProductDeletedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Ürün müsaitlik durumunu günceller
    /// </summary>
    /// <param name="id">Ürün ID'si</param>
    /// <param name="dto">Müsaitlik bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{id}/availability")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateProductAvailability(Guid id,
        UpdateProductAvailabilityDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "VendorNotFoundForUser", CurrentCulture),
                "VENDOR_NOT_FOUND"));
        }

        var product = await UnitOfWork.Products.Query()
            .FirstOrDefaultAsync(p => p.Id == id && p.VendorId == vendorId.Value);

        if (product == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "ProductNotFoundOrNoUpdateAccess", CurrentCulture),
                "PRODUCT_NOT_FOUND"));
        }

        product.IsAvailable = dto.IsAvailable;
        product.UpdatedAt = DateTime.UtcNow;

        UnitOfWork.Products.Update(product);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(
            new { },
            LocalizationService.GetLocalizedString(ResourceName, "ProductAvailabilityUpdatedSuccessfully",
                CurrentCulture)));
    }

    /// <summary>
    /// Ürün fiyatını günceller
    /// </summary>
    /// <param name="id">Ürün ID'si</param>
    /// <param name="dto">Fiyat bilgisi</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{id}/price")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateProductPrice(Guid id, UpdateProductPriceDto dto)
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "VendorNotFoundForUser", CurrentCulture),
                "VENDOR_NOT_FOUND"));
        }

        var product = await UnitOfWork.Products.Query()
            .FirstOrDefaultAsync(p => p.Id == id && p.VendorId == vendorId.Value);

        if (product == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "ProductNotFoundOrNoUpdateAccess", CurrentCulture),
                "PRODUCT_NOT_FOUND"));
        }

        product.Price = dto.Price;
        product.UpdatedAt = DateTime.UtcNow;

        UnitOfWork.Products.Update(product);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(
            new { },
            LocalizationService.GetLocalizedString(ResourceName, "ProductPriceUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Satıcının ürün kategorilerini getirir
    /// </summary>
    /// <returns>Kategori listesi</returns>
    [HttpGet("categories")]
    public async Task<ActionResult<ApiResponse<List<string>>>> GetCategories()
    {
        var vendorId = await GetVendorIdAsync();
        if (vendorId == null)
        {
            return NotFound(new ApiResponse<List<string>>(
                LocalizationService.GetLocalizedString(ResourceName, "VendorNotFoundForUser", CurrentCulture),
                "VENDOR_NOT_FOUND"));
        }

        var categories = await UnitOfWork.Products.Query()
            .Where(p => p.VendorId == vendorId.Value && p.Category != null)
            .Select(p => p.Category!)
            .Distinct()
            .OrderBy(c => c)
            .ToListAsync();

        return Ok(new ApiResponse<List<string>>(
            categories,
            LocalizationService.GetLocalizedString(ResourceName, "CategoriesRetrievedSuccessfully", CurrentCulture)));
    }
}
