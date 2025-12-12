using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IMerchantOnboardingService
{
	Task<MerchantOnboardingResponse?> GetStatusAsync(Guid merchantId, CancellationToken ct = default);
	Task<OnboardingProgressResponse?> GetProgressAsync(Guid merchantId, CancellationToken ct = default);
	Task<List<OnboardingStepResponse>?> GetStepsAsync(Guid merchantId, CancellationToken ct = default);
	Task<bool> CompleteStepAsync(Guid merchantId, Guid stepId, CompleteOnboardingStepRequest request, CancellationToken ct = default);
	Task<bool> SubmitAsync(Guid merchantId, CancellationToken ct = default);
}


