using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

public interface IReviewService
{
    Task<PagedResultDto<VendorReviewDto>?> GetReviewsAsync(int page = 1, int pageSize = 10, int? rating = null, 
        string? search = null, string? sortBy = null, string sortOrder = "desc", CancellationToken ct = default);

    // Maybe Approval?
    // Task<bool> ApproveReviewAsync(Guid id, bool isApproved, CancellationToken ct = default);
}
