using System.Net.Http.Headers;
using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class FileService : IFileService
{
	private readonly HttpClient _httpClient;
	private readonly ILogger<FileService> _logger;

	public FileService(HttpClient httpClient, ILogger<FileService> logger)
	{
		_httpClient = httpClient;
		_logger = logger;
	}

	public async Task<FileUploadResponse?> UploadMerchantFileAsync(Stream stream, string fileName, string contentType, CancellationToken ct = default)
	{
		try
		{
			using var content = new MultipartFormDataContent();
			var fileContent = new StreamContent(stream);
			fileContent.Headers.ContentType = new MediaTypeHeaderValue(contentType);
			content.Add(fileContent, "file", fileName);

			var response = await _httpClient.PostAsync("api/v1/files/merchant/upload", content, ct);
			if (!response.IsSuccessStatusCode)
				return null;

			var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<FileUploadResponse>>(cancellationToken: ct);
			return apiResponse?.Data;
		}
		catch (Exception ex)
		{
			_logger.LogError(ex, "Error uploading file {FileName}", fileName);
			return null;
		}
	}
}


