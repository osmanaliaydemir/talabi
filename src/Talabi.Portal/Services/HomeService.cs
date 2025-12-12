using Talabi.Core.Interfaces;
using Talabi.Portal.Models;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Portal.Services;

public class HomeService : IHomeService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IUserContextService _userContextService;
    private readonly ILogger<HomeService> _logger;

    public HomeService(
        IUnitOfWork unitOfWork,
        IUserContextService userContextService,
        ILogger<HomeService> logger)
    {
        _unitOfWork = unitOfWork;
        _userContextService = userContextService;
        _logger = logger;
    }

    public async Task<VendorProfileDto?> GetProfileAsync(CancellationToken ct = default)
    {
        try
        {
            var userId = _userContextService.GetUserId();
            if (string.IsNullOrEmpty(userId)) return null;

            var vendor = await _unitOfWork.Vendors.Query()
                .FirstOrDefaultAsync(v => v.OwnerId == userId, ct);

            if (vendor == null) return null;

            return new VendorProfileDto
            {
                Id = vendor.Id,
                Name = vendor.Name,
                ImageUrl = vendor.ImageUrl,
                Address = vendor.Address,
                City = vendor.City,
                Latitude = vendor.Latitude ?? 0,
                Longitude = vendor.Longitude ?? 0,
                PhoneNumber = vendor.PhoneNumber,
                Description = vendor.Description,
                Rating = (double)(vendor.Rating ?? 0),
                RatingCount = vendor.RatingCount
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting vendor profile");
            return null;
        }
    }
}
