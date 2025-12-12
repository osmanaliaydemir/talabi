using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class CampaignService : ICampaignService
{
	private readonly IApiClient _apiClient;
	private readonly ILogger<CampaignService> _logger;

	public CampaignService(IApiClient apiClient, ILogger<CampaignService> logger)
	{
		_apiClient = apiClient;
		_logger = logger;
	}

	public async Task<PagedResult<CampaignResponse>?> GetActiveCampaignsAsync(
		int page = 1,
		int pageSize = 20,
		CancellationToken ct = default)
	{
		try
		{
			var endpoint = $"api/v1/campaign?page={page}&pageSize={pageSize}";
			var response = await _apiClient.GetAsync<ApiResponse<PagedResult<CampaignResponse>>>(endpoint, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error fetching active campaigns");
			return null;
		}
	}
}


