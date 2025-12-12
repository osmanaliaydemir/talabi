using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IAuthService
{
    /// <summary>
    /// Kullanıcı girişi yapar.
    /// </summary>
    /// <param name="request">Giriş isteği</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Giriş yanıtı</returns>
    Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken ct = default);
    /// <summary>
    /// Kullanıcı çıkışı yapar.
    /// </summary>
    Task LogoutAsync();
    /// <summary>
    /// Şifre değiştirir.
    /// </summary>
    /// <param name="currentPassword">Mevcut şifre</param>
    /// <param name="newPassword">Yeni şifre</param>
    /// <param name="ct">CancellationToken</param>
    /// <returns>Başarılı olup olmadığı</returns>
    Task<bool> ChangePasswordAsync(string currentPassword, string newPassword, CancellationToken ct = default);
}

