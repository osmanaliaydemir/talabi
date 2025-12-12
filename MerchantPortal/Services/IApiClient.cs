namespace Getir.MerchantPortal.Services;

public interface IApiClient
{
    /// <summary>
    /// GET isteği yapar.
    /// </summary>
    /// <param name="endpoint">Endpoint</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Yanıt</returns>
    Task<T?> GetAsync<T>(string endpoint, CancellationToken ct = default);
    /// <summary>
    /// POST isteği yapar.
    /// </summary>
    /// <param name="endpoint">Endpoint</param>
    /// <param name="data">Veri</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Yanıt</returns>
    Task<T?> PostAsync<T>(string endpoint, object? data = null, CancellationToken ct = default);
    /// <summary>
    /// PUT isteği yapar.
    /// </summary>
    /// <param name="endpoint">Endpoint</param>
    /// <param name="data">Veri</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Yanıt</returns>
    Task<T?> PutAsync<T>(string endpoint, object data, CancellationToken ct = default);
    /// <summary>
    /// PUT isteği yapar (başarı durumu ile).
    /// </summary>
    /// <param name="endpoint">Endpoint</param>
    /// <param name="data">Veri</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Başarılı olup olmadığı</returns>
    Task<bool> PutAsync(string endpoint, object? data = null, CancellationToken ct = default);
    /// <summary>
    /// DELETE isteği yapar.
    /// </summary>
    /// <param name="endpoint">Endpoint</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Yanıt</returns>
    Task<T?> DeleteAsync<T>(string endpoint, CancellationToken ct = default);
    /// <summary>
    /// DELETE isteği yapar.
    /// </summary>
    /// <param name="endpoint">Endpoint</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Başarılı olup olmadığı</returns>
    Task<bool> DeleteAsync(string endpoint, CancellationToken ct = default);
    /// <summary>
    /// RAW içerik döner.
    /// </summary>
    /// <param name="endpoint">Endpoint</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Byte dizisi</returns>
    Task<byte[]?> GetByteArrayAsync(string endpoint, CancellationToken ct = default);
    /// <summary>
    /// Auth token'ı ayarlar.
    /// </summary>
    /// <param name="token">Token</param>
    /// <returns>Başarılı olup olmadığı</returns>
    /// </summary>
    void SetAuthToken(string token);
    /// <summary>
    /// Auth token'ı temizler.
    /// </summary>
    /// <returns>Başarılı olup olmadığı</returns>
    /// </summary>
    void ClearAuthToken();
}

