using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.IdentityModel.Tokens;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Email;
using Talabi.Core.Email;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Talabi.Core.Services;

namespace Talabi.Api.Controllers;

/// <summary>
/// Kimlik doğrulama ve yetkilendirme işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class AuthController : BaseController
{
    private readonly IAuthService _authService;
    private readonly UserManager<AppUser> _userManager;
    private readonly IMemoryCache _memoryCache;
    private readonly IEmailSender _emailSender;
    private readonly IExternalAuthTokenVerifier _tokenVerifier;
    private readonly IVerificationCodeSecurityService _verificationSecurity;
    private readonly INotificationService _notificationService;
    private const string ResourceName = "AuthResources";

    /// <summary>
    /// AuthController constructor
    /// </summary>
    public AuthController(
        IAuthService authService,
        UserManager<AppUser> userManager,
        IMemoryCache memoryCache,
        IEmailSender emailSender,
        IExternalAuthTokenVerifier tokenVerifier,
        IVerificationCodeSecurityService verificationSecurity,
        INotificationService notificationService,
        IUnitOfWork unitOfWork,
        ILogger<AuthController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _authService = authService;
        _userManager = userManager;
        _memoryCache = memoryCache;
        _emailSender = emailSender;
        _tokenVerifier = tokenVerifier;
        _verificationSecurity = verificationSecurity;
        _notificationService = notificationService;
    }


    /// <summary>
    /// Yeni kullanıcı kaydı oluşturur
    /// </summary>
    /// <param name="dto">Kayıt bilgileri</param>
    /// <returns>Kayıt sonucu</returns>
    [HttpPost("register")]
    public async Task<ActionResult<ApiResponse<object>>> Register(RegisterDto dto)
    {
        try
        {
            var lang = GetLanguageFromRequest(dto.Language);
            var culture = GetCultureInfo(lang);

            var result = await _authService.RegisterAsync(dto, culture);

            return Ok(new ApiResponse<object>(
                result,
                LocalizationService.GetLocalizedString(ResourceName, "UserCreatedSuccessfully", culture)
            ));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new ApiResponse<object>(ex.Message, "REGISTRATION_FAILED"));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Register işlemi sırasında beklenmeyen hata. Email: {Email}", dto.Email);

            // Email gönderildiyse cache'i temizle
            var cacheKey = $"verification_code_{dto.Email}";
            _memoryCache.Remove(cacheKey);

            return StatusCode(500, new ApiResponse<object>(
                "Kayıt sırasında bir hata oluştu",
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
        }
    }

    /// <summary>
    /// Yeni satıcı kaydı oluşturur
    /// </summary>
    /// <param name="dto">Satıcı kayıt bilgileri</param>
    /// <returns>Kayıt sonucu</returns>
    [HttpPost("vendor-register")]
    public async Task<ActionResult<ApiResponse<object>>> VendorRegister(VendorRegisterDto dto)
    {
        try
        {
            var langVendor = GetLanguageFromRequest(dto.Language);
            var cultureVendor = GetCultureInfo(langVendor);

            var result = await _authService.VendorRegisterAsync(dto, cultureVendor);

            return Ok(new ApiResponse<object>(
                result,
                LocalizationService.GetLocalizedString(ResourceName, "VendorCreatedSuccessfully", cultureVendor)
            ));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new ApiResponse<object>(ex.Message, "REGISTRATION_FAILED"));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "VendorRegister işlemi sırasında beklenmeyen hata. Email: {Email}", dto.Email);

            var cacheKey = $"verification_code_{dto.Email}";
            _memoryCache.Remove(cacheKey);

            var langError = GetLanguageFromRequest(dto.Language);
            var cultureError = GetCultureInfo(langError);
            return StatusCode(500, new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "RegistrationError", cultureError),
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
        }
    }

    /// <summary>
    /// Yeni kurye kaydı oluşturur
    /// </summary>
    /// <param name="dto">Kurye kayıt bilgileri</param>
    /// <returns>Kayıt sonucu</returns>
    [HttpPost("courier-register")]
    public async Task<ActionResult<ApiResponse<object>>> CourierRegister(CourierRegisterDto dto)
    {
        try
        {
            var langCourier = GetLanguageFromRequest(dto.Language);
            var cultureCourier = GetCultureInfo(langCourier);

            var result = await _authService.CourierRegisterAsync(dto, cultureCourier);

            return Ok(new ApiResponse<object>(
                result,
                LocalizationService.GetLocalizedString(ResourceName, "CourierCreatedSuccessfully", cultureCourier)
            ));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new ApiResponse<object>(ex.Message, "REGISTRATION_FAILED"));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "CourierRegister işlemi sırasında beklenmeyen hata. Email: {Email}", dto.Email);

            var cacheKey = $"verification_code_{dto.Email}";
            _memoryCache.Remove(cacheKey);

            var langError = GetLanguageFromRequest(dto.Language);
            var cultureError = GetCultureInfo(langError);
            return StatusCode(500, new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "RegistrationError", cultureError),
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
        }
    }

    /// <summary>
    /// Email doğrulama kodunu kontrol eder ve email'i doğrular
    /// </summary>
    /// <param name="dto">Doğrulama kodu bilgileri</param>
    /// <returns>Doğrulama sonucu</returns>
    [HttpPost("verify-email-code")]
    public async Task<ActionResult<ApiResponse<object>>> VerifyEmailCode([FromBody] VerifyEmailCodeDto dto)
    {
        try
        {
            // Check if verification attempts are allowed (brute force protection)
            var canAttempt = await _verificationSecurity.CanAttemptVerificationAsync(dto.Email);
            if (!canAttempt)
            {
                var lockoutExpiration = await _verificationSecurity.GetLockoutExpirationAsync(dto.Email);
                if (lockoutExpiration.HasValue)
                {
                    var minutesRemaining = (int)Math.Ceiling((lockoutExpiration.Value - DateTime.UtcNow).TotalMinutes);
                    Logger.LogWarning(
                        "Verification attempt blocked for locked email: {Email}, Lockout expires in {Minutes} minutes",
                        dto.Email, minutesRemaining);

                    return BadRequest(new ApiResponse<object>(
                        LocalizationService.GetLocalizedString(ResourceName, "TooManyFailedAttempts", CurrentCulture)
                        ?? $"Çok fazla başarısız deneme. Lütfen {minutesRemaining} dakika sonra tekrar deneyin.",
                        "TOO_MANY_FAILED_ATTEMPTS",
                        new List<string> { $"Lockout expires in {minutesRemaining} minutes" }
                    ));
                }

                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "TooManyFailedAttempts", CurrentCulture)
                    ?? "Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin.",
                    "TOO_MANY_FAILED_ATTEMPTS"
                ));
            }

            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null)
            {
                // Don't reveal user existence, but still record attempt to prevent enumeration
                await _verificationSecurity.RecordFailedAttemptAsync(dto.Email);
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "InvalidCode", CurrentCulture),
                    "INVALID_CODE"));
            }

            // Check if email is already confirmed
            if (await _userManager.IsEmailConfirmedAsync(user))
            {
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "EmailAlreadyConfirmed", CurrentCulture),
                    "EMAIL_ALREADY_CONFIRMED"));
            }

            var cacheKey = $"verification_code_{dto.Email}";
            if (!_memoryCache.TryGetValue(cacheKey, out string? cachedCode))
            {
                await _verificationSecurity.RecordFailedAttemptAsync(dto.Email);
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "CodeExpired", CurrentCulture),
                    "CODE_EXPIRED"));
            }

            if (cachedCode != dto.Code)
            {
                // Record failed attempt
                await _verificationSecurity.RecordFailedAttemptAsync(dto.Email);

                var remainingAttempts = await _verificationSecurity.GetRemainingAttemptsAsync(dto.Email);
                Logger.LogWarning("Invalid verification code attempt for {Email}, Remaining attempts: {Remaining}",
                    dto.Email, remainingAttempts);

                var errorMessage = LocalizationService.GetLocalizedString(ResourceName, "InvalidCode", CurrentCulture);
                if (remainingAttempts <= 2)
                {
                    errorMessage += $" Kalan deneme hakkı: {remainingAttempts}";
                }

                return BadRequest(new ApiResponse<object>(
                    errorMessage,
                    "INVALID_CODE",
                    remainingAttempts > 0 ? new List<string> { $"Remaining attempts: {remainingAttempts}" } : null
                ));
            }

            // Code is valid, confirm email
            var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            var result = await _userManager.ConfirmEmailAsync(user, token);

            if (result.Succeeded)
            {
                // Remove code from cache
                _memoryCache.Remove(cacheKey);

                // Record success and clear tracking
                await _verificationSecurity.RecordSuccessAsync(dto.Email);

                Logger.LogInformation("Email verified successfully for {Email}", dto.Email);

                return Ok(new ApiResponse<object>(new { },
                    LocalizationService.GetLocalizedString(ResourceName, "EmailVerifiedSuccessfully", CurrentCulture)));
            }

            var errorMessages = result.Errors.Select(e => e.Description).ToList();
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "EmailVerificationFailed", CurrentCulture),
                "EMAIL_VERIFICATION_FAILED",
                errorMessages
            ));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error verifying email code for {Email}", dto.Email);
            return StatusCode(500, new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "VerificationError", CurrentCulture),
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
        }
    }

    /// <summary>
    /// Email doğrulama kodunu yeniden gönderir
    /// </summary>
    /// <param name="dto">Yeniden gönderme bilgileri</param>
    /// <returns>Gönderme sonucu</returns>
    [HttpPost("resend-verification-code")]
    public async Task<ActionResult<ApiResponse<object>>> ResendVerificationCode(
        [FromBody] ResendVerificationCodeDto dto)
    {
        try
        {
            // Try to get language from UserPreferences if user has preferences
            string? userLanguage = null;
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user != null)
            {
                var userPreferences = await UnitOfWork.UserPreferences.Query()
                    .FirstOrDefaultAsync(up => up.UserId == user.Id);

                if (userPreferences != null)
                {
                    userLanguage = userPreferences.Language;
                }
            }

            // Priority: DTO Language > UserPreferences > Accept-Language > Default
            var languageToUse = dto.Language ?? userLanguage;
            var lang = GetLanguageFromRequest(languageToUse);
            var culture = GetCultureInfo(lang);

            if (user == null)
            {
                // Don't reveal if user exists or not for security
                return Ok(new ApiResponse<object>(new { },
                    LocalizationService.GetLocalizedString(ResourceName, "CodeResentMessage", culture)));
            }

            // Check if email is already confirmed
            if (await _userManager.IsEmailConfirmedAsync(user))
            {
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "EmailAlreadyConfirmed", culture),
                    "EMAIL_ALREADY_CONFIRMED"));
            }

            // Send new verification code with language preference
            await _authService.SendVerificationCodeAsync(user.Email!, user.FullName, languageToUse);

            return Ok(new ApiResponse<object>(new { },
                LocalizationService.GetLocalizedString(ResourceName, "CodeResentSuccessfully", CurrentCulture)));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "CodeResendError", CurrentCulture),
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
        }
    }

    /// <summary>
    /// Email doğrulama token'ı ile email'i doğrular (legacy endpoint - backward compatibility için)
    /// </summary>
    /// <param name="token">Email doğrulama token'ı</param>
    /// <param name="email">Doğrulanacak email adresi</param>
    /// <returns>Doğrulama sonucu</returns>
    [HttpGet("confirm-email")]
    public async Task<IActionResult> ConfirmEmail(string? token, string? email)
    {
        try
        {
            // Token validation
            if (string.IsNullOrWhiteSpace(token))
            {
                Logger.LogWarning("ConfirmEmail: Token is null or empty");
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "TokenRequired", CurrentCulture),
                    "TOKEN_REQUIRED"));
            }

            // Email validation
            if (string.IsNullOrWhiteSpace(email))
            {
                Logger.LogWarning("ConfirmEmail: Email is null or empty");
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "EmailRequired", CurrentCulture),
                    "EMAIL_REQUIRED"));
            }

            // Email format validation
            if (!System.Text.RegularExpressions.Regex.IsMatch(email, @"^[^@\s]+@[^@\s]+\.[^@\s]+$"))
            {
                Logger.LogWarning("ConfirmEmail: Invalid email format - {Email}", email);
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "InvalidEmailFormat", CurrentCulture),
                    "INVALID_EMAIL_FORMAT"));
            }

            // Token format validation (ASP.NET Core Identity tokens are base64 encoded)
            // Token should not be too short or too long
            if (token.Length < 10 || token.Length > 1000)
            {
                Logger.LogWarning("ConfirmEmail: Invalid token format - Token length: {Length}", token.Length);
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "InvalidToken", CurrentCulture),
                    "INVALID_TOKEN_FORMAT"));
            }

            // Find user
            var user = await _userManager.FindByEmailAsync(email);
            if (user == null)
            {
                // Don't reveal if user exists or not for security
                Logger.LogWarning("ConfirmEmail: User not found for email - {Email}", email);
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "InvalidEmailConfirmationRequest",
                        CurrentCulture),
                    "INVALID_REQUEST"));
            }

            // Check if email is already confirmed
            if (await _userManager.IsEmailConfirmedAsync(user))
            {
                Logger.LogInformation("ConfirmEmail: Email already confirmed for - {Email}", email);
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "EmailAlreadyConfirmed", CurrentCulture),
                    "EMAIL_ALREADY_CONFIRMED"));
            }

            // URL decode token if needed (tokens in URLs are often URL encoded)
            var decodedToken = Uri.UnescapeDataString(token);

            // Confirm email with token
            var result = await _userManager.ConfirmEmailAsync(user, decodedToken);

            if (result.Succeeded)
            {
                Logger.LogInformation("Email confirmed successfully for - {Email}", email);
                return Ok(new ApiResponse<object>(
                    new { },
                    LocalizationService.GetLocalizedString(ResourceName, "EmailConfirmedSuccessfully",
                        CurrentCulture)));
            }

            // Log specific errors
            var errorMessages = result.Errors.Select(e => e.Description).ToList();
            Logger.LogWarning("ConfirmEmail: Email confirmation failed for - {Email}, Errors: {Errors}",
                email, string.Join(", ", errorMessages));

            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "EmailConfirmationFailed", CurrentCulture),
                "EMAIL_CONFIRMATION_FAILED",
                errorMessages));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error confirming email for - {Email}", email);
            return StatusCode(500, new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "EmailConfirmationError", CurrentCulture),
                "INTERNAL_ERROR",
                new List<string> { ex.Message }));
        }
    }

    /// <summary>
    /// Şifre sıfırlama kodu gönderir
    /// </summary>
    /// <param name="dto">Email bilgisi</param>
    /// <returns>Gönderme sonucu</returns>
    [HttpPost("forgot-password")]
    public async Task<ActionResult<ApiResponse<object>>> ForgotPassword([FromBody] ForgotPasswordDto dto)
    {
        try
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);
            var lang = GetLanguageFromRequest(dto.Language);
            var culture = GetCultureInfo(lang);

            if (user == null)
            {
                // Güvenlik için kullanıcı bulunamasa bile başarılı dön
                return Ok(new ApiResponse<object>(new { },
                    LocalizationService.GetLocalizedString(ResourceName, "PasswordResetCodeSent", culture)));
            }

            // Random 6 haneli kod oluştur
            var code = new Random().Next(100000, 999999).ToString();

            // Kodu cache'e kaydet (15 dakika geçerli)
            var cacheKey = $"reset_code_{dto.Email}";
            _memoryCache.Set(cacheKey, code, TimeSpan.FromMinutes(15));

            var subject = LocalizationService.GetLocalizedString(ResourceName, "ResetPasswordSubject", culture) ??
                          "Parola Sıfırlama Kodu";

            await _emailSender.SendEmailAsync(new EmailTemplateRequest
            {
                To = user.Email!,
                Subject = subject,
                TemplateName = EmailTemplateNames.ResetPassword,
                LanguageCode = lang,
                Variables = new Dictionary<string, string>
                {
                    ["fullName"] = string.IsNullOrWhiteSpace(user.FullName) ? user.Email! : user.FullName,
                    ["resetToken"] = code // Şablonun {{resetToken}} değişkenine kod gönderiliyor
                }
            });

            return Ok(new ApiResponse<object>(new { },
                LocalizationService.GetLocalizedString(ResourceName, "PasswordResetCodeSent", culture)));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "LoginError", CurrentCulture),
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
        }
    }

    /// <summary>
    /// Şifre sıfırlama kodunu doğrular
    /// </summary>
    /// <param name="dto">Email ve kod bilgisi</param>
    /// <returns>Sıfırlama token'ı</returns>
    [HttpPost("verify-reset-code")]
    public async Task<ActionResult<ApiResponse<object>>> VerifyResetCode([FromBody] VerifyResetCodeDto dto)
    {
        try
        {
            var cacheKey = $"reset_code_{dto.Email}";
            if (!_memoryCache.TryGetValue(cacheKey, out string? cachedCode) || cachedCode != dto.Code)
            {
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "InvalidCode", CurrentCulture),
                    "INVALID_CODE"));
            }

            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null)
            {
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "UserNotFound", CurrentCulture),
                    "USER_NOT_FOUND"));
            }

            // Kod doğru ise asıl password reset token'ını oluştur ve dön
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);

            // Cache'deki kodu sil (tek kullanımlık olması için)
            _memoryCache.Remove(cacheKey);

            return Ok(new ApiResponse<object>(new { Token = token },
                LocalizationService.GetLocalizedString(ResourceName, "CodeVerified", CurrentCulture)));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                "Doğrulama hatası",
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
        }
    }

    /// <summary>
    /// Şifreyi yeniler
    /// </summary>
    /// <param name="dto">Email, token ve yeni şifre</param>
    /// <returns>Sonuç</returns>
    [HttpPost("reset-password")]
    public async Task<ActionResult<ApiResponse<object>>> ResetPassword([FromBody] ResetPasswordDto dto)
    {
        try
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null)
            {
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "UserNotFound", CurrentCulture),
                    "USER_NOT_FOUND"));
            }

            var result = await _userManager.ResetPasswordAsync(user, dto.Token, dto.NewPassword);

            if (result.Succeeded)
            {
                return Ok(new ApiResponse<object>(new { },
                    LocalizationService.GetLocalizedString(ResourceName, "PasswordResetSuccess", CurrentCulture)));
            }

            var errorMessages = result.Errors.Select(e => e.Description).ToList();
            return BadRequest(new ApiResponse<object>(
                "Şifre sıfırlama başarısız",
                "RESET_FAILED",
                errorMessages
            ));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                "Şifre sıfırlama hatası",
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
        }
    }

    /// <summary>
    /// Kullanıcı girişi yapar ve JWT token döndürür
    /// </summary>
    /// <param name="dto">Giriş bilgileri</param>
    /// <returns>JWT token ve kullanıcı bilgileri</returns>
    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<LoginResponseDto>>> Login(LoginDto dto)
    {
        try
        {
            // Pass current culture language code to service
            var languageCode = CurrentCulture.TwoLetterISOLanguageName;
            var loginResponse = await _authService.LoginAsync(dto, languageCode);
            return Ok(new ApiResponse<LoginResponseDto>(loginResponse,
                LocalizationService.GetLocalizedString(ResourceName, "LoginSuccess", CurrentCulture)));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new ApiResponse<LoginResponseDto>(ex.Message, "INVALID_CREDENTIALS"));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new ApiResponse<LoginResponseDto>(ex.Message, "ACCOUNT_LOCKED"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<LoginResponseDto>(
                LocalizationService.GetLocalizedString(ResourceName, "LoginError", CurrentCulture),
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
        }
    }

    /// <summary>
    /// JWT token'ı yeniler
    /// </summary>
    /// <param name="dto">Token bilgileri</param>
    /// <returns>Yeni token'lar</returns>
    [HttpPost("refresh-token")]
    public async Task<ActionResult<ApiResponse<LoginResponseDto>>> RefreshToken(RefreshTokenDto dto)
    {
        if (dto is null)
            return BadRequest(new ApiResponse<LoginResponseDto>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture),
                "INVALID_REQUEST"));

        string? accessToken = dto.Token;
        string? refreshToken = dto.RefreshToken;

        var principal = _authService.GetPrincipalFromExpiredToken(accessToken);
        if (principal == null)
            return BadRequest(new ApiResponse<LoginResponseDto>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidToken", CurrentCulture), "INVALID_TOKEN"));

        var email = principal.FindFirstValue(ClaimTypes.Email) ??
                    principal.FindFirstValue(JwtRegisteredClaimNames.Email);
        if (email == null)
            return BadRequest(new ApiResponse<LoginResponseDto>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidToken", CurrentCulture), "INVALID_TOKEN"));

        var user = await _userManager.FindByEmailAsync(email);

        if (user == null || user.RefreshToken != refreshToken || user.RefreshTokenExpiryTime <= DateTime.UtcNow)
            return BadRequest(new ApiResponse<LoginResponseDto>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidToken", CurrentCulture), "INVALID_TOKEN"));

        var newAccessToken = await _authService.GenerateJwtTokenAsync(user);
        var newRefreshToken = _authService.GenerateRefreshToken();

        user.RefreshToken = newRefreshToken;
        await _userManager.UpdateAsync(user);

        var loginResponse = new LoginResponseDto
        {
            Token = newAccessToken,
            RefreshToken = newRefreshToken,
            UserId = user.Id,
            Email = user.Email!,
            FullName = user.FullName,
            Role = user.Role.ToString()
        };

        return Ok(new ApiResponse<LoginResponseDto>(loginResponse,
            LocalizationService.GetLocalizedString(ResourceName, "TokenRefreshSuccess", CurrentCulture)));
    }


    /// <summary>
    /// Sosyal medya ile giriş yapar (Google, Apple, Facebook)
    /// </summary>
    /// <param name="dto">Sosyal medya giriş bilgileri</param>
    /// <returns>JWT token ve kullanıcı bilgileri</returns>
    [HttpPost("external-login")]
    public async Task<ActionResult<ApiResponse<LoginResponseDto>>> ExternalLogin([FromBody] ExternalAuthDto dto)
    {
        try
        {
            // Validate provider
            if (string.IsNullOrEmpty(dto.Provider) ||
                !new[] { "Google", "Apple", "Facebook" }.Contains(dto.Provider))
            {
                return BadRequest(new ApiResponse<LoginResponseDto>(
                    LocalizationService.GetLocalizedString(ResourceName, "InvalidProvider", CurrentCulture),
                    "INVALID_PROVIDER"));
            }

            // Validate token
            if (string.IsNullOrEmpty(dto.IdToken))
            {
                return BadRequest(new ApiResponse<LoginResponseDto>(
                    LocalizationService.GetLocalizedString(ResourceName, "TokenRequired", CurrentCulture),
                    "TOKEN_REQUIRED"));
            }

            // Verify token with external provider
            var isTokenValid = await _tokenVerifier.VerifyTokenAsync(dto.Provider, dto.IdToken, dto.Email);
            if (!isTokenValid)
            {
                Logger.LogWarning("Invalid token for provider: {Provider}, Email: {Email}", dto.Provider, dto.Email);
                return Unauthorized(new ApiResponse<LoginResponseDto>(
                    LocalizationService.GetLocalizedString(ResourceName, "InvalidToken", CurrentCulture),
                    "INVALID_TOKEN"));
            }

            // Get email from token if not provided (more secure)
            var verifiedEmail = dto.Email;
            if (string.IsNullOrEmpty(verifiedEmail))
            {
                verifiedEmail = await _tokenVerifier.GetEmailFromTokenAsync(dto.Provider, dto.IdToken);
            }

            if (string.IsNullOrEmpty(verifiedEmail))
            {
                return BadRequest(new ApiResponse<LoginResponseDto>(
                    LocalizationService.GetLocalizedString(ResourceName, "EmailRequired", CurrentCulture),
                    "EMAIL_REQUIRED"));
            }

            // Check if user exists
            var user = await _userManager.FindByEmailAsync(verifiedEmail);

            if (user == null)
            {
                // Create new user
                user = new AppUser
                {
                    UserName = verifiedEmail,
                    Email = verifiedEmail,
                    FullName = dto.FullName ?? verifiedEmail,
                    EmailConfirmed = true, // Social login emails are pre-verified
                    Role = Talabi.Core.Enums.UserRole.Customer
                };

                var result = await _userManager.CreateAsync(user);
                if (!result.Succeeded)
                {
                    var errorMessages = result.Errors.Select(e => e.Description).ToList();
                    return BadRequest(new ApiResponse<LoginResponseDto>(
                        "User creation failed",
                        "USER_CREATION_FAILED",
                        errorMessages
                    ));
                }

                // Assign Customer role
                await _userManager.AddToRoleAsync(user, "Customer");

                // Create Customer entity
                var customer = new Customer
                {
                    UserId = user.Id
                };
                await UnitOfWork.Customers.AddAsync(customer);
                await UnitOfWork.SaveChangesAsync();

                Logger.LogInformation("New user created via {Provider}: {Email}", dto.Provider, verifiedEmail);
            }
            else
            {
                // User exists, just log them in
                Logger.LogInformation("Existing user logged in via {Provider}: {Email}", dto.Provider, verifiedEmail);
            }

            // Generate JWT token
            var token = await _authService.GenerateJwtTokenAsync(user);
            var refreshToken = _authService.GenerateRefreshToken();

            user.RefreshToken = refreshToken;
            user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(7);
            await _userManager.UpdateAsync(user);

            var loginResponse = new LoginResponseDto
            {
                Token = token,
                RefreshToken = refreshToken,
                UserId = user.Id,
                Email = user.Email!,
                FullName = user.FullName,
                Role = user.Role.ToString(),
                Provider = dto.Provider
            };

            return Ok(new ApiResponse<LoginResponseDto>(loginResponse,
                LocalizationService.GetLocalizedString(ResourceName, "LoginSuccess", CurrentCulture)));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, $"External login failed for provider: {dto.Provider}");
            return StatusCode(500, new ApiResponse<LoginResponseDto>(
                LocalizationService.GetLocalizedString(ResourceName, "ExternalLoginError", CurrentCulture),
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
        }
    }

    /// <summary>
    /// Kullanıcı hesabını siler
    /// </summary>
    [HttpPost("delete-account")]
    [Authorize]
    public async Task<IActionResult> DeleteAccount()
    {
        try
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId))
            {
                return Unauthorized(new ApiResponse<string>(
                    LocalizationService.GetLocalizedString(ResourceName, "UserNotFound", CurrentCulture),
                    "UNAUTHORIZED"));
            }

            await _authService.DeleteAccountAsync(userId);

            return Ok(new ApiResponse<string>(
                data: string.Empty,
                message: LocalizationService.GetLocalizedString(ResourceName, "AccountDeletedSuccessfully",
                    CurrentCulture)));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Account deletion failed");
            return StatusCode(500, new ApiResponse<string>(
                message: LocalizationService.GetLocalizedString(ResourceName, "AccountDeletionError", CurrentCulture),
                errorCode: "INTERNAL_ERROR",
                errors: new List<string> { ex.Message }
            ));
        }
    }

    /// <summary>
    /// Cihaz token'ını kaydeder
    /// </summary>
    /// <param name="request">Cihaz kayıt bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPost("register-device")]
    [AllowAnonymous] // Allow device registration without authentication
    public async Task<ActionResult<ApiResponse<object>>> RegisterDevice(
        [FromBody] RegisterDeviceRequest request)
    {
        // If user is authenticated, use their ID; otherwise use the token as a guest identifier
        var userId = UserContext.GetUserId() ?? $"guest_{request.Token.GetHashCode()}";

        await _notificationService.RegisterDeviceTokenAsync(userId, request.Token, request.DeviceType);
        return Ok(new ApiResponse<object>(
            new { }, 
            LocalizationService.GetLocalizedString("NotificationResources", "DeviceRegisteredSuccessfully", CurrentCulture)));
    }
}

/// <summary>
/// Cihaz kayıt isteği DTO'su
/// </summary>
public class RegisterDeviceRequest
{
    public string Token { get; set; } = string.Empty;
    public string DeviceType { get; set; } = string.Empty;
}
