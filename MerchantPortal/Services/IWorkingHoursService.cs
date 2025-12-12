using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IWorkingHoursService
{   
    /// <summary>
    /// Çalışma saatlerini getirir.
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Çalışma saatleri</returns>
    Task<List<WorkingHoursResponse>?> GetWorkingHoursByMerchantAsync(Guid merchantId, CancellationToken ct = default);

    /// <summary>
    /// Çalışma saatlerini bulk günceller.
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="workingHours">Çalışma saatleri</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Başarılı olup olmadığı</returns>
    Task<bool> BulkUpdateWorkingHoursAsync(Guid merchantId, List<UpdateWorkingHoursRequest> workingHours, CancellationToken ct = default);
}

