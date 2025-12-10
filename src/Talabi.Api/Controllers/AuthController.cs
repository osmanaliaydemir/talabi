using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Email;
using Talabi.Core.Email;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
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
    private const string ResourceName = "AuthResources";

    /// <summary>
    /// AuthController constructor
    /// </summary>
    public AuthController(
        IAuthService authService,
        UserManager<AppUser> userManager,
        IMemoryCache memoryCache,
        IEmailSender emailSender,
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
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null)
            {
                return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "UserNotFound", CurrentCulture), "USER_NOT_FOUND"));
            }

            // Check if email is already confirmed
            if (await _userManager.IsEmailConfirmedAsync(user))
            {
                return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "EmailAlreadyConfirmed", CurrentCulture), "EMAIL_ALREADY_CONFIRMED"));
            }

            var cacheKey = $"verification_code_{dto.Email}";
            if (!_memoryCache.TryGetValue(cacheKey, out string? cachedCode))
            {
                return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "CodeExpired", CurrentCulture), "CODE_EXPIRED"));
            }

            if (cachedCode != dto.Code)
            {
                return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "InvalidCode", CurrentCulture), "INVALID_CODE"));
            }

            // Confirm email
            var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            var result = await _userManager.ConfirmEmailAsync(user, token);

            if (result.Succeeded)
            {
                // Remove code from cache
                _memoryCache.Remove(cacheKey);

                return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "EmailVerifiedSuccessfully", CurrentCulture)));
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
    public async Task<ActionResult<ApiResponse<object>>> ResendVerificationCode([FromBody] ResendVerificationCodeDto dto)
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
                return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "CodeResentMessage", culture)));
            }

            // Check if email is already confirmed
            if (await _userManager.IsEmailConfirmedAsync(user))
            {
                return BadRequest(new ApiResponse<object>(LocalizationService.GetLocalizedString(ResourceName, "EmailAlreadyConfirmed", culture), "EMAIL_ALREADY_CONFIRMED"));
            }

            // Send new verification code with language preference
            await _authService.SendVerificationCodeAsync(user.Email!, user.FullName, languageToUse);

            return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "CodeResentSuccessfully", CurrentCulture)));
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

    // Keep the old endpoint for backward compatibility (if needed)
    [HttpGet("confirm-email")]
    public async Task<IActionResult> ConfirmEmail(string token, string email)
    {
        var user = await _userManager.FindByEmailAsync(email);
        if (user == null)
            return BadRequest("Invalid email confirmation request.");

        var result = await _userManager.ConfirmEmailAsync(user, token);
        if (result.Succeeded)
            return Ok("Email confirmed successfully!");

        return BadRequest("Error confirming email.");
    }

    /// <summary>
    /// Şifre sıfırlama linki gönderir
    /// </summary>
    /// <param name="dto">Email bilgisi</param>
    /// <returns>Gönderme sonucu</returns>
    [HttpPost("forgot-password")]
    public async Task<ActionResult<ApiResponse<object>>> ForgotPassword([FromBody] ForgotPasswordDto dto)
    {
        try
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null)
            {
                // Don't reveal if user exists or not for security
                return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "PasswordResetSent", CurrentCulture)));
            }

            var token = await _userManager.GeneratePasswordResetTokenAsync(user);

            await _emailSender.SendEmailAsync(new EmailTemplateRequest
            {
                To = user.Email!,
                Subject = "Parolayı sıfırla", // TODO: Localize this too
                TemplateName = EmailTemplateNames.ResetPassword,
                Variables = new Dictionary<string, string>
                {
                    ["fullName"] = string.IsNullOrWhiteSpace(user.FullName) ? user.Email! : user.FullName,
                    ["resetToken"] = token
                }
            });

            return Ok(new ApiResponse<object>(new { }, LocalizationService.GetLocalizedString(ResourceName, "PasswordResetSent", CurrentCulture)));
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
    /// Kullanıcı girişi yapar ve JWT token döndürür
    /// </summary>
    /// <param name="dto">Giriş bilgileri</param>
    /// <returns>JWT token ve kullanıcı bilgileri</returns>
    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<LoginResponseDto>>> Login(LoginDto dto)
    {
        try
        {
            var loginResponse = await _authService.LoginAsync(dto, null);
            return Ok(new ApiResponse<LoginResponseDto>(loginResponse, LocalizationService.GetLocalizedString(ResourceName, "LoginSuccess", CurrentCulture)));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new ApiResponse<LoginResponseDto>(ex.Message, "INVALID_CREDENTIALS"));
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(500, new ApiResponse<LoginResponseDto>(ex.Message, "LOGIN_ERROR"));
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
            return BadRequest(new ApiResponse<LoginResponseDto>(LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture), "INVALID_REQUEST"));

        string? accessToken = dto.Token;
        string? refreshToken = dto.RefreshToken;

        var principal = _authService.GetPrincipalFromExpiredToken(accessToken);
        if (principal == null)
            return BadRequest(new ApiResponse<LoginResponseDto>(LocalizationService.GetLocalizedString(ResourceName, "InvalidToken", CurrentCulture), "INVALID_TOKEN"));

        var email = principal.FindFirstValue(ClaimTypes.Email) ?? principal.FindFirstValue(JwtRegisteredClaimNames.Email);
        if (email == null)
            return BadRequest(new ApiResponse<LoginResponseDto>(LocalizationService.GetLocalizedString(ResourceName, "InvalidToken", CurrentCulture), "INVALID_TOKEN"));

        var user = await _userManager.FindByEmailAsync(email);

        if (user == null || user.RefreshToken != refreshToken || user.RefreshTokenExpiryTime <= DateTime.UtcNow)
            return BadRequest(new ApiResponse<LoginResponseDto>(LocalizationService.GetLocalizedString(ResourceName, "InvalidToken", CurrentCulture), "INVALID_TOKEN"));

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

        return Ok(new ApiResponse<LoginResponseDto>(loginResponse, LocalizationService.GetLocalizedString(ResourceName, "TokenRefreshSuccess", CurrentCulture)));
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
                return BadRequest(new ApiResponse<LoginResponseDto>(LocalizationService.GetLocalizedString(ResourceName, "InvalidProvider", CurrentCulture), "INVALID_PROVIDER"));
            }

            // For now, we trust the token from mobile app
            // In production, you should verify the token with the provider's API
            // Example: For Google, verify with https://oauth2.googleapis.com/tokeninfo?id_token={token}

            if (string.IsNullOrEmpty(dto.Email))
            {
                return BadRequest(new ApiResponse<LoginResponseDto>(LocalizationService.GetLocalizedString(ResourceName, "EmailRequired", CurrentCulture), "EMAIL_REQUIRED"));
            }

            // Check if user exists
            var user = await _userManager.FindByEmailAsync(dto.Email);

            if (user == null)
            {
                // Create new user
                user = new AppUser
                {
                    UserName = dto.Email,
                    Email = dto.Email,
                    FullName = dto.FullName ?? dto.Email,
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

                Logger.LogInformation($"New user created via {dto.Provider}: {dto.Email}");
            }
            else
            {
                // User exists, just log them in
                Logger.LogInformation($"Existing user logged in via {dto.Provider}: {dto.Email}");
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

            return Ok(new ApiResponse<LoginResponseDto>(loginResponse, LocalizationService.GetLocalizedString(ResourceName, "LoginSuccess", CurrentCulture)));
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
}
