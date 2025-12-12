using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface ICouponService
{
	Task<CouponValidationResponse?> ValidateAsync(ValidateCouponRequest request, CancellationToken ct = default);
	Task<CouponResponse?> CreateAsync(CreateCouponRequest request, CancellationToken ct = default);
	Task<PagedResult<CouponResponse>?> GetCouponsAsync(int page = 1, int pageSize = 20, CancellationToken ct = default);
}


