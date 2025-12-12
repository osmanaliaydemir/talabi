using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public class ReviewService : IReviewService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IUserContextService _userContextService;
    private readonly ILogger<ReviewService> _logger;

    public ReviewService(
        IUnitOfWork unitOfWork,
        IUserContextService userContextService,
        ILogger<ReviewService> logger)
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

    public async Task<PagedResultDto<VendorReviewDto>?> GetReviewsAsync(int page = 1, int pageSize = 10, int? rating = null, 
        string? search = null, string? sortBy = null, string sortOrder = "desc", CancellationToken ct = default)
    {
        try
        {
            var vendorId = await GetVendorIdAsync(ct);
            if (vendorId == null) return null;

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 10;

            var query = _unitOfWork.Reviews.Query()
                .Include(r => r.User)
                .Include(r => r.Product)
                .Where(r => r.VendorId == vendorId.Value);

            if (rating.HasValue)
                query = query.Where(r => r.Rating == rating.Value);

            if (!string.IsNullOrWhiteSpace(search))
            {
                var searchLower = search.ToLower();
                query = query.Where(r => r.Comment.ToLower().Contains(searchLower) ||
                                         (r.User != null && (r.User.FullName).ToLower().Contains(searchLower)) ||
                                         (r.Product != null && r.Product.Name.ToLower().Contains(searchLower)));
            }

            IOrderedQueryable<Review> orderedQuery;

            if (string.IsNullOrEmpty(sortBy))
            {
                orderedQuery = query.OrderByDescending(r => r.CreatedAt);
            }
            else
            {
                var isAsc = sortOrder.Equals("asc", StringComparison.OrdinalIgnoreCase);
                orderedQuery = sortBy.ToLower() switch
                {
                    "rating" => isAsc ? query.OrderBy(r => r.Rating) : query.OrderByDescending(r => r.Rating),
                    "date" => isAsc ? query.OrderBy(r => r.CreatedAt) : query.OrderByDescending(r => r.CreatedAt),
                    "customername" => isAsc ? query.OrderBy(r => r.User != null ? r.User.FullName : "") : query.OrderByDescending(r => r.User != null ? r.User.FullName : ""),
                    "productname" => isAsc ? query.OrderBy(r => r.Product != null ? r.Product.Name : "") : query.OrderByDescending(r => r.Product != null ? r.Product.Name : ""),
                    _ => query.OrderByDescending(r => r.CreatedAt)
                };
            }

            var totalCount = await query.LongCountAsync(ct);
            var items = await orderedQuery
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(r => new VendorReviewDto
                {
                    Id = r.Id,
                    CustomerName = r.User != null ? (r.User.FullName) : "Anonymous",
                    ProductName = r.Product != null ? r.Product.Name : null,
                    Rating = r.Rating,
                    Comment = r.Comment,
                    IsApproved = r.IsApproved,
                    CreatedAt = r.CreatedAt
                })
                .ToListAsync(ct);

            return new PagedResultDto<VendorReviewDto>
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
            _logger.LogError(ex, "Error getting reviews");
            return null;
        }
    }
}
