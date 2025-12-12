using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IMerchantDocumentService
{
	Task<PagedResult<MerchantDocumentResponse>?> GetDocumentsAsync(Guid? merchantId = null, string? documentType = null, string? status = null, int page = 1, int pageSize = 20, CancellationToken ct = default);
	Task<PagedResult<MerchantDocumentResponse>?> GetPendingDocumentsAsync(int page = 1, int pageSize = 20, CancellationToken ct = default);
	Task<MerchantDocumentResponse?> GetDocumentAsync(Guid documentId, CancellationToken ct = default);
	Task<DocumentDownloadResult?> DownloadAsync(Guid documentId, CancellationToken ct = default);
	Task<MerchantDocumentProgressResponse?> GetProgressAsync(Guid merchantId, CancellationToken ct = default);
	Task<IReadOnlyList<DocumentTypeResponse>?> GetRequiredTypesAsync(CancellationToken ct = default);
	Task<MerchantDocumentStatisticsResponse?> GetStatisticsAsync(Guid? merchantId = null, CancellationToken ct = default);
	Task<MerchantDocumentResponse?> VerifyDocumentAsync(Guid documentId, VerifyMerchantDocumentRequest request, CancellationToken ct = default);
	Task<BulkVerifyDocumentsResponse?> BulkVerifyDocumentsAsync(BulkVerifyDocumentsRequest request, CancellationToken ct = default);
	Task<MerchantDocumentResponse?> UploadAsync(UploadMerchantDocumentRequest request, IFormFile file, CancellationToken ct = default);
	Task<bool> DeleteAsync(Guid documentId, CancellationToken ct = default);
}


