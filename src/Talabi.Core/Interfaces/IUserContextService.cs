namespace Talabi.Core.Interfaces;

/// <summary>
/// Kullanıcı context servisi interface'i
/// Mevcut kullanıcı bilgilerini ve rollerini sağlar
/// </summary>
public interface IUserContextService
{
    /// <summary>
    /// Mevcut kullanıcı ID'sini getirir
    /// </summary>
    /// <returns>User ID veya null</returns>
    string? GetUserId();

    /// <summary>
    /// Mevcut kullanıcının Vendor ID'sini getirir (varsa)
    /// </summary>
    /// <returns>Vendor ID veya null</returns>
    Task<Guid?> GetVendorIdAsync();

    /// <summary>
    /// Mevcut kullanıcının Courier ID'sini getirir (varsa)
    /// </summary>
    /// <returns>Courier ID veya null</returns>
    Task<Guid?> GetCourierIdAsync();

    /// <summary>
    /// Mevcut kullanıcının Customer ID'sini getirir (varsa)
    /// </summary>
    /// <returns>Customer ID veya null</returns>
    Task<Guid?> GetCustomerIdAsync();

    /// <summary>
    /// Kullanıcının vendor olup olmadığını kontrol eder
    /// </summary>
    /// <returns>True if vendor, false otherwise</returns>
    Task<bool> IsVendorAsync();

    /// <summary>
    /// Kullanıcının courier olup olmadığını kontrol eder
    /// </summary>
    /// <returns>True if courier, false otherwise</returns>
    Task<bool> IsCourierAsync();
}

