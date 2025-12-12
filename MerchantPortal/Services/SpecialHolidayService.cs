using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public class SpecialHolidayService : ISpecialHolidayService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<SpecialHolidayService> _logger;

    public SpecialHolidayService(IApiClient apiClient, ILogger<SpecialHolidayService> logger)
    {
        _apiClient = apiClient;
        _logger = logger;
    }

    public async Task<List<SpecialHolidayResponse>?> GetHolidaysAsync(Guid merchantId, bool includeInactive = false, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<List<SpecialHolidayResponse>>>(
                $"api/v1/specialholiday/merchant/{merchantId}?includeInactive={includeInactive}",
                ct);
            return response?.Data ?? new List<SpecialHolidayResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting special holidays for merchant {MerchantId}", merchantId);
            return null;
        }
    }

    public async Task<List<SpecialHolidayResponse>?> GetUpcomingAsync(Guid merchantId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<List<SpecialHolidayResponse>>>(
                $"api/v1/specialholiday/merchant/{merchantId}/upcoming",
                ct);
            return response?.Data ?? new List<SpecialHolidayResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting upcoming special holidays for merchant {MerchantId}", merchantId);
            return null;
        }
    }

    public async Task<SpecialHolidayResponse?> GetByIdAsync(Guid id, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<SpecialHolidayResponse>>(
                $"api/v1/specialholiday/{id}",
                ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting special holiday {HolidayId}", id);
            return null;
        }
    }

    public async Task<MerchantAvailabilityResponse?> CheckAvailabilityAsync(Guid merchantId, DateTime? date = null, CancellationToken ct = default)
    {
        try
        {
            var url = $"api/v1/specialholiday/merchant/{merchantId}/availability";
            if (date.HasValue)
            {
                url += $"?checkDate={date.Value:O}";
            }

            var response = await _apiClient.GetAsync<ApiResponse<MerchantAvailabilityResponse>>(url, ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking merchant availability {MerchantId}", merchantId);
            return null;
        }
    }

    public async Task<SpecialHolidayResponse?> CreateAsync(CreateSpecialHolidayRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PostAsync<ApiResponse<SpecialHolidayResponse>>(
                "api/v1/specialholiday",
                request,
                ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating special holiday for merchant {MerchantId}", request.MerchantId);
            return null;
        }
    }

    public async Task<SpecialHolidayResponse?> UpdateAsync(Guid id, UpdateSpecialHolidayRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PutAsync<ApiResponse<SpecialHolidayResponse>>(
                $"api/v1/specialholiday/{id}",
                request,
                ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating special holiday {HolidayId}", id);
            return null;
        }
    }

    public async Task<bool> DeleteAsync(Guid id, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.DeleteAsync<ApiResponse<object>>(
                $"api/v1/specialholiday/{id}",
                ct);
            return response?.isSuccess == true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting special holiday {HolidayId}", id);
            return false;
        }
    }

    public async Task<bool> ToggleStatusAsync(Guid id, CancellationToken ct = default)
    {
        try
        {
            var holiday = await GetByIdAsync(id, ct);
            if (holiday == null)
            {
                return false;
            }

            var updateRequest = new UpdateSpecialHolidayRequest
            {
                Title = holiday.Title,
                Description = holiday.Description,
                StartDate = holiday.StartDate,
                EndDate = holiday.EndDate,
                IsClosed = holiday.IsClosed,
                SpecialOpenTime = holiday.SpecialOpenTime,
                SpecialCloseTime = holiday.SpecialCloseTime,
                IsRecurring = holiday.IsRecurring,
                IsActive = !holiday.IsActive
            };

            var updated = await UpdateAsync(id, updateRequest, ct);
            return updated != null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error toggling special holiday status {HolidayId}", id);
            return false;
        }
    }
}

