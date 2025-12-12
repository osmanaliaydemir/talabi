using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class RateLimitAdminService : IRateLimitAdminService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<RateLimitAdminService> _logger;

    public RateLimitAdminService(IApiClient apiClient, ILogger<RateLimitAdminService> logger)
    {
        _apiClient = apiClient;
        _logger = logger;
    }

    public async Task<List<RateLimitRuleResponse>> GetRulesAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<List<RateLimitRuleResponse>>>("api/ratelimit/rules", ct);
            return response?.Data ?? new List<RateLimitRuleResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch rate limit rules");
            return new List<RateLimitRuleResponse>();
        }
    }

    public async Task<bool> EnableRuleAsync(Guid ruleId, CancellationToken ct = default)
    {
        try
        {
            var endpoint = $"api/ratelimit/rules/{ruleId}/enable";
        var response = await _apiClient.PostAsync<ApiResponse<object>>(endpoint, null, ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to enable rate limit rule {RuleId}", ruleId);
            return false;
        }
    }

    public async Task<bool> DisableRuleAsync(Guid ruleId, CancellationToken ct = default)
    {
        try
        {
            var endpoint = $"api/ratelimit/rules/{ruleId}/disable";
        var response = await _apiClient.PostAsync<ApiResponse<object>>(endpoint, null, ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to disable rate limit rule {RuleId}", ruleId);
            return false;
        }
    }

    public async Task<RateLimitSearchResponseModel?> SearchLogsAsync(RateLimitSearchRequestModel request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<RateLimitSearchResponseModel>>("api/ratelimit/logs/search", request, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to search rate limit logs");
            return null;
        }
    }

    public async Task<RateLimitCheckResponseModel?> GetStatusAsync(string endpoint, string httpMethod, CancellationToken ct = default)
    {
        try
        {
            var encodedEndpoint = Uri.EscapeDataString(endpoint);
            var encodedMethod = Uri.EscapeDataString(httpMethod);
            var url = $"api/ratelimit/status?endpoint={encodedEndpoint}&httpMethod={encodedMethod}";
            var response = await _apiClient.GetAsync<ApiResponse<RateLimitCheckResponseModel>>(url, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to fetch rate limit status for {Endpoint}", endpoint);
            return null;
        }
    }
}

