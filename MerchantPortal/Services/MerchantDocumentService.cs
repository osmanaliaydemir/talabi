using System.Net.Http.Headers;
using System.Net.Http.Json;
using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class MerchantDocumentService : IMerchantDocumentService
{
	private readonly HttpClient _httpClient;
	private readonly IApiClient _apiClient;
	private readonly ILogger<MerchantDocumentService> _logger;

	public MerchantDocumentService(HttpClient httpClient, IApiClient apiClient, ILogger<MerchantDocumentService> logger)
	{
		_httpClient = httpClient;
		_apiClient = apiClient;
		_logger = logger;
	}

	public async Task<PagedResult<MerchantDocumentResponse>?> GetDocumentsAsync(Guid? merchantId = null, string? documentType = null, string? status = null, int page = 1, int pageSize = 20, CancellationToken ct = default)
	{
		var qs = new List<string> { $"page={page}", $"pageSize={pageSize}" };
		if (merchantId.HasValue) qs.Add($"merchantId={merchantId}");
		if (!string.IsNullOrWhiteSpace(documentType)) qs.Add($"documentType={documentType}");
		if (!string.IsNullOrWhiteSpace(status)) qs.Add($"status={status}");
		var url = "api/merchantdocument" + (qs.Count > 0 ? ("?" + string.Join("&", qs)) : string.Empty);
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<PagedResult<MerchantDocumentResponse>>>(url, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting merchant documents");
			return null;
		}
	}

	public async Task<PagedResult<MerchantDocumentResponse>?> GetPendingDocumentsAsync(int page = 1, int pageSize = 20, CancellationToken ct = default)
	{
		var url = $"api/merchantdocument/pending?page={page}&pageSize={pageSize}";
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<PagedResult<MerchantDocumentResponse>>>(url, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting pending merchant documents");
			return null;
		}
	}

	public async Task<MerchantDocumentResponse?> GetDocumentAsync(Guid documentId, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<MerchantDocumentResponse>>($"api/merchantdocument/{documentId}", ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting document detail {DocumentId}", documentId);
			return null;
		}
	}

	public async Task<DocumentDownloadResult?> DownloadAsync(Guid documentId, CancellationToken ct = default)
	{
		try
		{
			using var response = await _httpClient.GetAsync($"api/merchantdocument/{documentId}/download", ct);
			if (!response.IsSuccessStatusCode)
			{
				var error = await response.Content.ReadAsStringAsync(ct);
				_logger.LogWarning("Document download failed for {DocumentId} - {StatusCode} {Message}", documentId, response.StatusCode, error);
				return null;
			}

			var bytes = await response.Content.ReadAsByteArrayAsync(ct);
			var contentType = response.Content.Headers.ContentType?.MediaType ?? "application/octet-stream";
			var fileName = response.Content.Headers.ContentDisposition?.FileName?.Trim('\"') ?? $"document_{documentId}";

			return new DocumentDownloadResult
			{
				Content = bytes,
				ContentType = contentType,
				FileName = fileName
			};
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error downloading document {DocumentId}", documentId);
			return null;
		}
	}

	public async Task<MerchantDocumentProgressResponse?> GetProgressAsync(Guid merchantId, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<MerchantDocumentProgressResponse>>($"api/merchantdocument/progress/{merchantId}", ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting document progress for merchant {MerchantId}", merchantId);
			return null;
		}
	}

	public async Task<IReadOnlyList<DocumentTypeResponse>?> GetRequiredTypesAsync(CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<List<DocumentTypeResponse>>>("api/merchantdocument/required-types", ct);
			return res?.Data ?? new List<DocumentTypeResponse>();
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting required document types");
			return null;
		}
	}

	public async Task<MerchantDocumentStatisticsResponse?> GetStatisticsAsync(Guid? merchantId = null, CancellationToken ct = default)
	{
		var url = "api/merchantdocument/statistics";
		if (merchantId.HasValue)
		{
			url += $"?merchantId={merchantId}";
		}

		try
		{
			var res = await _apiClient.GetAsync<ApiResponse<MerchantDocumentStatisticsResponse>>(url, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error getting document statistics");
			return null;
		}
	}

	public async Task<MerchantDocumentResponse?> VerifyDocumentAsync(Guid documentId, VerifyMerchantDocumentRequest request, CancellationToken ct = default)
	{
		try
		{
			request.DocumentId = documentId;
			var res = await _apiClient.PostAsync<ApiResponse<MerchantDocumentResponse>>($"api/merchantdocument/{documentId}/verify", request, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error verifying document {DocumentId}", documentId);
			return null;
		}
	}

	public async Task<BulkVerifyDocumentsResponse?> BulkVerifyDocumentsAsync(BulkVerifyDocumentsRequest request, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.PostAsync<ApiResponse<BulkVerifyDocumentsResponse>>("api/merchantdocument/bulk-verify", request, ct);
			return res?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error bulk verifying documents");
			return null;
		}
	}

	public async Task<MerchantDocumentResponse?> UploadAsync(UploadMerchantDocumentRequest request, IFormFile file, CancellationToken ct = default)
	{
		try
		{
			using var content = new MultipartFormDataContent();
			content.Add(new StringContent(request.MerchantId.ToString()), nameof(UploadMerchantDocumentRequest.MerchantId));
			content.Add(new StringContent(request.DocumentType), nameof(UploadMerchantDocumentRequest.DocumentType));
			if (!string.IsNullOrWhiteSpace(request.Notes)) content.Add(new StringContent(request.Notes), nameof(UploadMerchantDocumentRequest.Notes));

			var fileContent = new StreamContent(file.OpenReadStream());
			fileContent.Headers.ContentType = new MediaTypeHeaderValue(file.ContentType);
			content.Add(fileContent, "file", file.FileName);

			var response = await _httpClient.PostAsync("api/merchantdocument/upload", content, ct);
			if (!response.IsSuccessStatusCode) return null;
			var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<MerchantDocumentResponse>>(cancellationToken: ct);
			return apiResponse?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error uploading merchant document");
			return null;
		}
	}

	public async Task<bool> DeleteAsync(Guid documentId, CancellationToken ct = default)
	{
		try
		{
			var res = await _apiClient.DeleteAsync($"api/merchantdocument/{documentId}", ct);
			return res;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error deleting merchant document {DocumentId}", documentId);
			return false;
		}
	}
}


