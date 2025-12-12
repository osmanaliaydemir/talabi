using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Threading;
using System.Threading.Tasks;
using Getir.MerchantPortal.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace Getir.MerchantPortal.Services;

public class FileManagerService : IFileManagerService
{
    private readonly HttpClient _httpClient;
    private readonly IApiClient _apiClient;
    private readonly ILogger<FileManagerService> _logger;

    public FileManagerService(HttpClient httpClient, IApiClient apiClient, ILogger<FileManagerService> logger)
    {
        _httpClient = httpClient;
        _apiClient = apiClient;
        _logger = logger;
    }

    public async Task<PagedResult<FileUploadResponse>?> GetMerchantFilesAsync(int page, int pageSize, CancellationToken ct = default)
    {
        try
        {
            var endpoint = $"api/v1/files/merchant?page={page}&pageSize={pageSize}";
            var response = await _apiClient.GetAsync<ApiResponse<PagedResult<FileUploadResponse>>>(endpoint, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching merchant files");
            return null;
        }
    }

    public async Task<FileUploadResponse?> UploadMerchantFileAsync(IFormFile file, CancellationToken ct = default)
    {
        try
        {
            using var content = new MultipartFormDataContent();
            await using var stream = file.OpenReadStream();
            var fileContent = new StreamContent(stream);
            fileContent.Headers.ContentType = new MediaTypeHeaderValue(file.ContentType);
            content.Add(fileContent, "file", file.FileName);

            var response = await _httpClient.PostAsync("api/v1/files/merchant/upload", content, ct);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Failed to upload merchant file: {StatusCode}", response.StatusCode);
                return null;
            }

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<FileUploadResponse>>();
            return apiResponse?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading merchant file");
            return null;
        }
    }

    public async Task<bool> DeleteMerchantFileAsync(string containerName, string fileName, CancellationToken ct = default)
    {
        try
        {
            var endpoint = $"api/v1/files/merchant/{containerName}/{fileName}";
            var response = await _httpClient.DeleteAsync(endpoint, ct);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting merchant file {FileName} from {Container}", fileName, containerName);
            return false;
        }
    }
}

