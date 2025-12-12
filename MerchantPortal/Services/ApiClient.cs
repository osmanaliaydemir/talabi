using System.Net.Http.Headers;
using System.Text;
using Newtonsoft.Json;

namespace Getir.MerchantPortal.Services;

public class ApiClient : IApiClient
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ApiClient> _logger;
    private string? _authToken;
    
    // JSON serialization settings for consistent camelCase handling
    private static readonly JsonSerializerSettings JsonSettings = new()
    {
        ContractResolver = new Newtonsoft.Json.Serialization.CamelCasePropertyNamesContractResolver(),
        NullValueHandling = NullValueHandling.Ignore
    };

    /// <summary>
    /// ApiClient constructor
    /// </summary>
    /// <param name="httpClient">HTTP client</param>
    /// <param name="logger">Logger instance</param>
    public ApiClient(HttpClient httpClient, ILogger<ApiClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    /// <summary>
    /// Kimlik doğrulama token'ını ayarla
    /// </summary>
    /// <param name="token">JWT token</param>
    public void SetAuthToken(string token)
    {
        _authToken = token;
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
    }

    /// <summary>
    /// Kimlik doğrulama token'ını temizle
    /// </summary>
    public void ClearAuthToken()
    {
        _authToken = null;
        _httpClient.DefaultRequestHeaders.Authorization = null;
    }
    
    /// <summary>
    /// JSON içeriğini camelCase ile deserialize et
    /// </summary>
    /// <typeparam name="T">Dönüş tipi</typeparam>
    /// <param name="content">JSON içeriği</param>
    /// <returns>Deserialize edilmiş nesne</returns>
    private T? DeserializeResponse<T>(string content)
    {
        return JsonConvert.DeserializeObject<T>(content, JsonSettings);
    }

    /// <summary>
    /// GET isteği gönder
    /// </summary>
    /// <typeparam name="T">Dönüş tipi</typeparam>
    /// <param name="endpoint">API endpoint</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>API yanıtı</returns>
    public async Task<T?> GetAsync<T>(string endpoint, CancellationToken ct = default)
    {
        try
        {
            var response = await _httpClient.GetAsync(endpoint, ct);
            
            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync(ct);
                _logger.LogWarning("GET request to {Endpoint} failed with status {StatusCode}. Response: {Response}", 
                    endpoint, response.StatusCode, errorContent);
                return default;
            }

            var content = await response.Content.ReadAsStringAsync(ct);
            return DeserializeResponse<T>(content);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during GET request to {Endpoint}", endpoint);
            throw;
        }
    }

    /// <summary>
    /// POST isteği gönder
    /// </summary>
    /// <typeparam name="T">Dönüş tipi</typeparam>
    /// <param name="endpoint">API endpoint</param>
    /// <param name="data">Gönderilecek veri</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>API yanıtı</returns>
    public async Task<T?> PostAsync<T>(string endpoint, object? data = null, CancellationToken ct = default)
    {
        try
        {
            HttpContent? content = null;
            if (data != null)
            {
                var json = JsonConvert.SerializeObject(data);
                content = new StringContent(json, Encoding.UTF8, "application/json");
            }

            var response = await _httpClient.PostAsync(endpoint, content, ct);
            
            if (!response.IsSuccessStatusCode)
            {
                var errorContent = await response.Content.ReadAsStringAsync(ct);
                _logger.LogWarning("POST request to {Endpoint} failed with status {StatusCode}. Error: {Error}", 
                    endpoint, response.StatusCode, errorContent);
                return default;
            }

            var responseContent = await response.Content.ReadAsStringAsync(ct);
            return DeserializeResponse<T>(responseContent);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during POST request to {Endpoint}", endpoint);
            throw;
        }
    }

    /// <summary>
    /// PUT isteği gönder
    /// </summary>
    /// <typeparam name="T">Dönüş tipi</typeparam>
    /// <param name="endpoint">API endpoint</param>
    /// <param name="data">Güncellenecek veri</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>API yanıtı</returns>
    public async Task<T?> PutAsync<T>(string endpoint, object data, CancellationToken ct = default)
    {
        try
        {
            var json = JsonConvert.SerializeObject(data);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PutAsync(endpoint, content, ct);
            
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("PUT request to {Endpoint} failed with status {StatusCode}", endpoint, response.StatusCode);
                return default;
            }

            var responseContent = await response.Content.ReadAsStringAsync(ct);
            return DeserializeResponse<T>(responseContent);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during PUT request to {Endpoint}", endpoint);
            throw;
        }
    }

    /// <summary>
    /// PUT isteği gönder (başarı durumu ile)
    /// </summary>
    /// <param name="endpoint">API endpoint</param>
    /// <param name="data">Güncellenecek veri</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    public async Task<bool> PutAsync(string endpoint, object? data = null, CancellationToken ct = default)
    {
        try
        {
            var json = JsonConvert.SerializeObject(data ?? new { });
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PutAsync(endpoint, content, ct);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("PUT request to {Endpoint} failed with status {StatusCode}", endpoint, response.StatusCode);
            }

            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during PUT request to {Endpoint}", endpoint);
            return false;
        }
    }

    /// <summary>
    /// DELETE isteği gönder (dönüş değeri ile)
    /// </summary>
    /// <typeparam name="T">Dönüş tipi</typeparam>
    /// <param name="endpoint">API endpoint</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>API yanıtı</returns>
    public async Task<T?> DeleteAsync<T>(string endpoint, CancellationToken ct = default)
    {
        try
        {
            var response = await _httpClient.DeleteAsync(endpoint, ct);
            
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("DELETE request to {Endpoint} failed with status {StatusCode}", endpoint, response.StatusCode);
                return default;
            }

            var content = await response.Content.ReadAsStringAsync(ct);
            return DeserializeResponse<T>(content);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during DELETE request to {Endpoint}", endpoint);
            throw;
        }
    }

    /// <summary>
    /// DELETE isteği gönder (başarı durumu ile)
    /// </summary>
    /// <param name="endpoint">API endpoint</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    public async Task<bool> DeleteAsync(string endpoint, CancellationToken ct = default)
    {
        try
        {
            var response = await _httpClient.DeleteAsync(endpoint, ct);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during DELETE request to {Endpoint}", endpoint);
            return false;
        }
    }

    /// <summary>
    /// Byte dizisi dönen GET isteği gönder
    /// </summary>
    /// <param name="endpoint">API endpoint</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Byte dizisi</returns>
    public async Task<byte[]?> GetByteArrayAsync(string endpoint, CancellationToken ct = default)
    {
        try
        {
            var response = await _httpClient.GetAsync(endpoint, ct);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("GET (byte[]) request to {Endpoint} failed with status {StatusCode}", endpoint, response.StatusCode);
                return null;
            }

            return await response.Content.ReadAsByteArrayAsync(ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during GET (byte[]) request to {Endpoint}", endpoint);
            return null;
        }
    }
}

