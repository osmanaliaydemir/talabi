using System.Security.Claims;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;

namespace Talabi.Core.Interfaces;

/// <summary>
/// Authentication işlemleri için service interface
/// </summary>
public interface IAuthService
{
    /// <summary>
    /// JWT token üretir
    /// </summary>
    Task<string> GenerateJwtTokenAsync(AppUser user);

    /// <summary>
    /// Refresh token üretir
    /// </summary>
    string GenerateRefreshToken();

    /// <summary>
    /// Expired token'dan principal çıkarır
    /// </summary>
    ClaimsPrincipal? GetPrincipalFromExpiredToken(string? token);

    /// <summary>
    /// Email doğrulama kodu gönderir
    /// </summary>
    Task SendVerificationCodeAsync(string email, string? fullName, string? languageCode);

    /// <summary>
    /// Kullanıcı girişi yapar
    /// </summary>
    Task<LoginResponseDto> LoginAsync(LoginDto dto, string? languageCode);

    /// <summary>
    /// Yeni kullanıcı kaydı oluşturur
    /// </summary>
    Task<object> RegisterAsync(RegisterDto dto, CultureInfo culture);

    /// <summary>
    /// Vendor kaydı oluşturur
    /// </summary>
    Task<object> VendorRegisterAsync(VendorRegisterDto dto, CultureInfo culture);

    /// <summary>
    /// Courier kaydı oluşturur
    /// </summary>
    Task<object> CourierRegisterAsync(CourierRegisterDto dto, CultureInfo culture);

    /// <summary>
    /// Kullanıcı hesabını siler
    /// </summary>
    Task DeleteAccountAsync(string userId);
}

