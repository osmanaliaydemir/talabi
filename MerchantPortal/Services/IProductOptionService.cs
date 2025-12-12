using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IProductOptionService
{
	Task<PagedResult<ProductOptionGroupResponse>?> GetGroupsAsync(Guid productId, int page = 1, int pageSize = 20, CancellationToken ct = default);
	Task<ProductOptionGroupResponse?> GetGroupAsync(Guid id, CancellationToken ct = default);
	Task<ProductOptionGroupResponse?> CreateGroupAsync(CreateProductOptionGroupRequest request, CancellationToken ct = default);
	Task<ProductOptionGroupResponse?> UpdateGroupAsync(Guid id, UpdateProductOptionGroupRequest request, CancellationToken ct = default);
	Task<bool> DeleteGroupAsync(Guid id, CancellationToken ct = default);
	Task<bool> ReorderGroupsAsync(Guid productId, List<Guid> orderedGroupIds, CancellationToken ct = default);

	Task<PagedResult<ProductOptionResponse>?> GetOptionsAsync(Guid productOptionGroupId, int page = 1, int pageSize = 20, CancellationToken ct = default);
	Task<ProductOptionResponse?> GetOptionAsync(Guid id, CancellationToken ct = default);
	Task<ProductOptionResponse?> CreateOptionAsync(CreateProductOptionRequest request, CancellationToken ct = default);
	Task<ProductOptionResponse?> UpdateOptionAsync(Guid id, UpdateProductOptionRequest request, CancellationToken ct = default);
	Task<bool> DeleteOptionAsync(Guid id, CancellationToken ct = default);
	Task<bool> BulkCreateOptionsAsync(BulkCreateProductOptionsRequest request, CancellationToken ct = default);
	Task<bool> BulkUpdateOptionsAsync(BulkUpdateProductOptionsRequest request, CancellationToken ct = default);
}


