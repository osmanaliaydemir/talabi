using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public class CategoryService : ICategoryService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IUserContextService _userContextService;
    private readonly ILogger<CategoryService> _logger;

    public CategoryService(
        IUnitOfWork unitOfWork,
        IUserContextService userContextService,
        ILogger<CategoryService> logger)
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

    public async Task<PagedResultDto<VendorCategoryDto>?> GetCategoriesAsync(int page = 1, int pageSize = 10, 
        string? search = null, string? sortBy = null, string sortOrder = "asc", CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return null;

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 10;

            var baseQuery = _unitOfWork.Products.Query()
                .Where(p => p.VendorId == vendorId.Value && p.Category != null);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var searchLower = search.ToLower();
                baseQuery = baseQuery.Where(p => p.Category!.ToLower().Contains(searchLower));
            }

            var groupedQuery = baseQuery
                .GroupBy(p => p.Category!)
                .Select(g => new VendorCategoryDto
                {
                    Name = g.Key,
                    ProductCount = g.Count()
                });

            // Sorting (Must happen before Skip/Take, but after GroupBy)
            // Note: EF Core might evaluate GroupBy in memory if complex. 
            // VendorCategoryDto has Name and Count.
            
            if (string.IsNullOrEmpty(sortBy))
            {
                groupedQuery = groupedQuery.OrderBy(c => c.Name);
            }
            else
            {
                var isAsc = sortOrder.Equals("asc", StringComparison.OrdinalIgnoreCase);
                groupedQuery = sortBy.ToLower() switch
                {
                    "name" => isAsc ? groupedQuery.OrderBy(c => c.Name) : groupedQuery.OrderByDescending(c => c.Name),
                    "productcount" => isAsc ? groupedQuery.OrderBy(c => c.ProductCount) : groupedQuery.OrderByDescending(c => c.ProductCount),
                    _ => groupedQuery.OrderBy(c => c.Name)
                };
            }

            var totalCount = await groupedQuery.CountAsync(ct);
            var items = await groupedQuery
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(ct);

            return new PagedResultDto<VendorCategoryDto>
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
            _logger.LogError(ex, "Error getting categories");
            return null;
        }
    }

    public async Task<bool> UpdateCategoryAsync(string oldName, string newName, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return false;

            var products = await _unitOfWork.Products.Query()
                .Where(p => p.VendorId == vendorId.Value && p.Category == oldName)
                .ToListAsync(ct);

            if (!products.Any()) return false;

            foreach (var p in products)
            {
                p.Category = newName;
                p.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.Products.Update(p);
            }

            await _unitOfWork.SaveChangesAsync(ct);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating category {OldName} to {NewName}", oldName, newName);
            return false;
        }
    }

    public async Task<bool> DeleteCategoryAsync(string name, CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return false;

            var products = await _unitOfWork.Products.Query()
                .Where(p => p.VendorId == vendorId.Value && p.Category == name)
                .ToListAsync(ct);

             if (!products.Any()) return false;

            foreach (var p in products)
            {
                p.Category = null;
                p.UpdatedAt = DateTime.UtcNow;
                _unitOfWork.Products.Update(p);
            }

            await _unitOfWork.SaveChangesAsync(ct);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting category {Name}", name);
            return false;
        }
    }
}
