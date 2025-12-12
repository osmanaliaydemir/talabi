using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface ICampaignService
{
	Task<PagedResult<CampaignResponse>?> GetActiveCampaignsAsync(
		int page = 1,
		int pageSize = 20,
		CancellationToken ct = default);
}


