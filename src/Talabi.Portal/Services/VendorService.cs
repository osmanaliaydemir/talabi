using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;

using Talabi.Core.Helpers; // Added for PagedResult

namespace Talabi.Portal.Services;

public class VendorService(IRepository<Vendor> vendorRepository, IUnitOfWork unitOfWork) : IVendorService
{
    private readonly IRepository<Vendor> _vendorRepository = vendorRepository;
    private readonly IUnitOfWork _unitOfWork = unitOfWork;

    public async Task<PagedResult<VendorListDto>> GetVendorsAsync(int page, int pageSize, string? search, string? sortColumn, string? sortDirection)
    {
        var query = _vendorRepository.Query()
            .Include(v => v.Owner)
            .AsNoTracking()
            .AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            query = query.Where(v =>
                v.Name.Contains(search, StringComparison.OrdinalIgnoreCase) ||
                (v.Owner != null && v.Owner.Email!.Contains(search, StringComparison.OrdinalIgnoreCase)) ||
                (v.PhoneNumber != null && v.PhoneNumber.Contains(search, StringComparison.OrdinalIgnoreCase))
            );
        }

        // Sorting
        query = sortColumn switch
        {
            "name" => sortDirection == "desc" ? query.OrderByDescending(v => v.Name) : query.OrderBy(v => v.Name),
            "type" => sortDirection == "desc" ? query.OrderByDescending(v => v.Type) : query.OrderBy(v => v.Type),
            "email" => sortDirection == "desc" ? query.OrderByDescending(v => v.Owner!.Email) : query.OrderBy(v => v.Owner!.Email),
            "isActive" => sortDirection == "desc" ? query.OrderByDescending(v => v.IsActive) : query.OrderBy(v => v.IsActive),
            "createdDate" => sortDirection == "desc" ? query.OrderByDescending(v => v.CreatedAt) : query.OrderBy(v => v.CreatedAt),
            _ => query.OrderByDescending(v => v.CreatedAt)
        };

        var totalCount = await query.CountAsync();
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize)
            .Select(v => new VendorListDto
            {
                Id = v.Id.ToString(),
                Name = v.Name,
                Type = v.Type.ToString(),
                Email = v.Owner != null ? v.Owner.Email : "",
                PhoneNumber = v.PhoneNumber,
                IsActive = v.IsActive,
                CreatedDate = v.CreatedAt,
                ImageUrl = v.ImageUrl
            })
            .ToListAsync();

        return new PagedResult<VendorListDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<VendorDetailDto?> GetVendorByIdAsync(string id)
    {
        if (!Guid.TryParse(id, out var guidId)) return null;

        var vendor = await _vendorRepository.Query()
            .Include(v => v.Owner)
            .AsNoTracking()
            .FirstOrDefaultAsync(v => v.Id == guidId);

        if (vendor == null) return null;

        return new VendorDetailDto
        {
            Id = vendor.Id.ToString(),
            Name = vendor.Name,
            Description = vendor.Description,
            // ItemsDescription = vendor.ItemsDescription, // Entity doesn't have checks, skipping or mapping null
            Type = vendor.Type.ToString(),
            Email = vendor.Owner?.Email,
            PhoneNumber = vendor.PhoneNumber,
            Address = vendor.Address,
            City = vendor.City,
            Latitude = vendor.Latitude,
            Longitude = vendor.Longitude,
            IsActive = vendor.IsActive,
            ImageUrl = vendor.ImageUrl,
            // CoverImageUrl = vendor.CoverImageUrl, // Entity doesn't have checks, skipping or mapping null
            MinimumOrderAmount = vendor.MinimumOrderAmount,
            DeliveryTimeMinutes = vendor.EstimatedDeliveryTime, // Mapped from EstimatedDeliveryTime
            CreatedDate = vendor.CreatedAt
        };
    }

    public async Task<bool> UpdateVendorStatusAsync(string id, bool isActive)
    {
        if (!Guid.TryParse(id, out var guidId)) return false;

        var vendor = await _vendorRepository.GetByIdAsync(guidId);
        if (vendor == null) return false;

        vendor.IsActive = isActive;
        _vendorRepository.Update(vendor);
        await _unitOfWork.SaveChangesAsync();

        return true;
    }

    public async Task<bool> ApproveVendorAsync(string id)
    {
        return await UpdateVendorStatusAsync(id, true);
    }

    public async Task<bool> RejectVendorAsync(string id)
    {
        return await UpdateVendorStatusAsync(id, false);
    }
}
