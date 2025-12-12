using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IRateLimitAdminService
{
    Task<List<RateLimitRuleResponse>> GetRulesAsync(CancellationToken ct = default);
    Task<bool> EnableRuleAsync(Guid ruleId, CancellationToken ct = default);
    Task<bool> DisableRuleAsync(Guid ruleId, CancellationToken ct = default);
    Task<RateLimitSearchResponseModel?> SearchLogsAsync(RateLimitSearchRequestModel request, CancellationToken ct = default);
    Task<RateLimitCheckResponseModel?> GetStatusAsync(string endpoint, string httpMethod, CancellationToken ct = default);
}

