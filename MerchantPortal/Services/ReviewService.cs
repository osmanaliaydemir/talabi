using Getir.MerchantPortal.Models;
using System.Text;

namespace Getir.MerchantPortal.Services;

/// <summary>
/// Merchant Portal değerlendirme servisi implementasyonu
/// </summary>
public class ReviewService : IReviewService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ReviewService> _logger;

    /// <summary>
    /// ReviewService constructor
    /// </summary>
    /// <param name="httpClient">HTTP client</param>
    /// <param name="logger">Logger instance</param>
    public ReviewService(HttpClient httpClient, ILogger<ReviewService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    /// <summary>
    /// Merchant değerlendirmelerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="filter">Filtre parametreleri</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Değerlendirme listesi</returns>
    public async Task<List<ReviewResponse>> GetMerchantReviewsAsync(Guid merchantId, ReviewFilterModel filter, CancellationToken ct = default)
    {
        try
        {
            var queryParams = new List<string>
            {
                "Page=1",
                "PageSize=50"
            };

            if (filter.Rating.HasValue)
                queryParams.Add($"rating={filter.Rating}");
            if (filter.StartDate.HasValue)
                queryParams.Add($"startDate={filter.StartDate:yyyy-MM-dd}");
            if (filter.EndDate.HasValue)
                queryParams.Add($"endDate={filter.EndDate:yyyy-MM-dd}");
            if (!string.IsNullOrEmpty(filter.SearchTerm))
                queryParams.Add($"search={filter.SearchTerm}");

            var query = string.Join("&", queryParams);
            var response = await _httpClient.GetAsync($"api/v1/review/entity/{merchantId}/Merchant?{query}", ct);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Failed to get merchant reviews: {StatusCode}", response.StatusCode);
                return new List<ReviewResponse>();
            }

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<PagedResult<ReviewResponse>>>();
            return apiResponse?.Data?.Items ?? new List<ReviewResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting merchant reviews for {MerchantId}", merchantId);
            return new List<ReviewResponse>();
        }
    }

    /// <summary>
    /// Kurye değerlendirmelerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="filter">Filtre parametreleri</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Değerlendirme listesi</returns>
    public async Task<List<ReviewResponse>> GetCourierReviewsAsync(Guid merchantId, ReviewFilterModel filter, CancellationToken ct = default)
    {
        try
        {
            // First get couriers for this merchant
            var couriersResponse = await _httpClient.GetAsync($"api/v1/courier/merchant/{merchantId}", ct);
            if (!couriersResponse.IsSuccessStatusCode)
            {
                _logger.LogWarning("Failed to get couriers for merchant: {StatusCode}", couriersResponse.StatusCode);
                return new List<ReviewResponse>();
            }

            var couriersApiResponse = await couriersResponse.Content.ReadFromJsonAsync<ApiResponse<List<CourierResponse>>>();
            var couriers = couriersApiResponse?.Data ?? new List<CourierResponse>();

            if (!couriers.Any())
                return new List<ReviewResponse>();

            // Get reviews for all couriers
            var allReviews = new List<ReviewResponse>();
            foreach (var courier in couriers)
            {
                var queryParams = new List<string>
                {
                    "Page=1",
                    "PageSize=50"
                };

                if (filter.Rating.HasValue)
                    queryParams.Add($"rating={filter.Rating}");
                if (filter.StartDate.HasValue)
                    queryParams.Add($"startDate={filter.StartDate:yyyy-MM-dd}");
                if (filter.EndDate.HasValue)
                    queryParams.Add($"endDate={filter.EndDate:yyyy-MM-dd}");

                var query = string.Join("&", queryParams);
                var response = await _httpClient.GetAsync($"api/v1/review/entity/{courier.Id}/Courier?{query}", ct);

                if (response.IsSuccessStatusCode)
                {
                    var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<PagedResult<ReviewResponse>>>();
                    var reviews = apiResponse?.Data?.Items ?? new List<ReviewResponse>();
                    allReviews.AddRange(reviews);
                }
            }

            return allReviews.OrderByDescending(r => r.CreatedAt).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting courier reviews for merchant {MerchantId}", merchantId);
            return new List<ReviewResponse>();
        }
    }

    /// <summary>
    /// Merchant değerlendirme istatistiklerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Değerlendirme istatistikleri</returns>
    public async Task<ReviewStatsResponse?> GetMerchantReviewStatsAsync(Guid merchantId, CancellationToken ct = default)
    {
        try
        {
            var response = await _httpClient.GetAsync($"api/v1/review/statistics/{merchantId}/Merchant", ct);
            if (!response.IsSuccessStatusCode)
                return null;

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<ReviewStatsResponse>>();
            return apiResponse?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting merchant review stats for {MerchantId}", merchantId);
            return null;
        }
    }

    /// <summary>
    /// Kurye değerlendirme istatistiklerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Değerlendirme istatistikleri</returns>
    public async Task<ReviewStatsResponse?> GetCourierReviewStatsAsync(Guid merchantId, CancellationToken ct = default)
    {
        try
        {
            // Get couriers for this merchant first
            var couriersResponse = await _httpClient.GetAsync($"api/v1/courier/merchant/{merchantId}", ct);
            if (!couriersResponse.IsSuccessStatusCode)
                return null;

            var couriersApiResponse = await couriersResponse.Content.ReadFromJsonAsync<ApiResponse<List<CourierResponse>>>();
            var couriers = couriersApiResponse?.Data ?? new List<CourierResponse>();

            if (!couriers.Any())
                return null;

            // Aggregate stats from all couriers
            var totalReviews = 0;
            var totalRating = 0.0;
            var ratingDistribution = new Dictionary<int, int>();

            foreach (var courier in couriers)
            {
                var response = await _httpClient.GetAsync($"api/v1/review/statistics/{courier.Id}/Courier", ct);
                if (response.IsSuccessStatusCode)
                {
                    var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<ReviewStatsResponse>>();
                    var stats = apiResponse?.Data;
                    if (stats != null)
                    {
                        totalReviews += stats.TotalReviews;
                        totalRating += stats.AverageRating * stats.TotalReviews;
                        
                        for (int i = 1; i <= 5; i++)
                        {
                            if (stats.RatingDistribution.ContainsKey(i))
                                ratingDistribution[i] = ratingDistribution.GetValueOrDefault(i, 0) + stats.RatingDistribution[i];
                        }
                    }
                }
            }

            if (totalReviews == 0)
                return null;

            return new ReviewStatsResponse
            {
                EntityId = merchantId,
                EntityType = "Courier",
                TotalReviews = totalReviews,
                AverageRating = totalRating / totalReviews,
                RatingDistribution = ratingDistribution
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting courier review stats for merchant {MerchantId}", merchantId);
            return null;
        }
    }

    /// <summary>
    /// Değerlendirmeye yanıt ver
    /// </summary>
    /// <param name="reviewId">Değerlendirme ID</param>
    /// <param name="response">Yanıt metni</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    public async Task<bool> RespondToReviewAsync(Guid reviewId, string response, CancellationToken ct = default)
    {
        try
        {
            var request = new { Response = response };
            var json = System.Text.Json.JsonSerializer.Serialize(request);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var httpResponse = await _httpClient.PutAsync($"api/v1/review/{reviewId}/respond", content, ct);
            return httpResponse.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error responding to review {ReviewId}", reviewId);
            return false;
        }
    }

    /// <summary>
    /// Değerlendirmeyi beğen/beğenme
    /// </summary>
    /// <param name="reviewId">Değerlendirme ID</param>
    /// <param name="isLiked">Beğenilme durumu</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    public async Task<bool> LikeReviewAsync(Guid reviewId, bool isLiked, CancellationToken ct = default)
    {
        try
        {
            if (isLiked)
            {
                var response = await _httpClient.PostAsync($"api/v1/review/{reviewId}/like", null, ct);
                return response.IsSuccessStatusCode;
            }
            else
            {
                var response = await _httpClient.DeleteAsync($"api/v1/review/{reviewId}/like", ct);
                return response.IsSuccessStatusCode;
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error liking/unliking review {ReviewId}", reviewId);
            return false;
        }
    }

    /// <summary>
    /// Değerlendirmeyi rapor et
    /// </summary>
    /// <param name="reviewId">Değerlendirme ID</param>
    /// <param name="reason">Rapor nedeni</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    public async Task<bool> ReportReviewAsync(Guid reviewId, string reason, CancellationToken ct = default)
    {
        try
        {
            var request = new { Reason = reason };
            var json = System.Text.Json.JsonSerializer.Serialize(request);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync($"api/v1/review/{reviewId}/report", content, ct);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reporting review {ReviewId}", reviewId);
            return false;
        }
    }

    /// <summary>
    /// Değerlendirme dashboard verilerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Dashboard verileri</returns>
    public async Task<ReviewDashboardModel> GetReviewDashboardAsync(Guid merchantId, CancellationToken ct = default)
    {
        try
        {
            var merchantStats = await GetMerchantReviewStatsAsync(merchantId, ct);
            var courierStats = await GetCourierReviewStatsAsync(merchantId, ct);

            return new ReviewDashboardModel
            {
                MerchantStats = merchantStats,
                CourierStats = courierStats,
                GeneratedAt = DateTime.Now
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting review dashboard for merchant {MerchantId}", merchantId);
            return new ReviewDashboardModel
            {
                GeneratedAt = DateTime.Now
            };
        }
    }
}
