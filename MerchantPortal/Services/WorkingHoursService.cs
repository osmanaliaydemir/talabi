using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class WorkingHoursService : IWorkingHoursService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<WorkingHoursService> _logger;

    public WorkingHoursService(IApiClient apiClient, ILogger<WorkingHoursService> logger)
    {
        _apiClient = apiClient;
        _logger = logger;
    }

    /// <summary>
    /// Çalışma saatlerini getirir.
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Çalışma saatleri</returns>
    public async Task<List<WorkingHoursResponse>?> GetWorkingHoursByMerchantAsync(Guid merchantId, CancellationToken ct = default)
    {
        try
        {
            // Backend'den API Response bekleriz (DayOfWeek enum gelir)
            var response = await _apiClient.GetAsync<ApiResponse<List<BackendWorkingHoursResponse>>>(
                $"api/v1/workinghours/merchant/{merchantId}",
                ct);

            if (response?.Data == null)
            {
                return null;
            }

            // Backend DTO → Frontend DTO mapping
            return response.Data.Select(MapToFrontendDto).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting working hours for merchant {MerchantId}", merchantId);
            return null;
        }
    }

    /// <summary>
    /// Çalışma saatlerini bulk günceller.
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="workingHours">Çalışma saatleri</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Başarılı olup olmadığı</returns>
    public async Task<bool> BulkUpdateWorkingHoursAsync(Guid merchantId, List<UpdateWorkingHoursRequest> workingHours, CancellationToken ct = default)
    {
        try
        {
            // Frontend DTO → Backend DTO mapping
            var backendWorkingHours = workingHours.Select(MapToBackendDto).ToList();

            // Backend expects: { WorkingHours: [...] }
            var request = new
            {
                WorkingHours = backendWorkingHours
            };

            var response = await _apiClient.PutAsync<ApiResponse<object>>(
                $"api/v1/workinghours/merchant/{merchantId}/bulk",
                request,
                ct);

            if (response?.isSuccess == true)
            {
                _logger.LogInformation("Working hours updated successfully for merchant {MerchantId}", merchantId);
                return true;
            }

            _logger.LogWarning("Failed to update working hours for merchant {MerchantId}. Response: {@Response}", merchantId, response);
            return false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error bulk updating working hours for merchant {MerchantId}", merchantId);
            return false;
        }
    }

    /// <summary>
    /// Backend DTO → Frontend DTO mapping
    /// </summary>
    private WorkingHoursResponse MapToFrontendDto(BackendWorkingHoursResponse backend)
    {
        // IsOpen24Hours logic: 00:00-23:59 veya 00:00-00:00 ise 24 saat açık
        var isOpen24Hours = backend.OpenTime.HasValue && backend.CloseTime.HasValue &&
                           backend.OpenTime.Value == TimeSpan.Zero &&
                           (backend.CloseTime.Value == new TimeSpan(23, 59, 0) || backend.CloseTime.Value == TimeSpan.Zero);

        return new WorkingHoursResponse
        {
            Id = backend.Id,
            MerchantId = backend.MerchantId,
            DayOfWeek = backend.DayOfWeek.ToString(), // enum → string
            OpenTime = backend.OpenTime ?? TimeSpan.Zero,
            CloseTime = backend.CloseTime ?? TimeSpan.Zero,
            IsClosed = backend.IsClosed,
            IsOpen24Hours = isOpen24Hours
        };
    }

    /// <summary>
    /// Frontend DTO → Backend DTO mapping
    /// </summary>
    private BackendUpdateWorkingHoursRequest MapToBackendDto(UpdateWorkingHoursRequest frontend)
    {
        // Parse enum from string
        if (!Enum.TryParse<DayOfWeek>(frontend.DayOfWeek, out var dayOfWeek))
        {
            throw new ArgumentException($"Invalid DayOfWeek: {frontend.DayOfWeek}");
        }

        // Parse time from string ("09:00" → TimeSpan)
        TimeSpan? openTime = null;
        TimeSpan? closeTime = null;

        if (!string.IsNullOrEmpty(frontend.OpenTime) && TimeSpan.TryParse(frontend.OpenTime, out var parsedOpen))
        {
            openTime = parsedOpen;
        }

        if (!string.IsNullOrEmpty(frontend.CloseTime) && TimeSpan.TryParse(frontend.CloseTime, out var parsedClose))
        {
            closeTime = parsedClose;
        }

        // IsOpen24Hours logic: 24 saat açıksa 00:00-23:59 yap
        if (frontend.IsOpen24Hours)
        {
            openTime = TimeSpan.Zero;
            closeTime = new TimeSpan(23, 59, 0);
        }

        // IsClosed ise time'ları null yap
        if (frontend.IsClosed)
        {
            openTime = null;
            closeTime = null;
        }

        return new BackendUpdateWorkingHoursRequest
        {
            DayOfWeek = dayOfWeek,
            OpenTime = openTime,
            CloseTime = closeTime,
            IsClosed = frontend.IsClosed
        };
    }

    /// <summary>
    /// Backend'den gelen DTO (DayOfWeek enum)
    /// JSON deserialization için init accessor kullanılır
    /// </summary>
    private class BackendWorkingHoursResponse
    {
        public Guid Id { get; init; }
        public Guid MerchantId { get; init; }
        public DayOfWeek DayOfWeek { get; init; }
        public TimeSpan? OpenTime { get; init; }
        public TimeSpan? CloseTime { get; init; }
        public bool IsClosed { get; init; }
        public DateTime CreatedAt { get; init; }
    }

    /// <summary>
    /// Backend'e gönderilen DTO (DayOfWeek enum)
    /// JSON serialization için init accessor kullanılır
    /// </summary>
    private class BackendUpdateWorkingHoursRequest
    {
        public DayOfWeek DayOfWeek { get; init; }
        public TimeSpan? OpenTime { get; init; }
        public TimeSpan? CloseTime { get; init; }
        public bool IsClosed { get; init; }
    }
}

