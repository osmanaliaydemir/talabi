using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class CouponService : ICouponService
{
	private readonly IApiClient _apiClient;
	private readonly ILogger<CouponService> _logger;

	public CouponService(IApiClient apiClient, ILogger<CouponService> logger)
	{
		_apiClient = apiClient;
		_logger = logger;
	}

	public async Task<CouponValidationResponse?> ValidateAsync(ValidateCouponRequest request, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PostAsync<ApiResponse<CouponValidationResponse>>(
				"api/v1/coupon/validate", request, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error validating coupon");
			return null;
		}
	}

	public async Task<CouponResponse?> CreateAsync(CreateCouponRequest request, CancellationToken ct = default)
	{
		try
		{
			var response = await _apiClient.PostAsync<ApiResponse<CouponResponse>>(
				"api/v1/coupon", request, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error creating coupon");
			return null;
		}
	}

	public async Task<PagedResult<CouponResponse>?> GetCouponsAsync(int page = 1, int pageSize = 20, CancellationToken ct = default)
	{
		try
		{
			var endpoint = $"api/v1/coupon?page={page}&pageSize={pageSize}";
			var response = await _apiClient.GetAsync<ApiResponse<PagedResult<CouponResponse>>>(endpoint, ct);
			return response?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error fetching coupons");
			return null;
		}
	}
}


