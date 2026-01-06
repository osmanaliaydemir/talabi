using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Helpers;
using System.Globalization;
using Talabi.Core.Enums;

namespace Talabi.Portal.Services;

public class ProductService : IProductService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IUserContextService _userContextService;
    private readonly ILogger<ProductService> _logger;

    public ProductService(
        IUnitOfWork unitOfWork,
        IUserContextService userContextService,
        ILogger<ProductService> logger)
    {
        _unitOfWork = unitOfWork;
        _userContextService = userContextService;
        _logger = logger;
    }

    private async Task<Guid?> GetVendorIdAsync(CancellationToken ct)
    {
        var userId = _userContextService.GetUserId();
        if (string.IsNullOrEmpty(userId)) return null;

        var vendor = await _unitOfWork.Vendors.Query()
            .Select(v => new { v.Id, v.OwnerId })
            .FirstOrDefaultAsync(v => v.OwnerId == userId, ct);

        return vendor?.Id;
    }

    public async Task<PagedResultDto<VendorProductDto>?> GetProductsAsync(int page = 1, int pageSize = 10,
        string? category = null, bool? isAvailable = null, string? search = null, string? sortBy = null,
        string sortOrder = "desc", CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return null;

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 10;

            var query = _unitOfWork.Products.Query()
                .Where(p => p.VendorId == vendorId.Value);

            if (!string.IsNullOrWhiteSpace(category))
                query = query.Where(p => p.Category == category);

            if (isAvailable.HasValue)
                query = query.Where(p => p.IsAvailable == isAvailable.Value);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var searchLower = search.ToLower();
                query = query.Where(p => p.Name.ToLower().Contains(searchLower) ||
                                         (p.Description != null && p.Description.ToLower().Contains(searchLower)));
            }

            IOrderedQueryable<Product> orderedQuery;

            if (string.IsNullOrEmpty(sortBy))
            {
                orderedQuery = query.OrderByDescending(p => p.CreatedAt);
            }
            else
            {
                var isAsc = sortOrder.Equals("asc", StringComparison.OrdinalIgnoreCase);
                orderedQuery = sortBy.ToLower() switch
                {
                    "name" => isAsc ? query.OrderBy(p => p.Name) : query.OrderByDescending(p => p.Name),
                    "price" => isAsc ? query.OrderBy(p => p.Price) : query.OrderByDescending(p => p.Price),
                    "stock" => isAsc ? query.OrderBy(p => p.Stock) : query.OrderByDescending(p => p.Stock),
                    "category" => isAsc ? query.OrderBy(p => p.Category) : query.OrderByDescending(p => p.Category),
                    "isavailable" => isAsc
                        ? query.OrderBy(p => p.IsAvailable)
                        : query.OrderByDescending(p => p.IsAvailable),
                    _ => query.OrderByDescending(p => p.CreatedAt)
                };
            }

            var totalCount = await query.LongCountAsync(ct);
            var items = await orderedQuery
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(p => new VendorProductDto
                {
                    Id = p.Id,
                    VendorId = p.VendorId,
                    Name = p.Name,
                    Description = p.Description,
                    Category = p.Category,
                    Price = p.Price,
                    Currency = p.Currency.ToString(),
                    ImageUrl = p.ImageUrl,
                    IsAvailable = p.IsAvailable,
                    Stock = p.Stock,
                    PreparationTime = p.PreparationTime,
                    CreatedAt = p.CreatedAt,
                    UpdatedAt = p.UpdatedAt
                })
                .ToListAsync(ct);

            return new PagedResultDto<VendorProductDto>
            {
                Items = items,
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting products");
            return null;
        }
    }

    public async Task<VendorProductDto?> GetProductAsync(Guid id, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return null;

            return await _unitOfWork.Products.Query()
                .Where(p => p.Id == id && p.VendorId == vendorId.Value)
                .Include(p => p.OptionGroups)
                .ThenInclude(g => g.Options)
                .Select(p => new VendorProductDto
                {
                    Id = p.Id,
                    VendorId = p.VendorId,
                    Name = p.Name,
                    Description = p.Description,
                    Category = p.Category,
                    Price = p.Price,
                    Currency = p.Currency.ToString(),
                    ImageUrl = p.ImageUrl,
                    IsAvailable = p.IsAvailable,
                    Stock = p.Stock,
                    PreparationTime = p.PreparationTime,
                    CreatedAt = p.CreatedAt,
                    UpdatedAt = p.UpdatedAt,
                    OptionGroups = p.OptionGroups.Select(g => new ProductOptionGroupDto
                    {
                        Id = g.Id,
                        Name = g.Name,
                        IsRequired = g.IsRequired,
                        AllowMultiple = g.AllowMultiple,
                        MinSelection = g.MinSelection,
                        MaxSelection = g.MaxSelection,
                        DisplayOrder = g.DisplayOrder,
                        Options = g.Options.Select(o => new ProductOptionValueDto
                        {
                            Id = o.Id,
                            Name = o.Name,
                            PriceAdjustment = o.PriceAdjustment,
                            IsDefault = o.IsDefault,
                            DisplayOrder = o.DisplayOrder
                        }).OrderBy(o => o.DisplayOrder).ToList()
                    }).OrderBy(g => g.DisplayOrder).ToList()
                })
                .FirstOrDefaultAsync(ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting product {ProductId}", id);
            return null;
        }
    }

    public async Task<bool> CreateProductAsync(CreateProductDto dto, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return false;

            var product = new Product
            {
                VendorId = vendorId.Value,
                Name = dto.Name,
                Description = dto.Description,
                Category = dto.Category,
                CategoryId = dto.CategoryId,
                Price = dto.Price,
                Currency = Enum.TryParse<Currency>(dto.Currency, out var currency) ? currency : Currency.TRY,
                ImageUrl = dto.ImageUrl,
                IsAvailable = dto.IsAvailable,
                Stock = dto.Stock,
                PreparationTime = dto.PreparationTime,
                OptionGroups = dto.OptionGroups?.Select((g, i) => new ProductOptionGroup
                {
                    Name = g.Name,
                    IsRequired = g.IsRequired,
                    AllowMultiple = g.AllowMultiple,
                    MinSelection = g.MinSelection,
                    MaxSelection = g.MaxSelection,
                    DisplayOrder = g.DisplayOrder == 0 ? i : g.DisplayOrder,
                    Options = g.Options?.Select((o, j) => new ProductOptionValue
                    {
                        Name = o.Name,
                        PriceAdjustment = o.PriceAdjustment,
                        IsDefault = o.IsDefault,
                        DisplayOrder = o.DisplayOrder == 0 ? j : o.DisplayOrder
                    }).ToList() ?? new List<ProductOptionValue>()
                }).ToList() ?? new List<ProductOptionGroup>()
            };

            await _unitOfWork.Products.AddAsync(product);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating product");
            return false;
        }
    }

    public async Task<bool> UpdateProductAsync(Guid id, UpdateProductDto dto, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return false;

            var product = await _unitOfWork.Products.Query()
                .Include(p => p.OptionGroups)
                .ThenInclude(g => g.Options)
                .FirstOrDefaultAsync(p => p.Id == id && p.VendorId == vendorId.Value, ct);

            if (product == null) return false;

            if (dto.Name != null) product.Name = dto.Name;
            if (dto.Description != null) product.Description = dto.Description;
            if (dto.Category != null) product.Category = dto.Category;
            if (dto.CategoryId.HasValue) product.CategoryId = dto.CategoryId.Value;
            if (dto.Price.HasValue) product.Price = dto.Price.Value;
            if (!string.IsNullOrEmpty(dto.Currency) && Enum.TryParse<Currency>(dto.Currency, out var currency))
                product.Currency = currency;
            if (dto.ImageUrl != null) product.ImageUrl = dto.ImageUrl;
            if (dto.IsAvailable.HasValue) product.IsAvailable = dto.IsAvailable.Value;
            if (dto.Stock.HasValue) product.Stock = dto.Stock;
            if (dto.PreparationTime.HasValue) product.PreparationTime = dto.PreparationTime;

            if (dto.OptionGroups != null)
            {
                product.OptionGroups.Clear();
                foreach (var gDto in dto.OptionGroups)
                {
                    product.OptionGroups.Add(new ProductOptionGroup
                    {
                        Name = gDto.Name,
                        IsRequired = gDto.IsRequired,
                        AllowMultiple = gDto.AllowMultiple,
                        MinSelection = gDto.MinSelection,
                        MaxSelection = gDto.MaxSelection,
                        DisplayOrder = gDto.DisplayOrder,
                        Options = gDto.Options?.Select(o => new ProductOptionValue
                        {
                            Name = o.Name,
                            PriceAdjustment = o.PriceAdjustment,
                            IsDefault = o.IsDefault,
                            DisplayOrder = o.DisplayOrder
                        }).ToList() ?? new List<ProductOptionValue>()
                    });
                }
            }

            product.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Products.Update(product);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating product {ProductId}", id);
            return false;
        }
    }

    public async Task<bool> DeleteProductAsync(Guid id, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return false;

            var product = await _unitOfWork.Products.Query()
                .FirstOrDefaultAsync(p => p.Id == id && p.VendorId == vendorId.Value, ct);

            if (product == null) return false;

            _unitOfWork.Products.Remove(product);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting product {ProductId}", id);
            return false;
        }
    }

    public async Task<bool> UpdateAvailabilityAsync(Guid id, bool isAvailable, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return false;

            var product = await _unitOfWork.Products.Query()
                .FirstOrDefaultAsync(p => p.Id == id && p.VendorId == vendorId.Value, ct);

            if (product == null) return false;

            product.IsAvailable = isAvailable;
            product.UpdatedAt = DateTime.UtcNow;

            _unitOfWork.Products.Update(product);
            await _unitOfWork.SaveChangesAsync();
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating availability for product {ProductId}", id);
            return false;
        }
    }

    public async Task<List<string>> GetCategoriesAsync(CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return new List<string>();

            return await _unitOfWork.Products.Query()
                .Where(p => p.VendorId == vendorId.Value && p.Category != null)
                .Select(p => p.Category!)
                .Distinct()
                .OrderBy(c => c)
                .ToListAsync(ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting categories");
            return new List<string>();
        }
    }
}
