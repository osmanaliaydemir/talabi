using Talabi.Portal.Models;

namespace Talabi.Portal.Services;

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
    /// Generates a JWT token for SignalR connection
    /// </summary>
    Task<string> GenerateSignalRTokenAsync(Core.Entities.AppUser user);
}
