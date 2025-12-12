using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class MerchantOnboardingService : IMerchantOnboardingService
{
	private readonly IApiClient _apiClient;
	private readonly ILogger<MerchantOnboardingService> _logger;

	public MerchantOnboardingService(IApiClient apiClient, ILogger<MerchantOnboardingService> logger)
	{
		_apiClient = apiClient;
		_logger = logger;
	}

	public async Task<MerchantOnboardingResponse?> GetStatusAsync(Guid merchantId, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<MerchantOnboardingResponse>>($"api/v1/merchants/{merchantId}/merchantonboarding", ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting onboarding status");
			return null;
		}
	}

	public async Task<OnboardingProgressResponse?> GetProgressAsync(Guid merchantId, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<OnboardingProgressResponse>>($"api/v1/merchants/{merchantId}/merchantonboarding/progress", ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting onboarding progress");
			return null;
		}
	}

	public async Task<List<OnboardingStepResponse>?> GetStepsAsync(Guid merchantId, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<List<OnboardingStepResponse>>>($"api/v1/merchants/{merchantId}/merchantonboarding/steps", ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting onboarding steps");
			return null;
		}
	}

	public async Task<bool> CompleteStepAsync(Guid merchantId, Guid stepId, CompleteOnboardingStepRequest request, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.PostAsync<ApiResponse<object>>($"api/v1/merchants/{merchantId}/merchantonboarding/steps/{stepId}/complete", request, ct);
			return res?.isSuccess == true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error completing onboarding step {StepId}", stepId);
			return false;
		}
	}

	public async Task<bool> SubmitAsync(Guid merchantId, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.PostAsync<ApiResponse<object>>($"api/v1/merchants/{merchantId}/merchantonboarding/submit", null, ct);
			return res?.isSuccess == true;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error submitting onboarding");
			return false;
		}
	}
}


