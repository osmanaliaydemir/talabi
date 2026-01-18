using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;
using Talabi.Core.Helpers; // Added for PagedResult

namespace Talabi.Portal.Services;

public class VendorService : IVendorService
{
    private readonly IRepository<Vendor> _vendorRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IEmailService _emailService;
    private readonly ILogger<VendorService> _logger;

    public VendorService(
        IRepository<Vendor> vendorRepository,
        IUnitOfWork unitOfWork,
        IEmailService emailService,
        ILogger<VendorService> logger)
    {
        _vendorRepository = vendorRepository;
        _unitOfWork = unitOfWork;
        _emailService = emailService;
        _logger = logger;
    }

    public async Task<PagedResult<VendorListDto>> GetVendorsAsync(int page, int pageSize, string? search,
        string? sortColumn, string? sortDirection)
    {
        var query = _vendorRepository.Query()
            .Include(v => v.Owner)
            .AsNoTracking()
            .AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            search = search.ToLower();
            query = query.Where(v =>
                v.Name.ToLower().Contains(search) ||
                (v.Owner != null && v.Owner.Email!.ToLower().Contains(search)) ||
                (v.PhoneNumber != null && v.PhoneNumber.Contains(search))
            );
        }

        // Sorting
        query = sortColumn switch
        {
            "name" => sortDirection == "desc" ? query.OrderByDescending(v => v.Name) : query.OrderBy(v => v.Name),
            "type" => sortDirection == "desc" ? query.OrderByDescending(v => v.Type) : query.OrderBy(v => v.Type),
            "email" => sortDirection == "desc"
                ? query.OrderByDescending(v => v.Owner!.Email)
                : query.OrderBy(v => v.Owner!.Email),
            "isActive" => sortDirection == "desc"
                ? query.OrderByDescending(v => v.IsActive)
                : query.OrderBy(v => v.IsActive),
            "createdDate" => sortDirection == "desc"
                ? query.OrderByDescending(v => v.CreatedAt)
                : query.OrderBy(v => v.CreatedAt),
            _ => query.OrderByDescending(v => v.CreatedAt)
        };

        var totalCount = await query.CountAsync();
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize)
            .Select(v => new VendorListDto
            {
                Id = v.Id.ToString(),
                Name = v.Name,
                Type = v.Type.ToString(),
                CommissionRate = v.CommissionRate, // Map CommissionRate
                Email = v.Owner != null ? (v.Owner.Email ?? string.Empty) : string.Empty,
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
            CommissionRate = vendor.CommissionRate, // Map CommissionRate
            Email = vendor.Owner?.Email ?? string.Empty,
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
        if (!Guid.TryParse(id, out var guidId)) return false;

        var vendor = await _vendorRepository.Query()
            .Include(v => v.Owner)
            .FirstOrDefaultAsync(v => v.Id == guidId);

        if (vendor == null || vendor.Owner == null) return false;

        vendor.IsActive = true;
        _vendorRepository.Update(vendor);
        await _unitOfWork.SaveChangesAsync();

        // Get user language preference
        var userLanguage = await GetUserLanguageAsync(vendor.OwnerId);

        // Send approval email
        try
        {
            await _emailService.SendVendorApprovalEmailAsync(
                vendor.Owner.Email!,
                vendor.Name,
                userLanguage);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send approval email to vendor {VendorId}", id);
            // Don't fail the approval if email fails
        }

        return true;
    }

    public async Task<bool> RejectVendorAsync(string id)
    {
        if (!Guid.TryParse(id, out var guidId)) return false;

        var vendor = await _vendorRepository.Query()
            .Include(v => v.Owner)
            .FirstOrDefaultAsync(v => v.Id == guidId);

        if (vendor == null || vendor.Owner == null) return false;

        vendor.IsActive = false;
        _vendorRepository.Update(vendor);
        await _unitOfWork.SaveChangesAsync();

        // Get user language preference
        var userLanguage = await GetUserLanguageAsync(vendor.OwnerId);

        // Send rejection email
        try
        {
            await _emailService.SendVendorRejectionEmailAsync(
                vendor.Owner.Email!,
                vendor.Name,
                userLanguage);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send rejection email to vendor {VendorId}", id);
            // Don't fail the rejection if email fails
        }

        return true;
    }

    public async Task<bool> UpdateCommissionRateAsync(string id, decimal rate)
    {
        if (!Guid.TryParse(id, out var guidId)) return false;

        var vendor = await _vendorRepository.GetByIdAsync(guidId);
        if (vendor == null) return false;

        vendor.CommissionRate = rate;
        _vendorRepository.Update(vendor);
        await _unitOfWork.SaveChangesAsync();

        return true;
    }

    private async Task<string> GetUserLanguageAsync(string userId)
    {
        try
        {
            var userPreference = await _unitOfWork.UserPreferences.Query()
                .Where(up => up.UserId == userId)
                .Select(up => up.Language)
                .FirstOrDefaultAsync();

            // Return user's language preference or default to "en" if not found
            return !string.IsNullOrWhiteSpace(userPreference) ? userPreference : "en";
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to get user language preference for user {UserId}, defaulting to 'en'",
                userId);
            return "en"; // Default to English if we can't determine the language
        }
    }
}
