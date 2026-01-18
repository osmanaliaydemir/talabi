using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Helpers;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Portal.Services;

public class CourierService : ICourierService
{
    private readonly IRepository<Courier> _courierRepository;
    private readonly IUnitOfWork _unitOfWork;

    public CourierService(IRepository<Courier> courierRepository, IUnitOfWork unitOfWork)
    {
        _courierRepository = courierRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<PagedResult<CourierListDto>> GetCouriersAsync(int page, int pageSize, string? search, string? sortColumn, string? sortDirection)
    {
        var query = _courierRepository.Query()
            .Include(c => c.User)
            .AsNoTracking()
            .AsQueryable();

        if (!string.IsNullOrEmpty(search))
        {
            search = search.ToLower();
            query = query.Where(c => 
                c.Name.ToLower().Contains(search) || 
                (c.User != null && c.User.Email!.ToLower().Contains(search)) ||
                (c.PhoneNumber != null && c.PhoneNumber.Contains(search))
            );
        }

        // Sorting
        query = sortColumn switch
        {
            "name" => sortDirection == "desc" ? query.OrderByDescending(c => c.Name) : query.OrderBy(c => c.Name),
            "vehicleType" => sortDirection == "desc" ? query.OrderByDescending(c => c.VehicleType) : query.OrderBy(c => c.VehicleType),
            "email" => sortDirection == "desc" ? query.OrderByDescending(c => c.User!.Email) : query.OrderBy(c => c.User!.Email),
            "isActive" => sortDirection == "desc" ? query.OrderByDescending(c => c.IsActive) : query.OrderBy(c => c.IsActive),
            "createdDate" => sortDirection == "desc" ? query.OrderByDescending(c => c.CreatedAt) : query.OrderBy(c => c.CreatedAt),
            _ => query.OrderByDescending(c => c.CreatedAt) 
        };

        var totalCount = await query.CountAsync();
        var items = await query.Skip((page - 1) * pageSize).Take(pageSize)
            .Select(c => new CourierListDto
            {
                Id = c.Id.ToString(),
                Name = c.Name,
                Email = c.User != null ? (c.User.Email ?? string.Empty) : string.Empty,
                PhoneNumber = c.PhoneNumber,
                VehicleType = c.VehicleType.ToString(),
                IsActive = c.IsActive,
                CreatedDate = c.CreatedAt,
                Status = c.Status.ToString()
            })
            .ToListAsync();

        return new PagedResult<CourierListDto>
        {
            Items = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<CourierDetailDto?> GetCourierByIdAsync(string id)
    {
        if (!Guid.TryParse(id, out var guidId)) return null;

        var courier = await _courierRepository.Query()
            .Include(c => c.User)
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == guidId);

        if (courier == null) return null;

        return new CourierDetailDto
        {
            Id = courier.Id.ToString(),
            Name = courier.Name,
            Email = courier.User?.Email ?? string.Empty,
            PhoneNumber = courier.PhoneNumber,
            VehicleType = courier.VehicleType.ToString(),
            IsActive = courier.IsActive,
            CreatedDate = courier.CreatedAt,
            Status = courier.Status.ToString(),
            TotalDeliveries = courier.TotalDeliveries,
            AverageRating = courier.AverageRating,
            TotalEarnings = courier.TotalEarnings
        };
    }

    public async Task<bool> UpdateCourierStatusAsync(string id, bool isActive)
    {
        if (!Guid.TryParse(id, out var guidId)) return false;

        var courier = await _courierRepository.GetByIdAsync(guidId);
        if (courier == null) return false;

        courier.IsActive = isActive;
        _courierRepository.Update(courier);
        await _unitOfWork.SaveChangesAsync();

        return true;
    }

    public async Task<bool> ApproveCourierAsync(string id)
    {
        return await UpdateCourierStatusAsync(id, true);
    }

    public async Task<bool> RejectCourierAsync(string id)
    {
        return await UpdateCourierStatusAsync(id, false);
    }
}
