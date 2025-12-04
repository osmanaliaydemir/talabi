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
using Talabi.Core.Interfaces;
using Talabi.Core.Services;

namespace Talabi.Api.Controllers;

/// <summary>
/// Kimlik doğrulama ve yetkilendirme işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly UserManager<AppUser> _userManager;
    private readonly SignInManager<AppUser> _signInManager;
    private readonly IConfiguration _configuration;
    private readonly IEmailSender _emailSender;
    private readonly IMemoryCache _memoryCache;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<AuthController> _logger;
    private const int VerificationCodeExpirationMinutes = 3;

    /// <summary>
    /// AuthController constructor
    /// </summary>
    public AuthController(UserManager<AppUser> userManager, SignInManager<AppUser> signInManager, IConfiguration configuration,
        IEmailSender emailSender, IMemoryCache memoryCache, IUnitOfWork unitOfWork, ILogger<AuthController> logger)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _configuration = configuration;
        _emailSender = emailSender;
        _memoryCache = memoryCache;
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    private static string GenerateVerificationCode()
    {
        var random = new Random();
        return random.Next(1000, 9999).ToString(); // 4 haneli kod
    }

    private string GetLanguageFromRequest(string? languageFromDto = null)
    {
        // Priority: 1. DTO'da belirtilen dil, 2. Accept-Language header, 3. Default (tr)
        if (!string.IsNullOrWhiteSpace(languageFromDto))
        {
            return NormalizeLanguageCode(languageFromDto);
        }

        // Check Accept-Language header
        if (Request.Headers.TryGetValue("Accept-Language", out var acceptLanguage))
        {
            var languages = acceptLanguage.ToString().Split(',');
            if (languages.Length > 0)
            {
                var primaryLanguage = languages[0].Split(';')[0].Trim().ToLowerInvariant();
                return NormalizeLanguageCode(primaryLanguage);
            }
        }

        return "tr"; // Default
    }

    private static string NormalizeLanguageCode(string? languageCode)
    {
        if (string.IsNullOrWhiteSpace(languageCode))
        {
            return "tr";
        }

        var normalized = languageCode.ToLowerInvariant().Trim();

        return normalized switch
        {
            "tr" or "turkish" or "tr-tr" or "tr-TR" => "tr",
            "en" or "english" or "en-us" or "en-US" or "en-gb" or "en-GB" => "en",
            "ar" or "arabic" or "ar-sa" or "ar-SA" => "ar",
            _ => "tr" // Default fallback
        };
    }

    private string GetEmailSubject(string languageCode)
    {
        return languageCode switch
        {
            "en" => "Talabi - Email Verification Code",
            "ar" => "Talabi - رمز التحقق من البريد الإلكتروني",
            _ => "Talabi - Email Doğrulama Kodu" // Default Turkish
        };
    }

    private async Task SendVerificationCodeAsync(string email, string? fullName, string? languageCode = null)
    {
        var code = GenerateVerificationCode();
        var cacheKey = $"verification_code_{email}";
        var cacheOptions = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(VerificationCodeExpirationMinutes)
        };

        _memoryCache.Set(cacheKey, code, cacheOptions);

        // Determine language
        var lang = GetLanguageFromRequest(languageCode);

        await _emailSender.SendEmailAsync(new EmailTemplateRequest
        {
            To = email,
            Subject = GetEmailSubject(lang),
            TemplateName = EmailTemplateNames.VerificationCode,
            LanguageCode = lang,
            Variables = new Dictionary<string, string>
            {
                ["fullName"] = string.IsNullOrWhiteSpace(fullName) ? email : fullName,
                ["verificationCode"] = code
            }
        });
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
            // ÖNCE KULLANICI VAR MI KONTROL ET - Varsa email gönderme
            var existingUser = await _userManager.FindByEmailAsync(dto.Email);
            if (existingUser != null)
            {
                // Kullanıcı zaten var, ancak email doğrulanmamış olabilir
                if (await _userManager.IsEmailConfirmedAsync(existingUser))
                {
                    return BadRequest(new ApiResponse<object>(
                        "Bu email adresi ile zaten bir hesap bulunmaktadır.",
                        "DuplicateEmail"
                    ));
                }
                else
                {
                    // Email doğrulanmamış, yeni kod gönder
                    try
                    {
                        await SendVerificationCodeAsync(dto.Email, dto.FullName, dto.Language);
                        return Ok(new ApiResponse<object>(
                            new { Email = dto.Email },
                            "Email adresinize yeni doğrulama kodu gönderildi. Lütfen email'inizi kontrol edin."
                        ));
                    }
                    catch (Exception emailEx)
                    {
                        _logger.LogError(emailEx, "Email gönderimi başarısız. Email: {Email}", dto.Email);
                        return BadRequest(new ApiResponse<object>(
                            "Doğrulama kodu gönderilemedi. Lütfen daha sonra tekrar deneyin.",
                            "Email gönderimi başarısız"
                        ));
                    }
                }
            }

            // Kullanıcı yok, şimdi email göndermeyi dene
            try
            {
                // Email göndermeyi dene (kullanıcı henüz oluşturulmadan)
                await SendVerificationCodeAsync(dto.Email, dto.FullName, dto.Language);
            }
            catch (Exception emailEx)
            {
                // Email gönderilemezse kullanıcıyı oluşturma ve hata döndür
                _logger.LogError(emailEx, "Email gönderimi başarısız. Email: {Email}", dto.Email);

                return BadRequest(new ApiResponse<object>(
                    "Doğrulama kodu gönderilemedi. Lütfen email adresinizi kontrol edin veya daha sonra tekrar deneyin.",
                    "Email gönderimi başarısız",
                    new List<string> { emailEx.Message }
                ));
            }

            // Email başarıyla gönderildi, şimdi kullanıcıyı oluştur
            var user = new AppUser { UserName = dto.Email, Email = dto.Email, FullName = dto.FullName };
            var result = await _userManager.CreateAsync(user, dto.Password);

            if (result.Succeeded)
            {
                try
                {
                    // Assign Customer role
                    await _userManager.AddToRoleAsync(user, "Customer");

                    // Create Customer entity
                    var customer = new Customer
                    {
                        UserId = user.Id
                    };
                    await _unitOfWork.Customers.AddAsync(customer);
                    await _unitOfWork.SaveChangesAsync();

                    return Ok(new ApiResponse<object>(
                        new { Email = user.Email },
                        "Kullanıcı başarıyla oluşturuldu. Email adresinize gönderilen 4 haneli kodu giriniz."
                    ));
                }
                catch (Exception dbEx)
                {
                    // Kullanıcı oluşturuldu ama Customer entity veya role ataması başarısız
                    // Email zaten gönderildi, kullanıcı var, sadece eksik kısımları tamamlamak lazım
                    var innerExceptionMessage = dbEx.InnerException?.Message ?? dbEx.Message;
                    _logger.LogError(dbEx, "Kullanıcı oluşturuldu ancak Customer entity veya role ataması başarısız. UserId: {UserId}, InnerException: {InnerException}",
                        user.Id, innerExceptionMessage);

                    // Kullanıcıyı sil (rollback)
                    await _userManager.DeleteAsync(user);

                    return StatusCode(500, new ApiResponse<object>(
                        "Kullanıcı oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.",
                        "DATABASE_ERROR",
                        new List<string> { innerExceptionMessage }
                    ));
                }
            }

            // Kullanıcı oluşturulamadı ama email gönderildi - cache'den kodu temizle
            var cacheKey = $"verification_code_{dto.Email}";
            _memoryCache.Remove(cacheKey);

            var errorMessages = result.Errors.Select(e => e.Description).ToList();
            return BadRequest(new ApiResponse<object>(
                "Kullanıcı oluşturulamadı",
                "USER_CREATION_FAILED",
                errorMessages
            ));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Register işlemi sırasında beklenmeyen hata. Email: {Email}", dto.Email);

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
            // ÖNCE KULLANICI VAR MI KONTROL ET
            var existingUser = await _userManager.FindByEmailAsync(dto.Email);
            if (existingUser != null)
            {
                if (await _userManager.IsEmailConfirmedAsync(existingUser))
                {
                    return BadRequest(new ApiResponse<object>(
                        "Bu email adresi ile zaten bir hesap bulunmaktadır.",
                        "DuplicateEmail"
                    ));
                }
                else
                {
                    // Email doğrulanmamış, yeni kod gönder
                    try
                    {
                        await SendVerificationCodeAsync(dto.Email, dto.FullName, dto.Language);
                        return Ok(new ApiResponse<object>(
                            new { Email = dto.Email },
                            "Email adresinize yeni doğrulama kodu gönderildi. Lütfen email'inizi kontrol edin."
                        ));
                    }
                    catch (Exception emailEx)
                    {
                        _logger.LogError(emailEx, "Email gönderimi başarısız. Email: {Email}", dto.Email);
                        return BadRequest(new ApiResponse<object>(
                            "Doğrulama kodu gönderilemedi. Lütfen daha sonra tekrar deneyin.",
                            "Email gönderimi başarısız"
                        ));
                    }
                }
            }

            // Kullanıcı yok, email göndermeyi dene
            try
            {
                await SendVerificationCodeAsync(dto.Email, dto.FullName, dto.Language);
            }
            catch (Exception emailEx)
            {
                _logger.LogError(emailEx, "Email gönderimi başarısız. Email: {Email}", dto.Email);
                return BadRequest(new ApiResponse<object>(
                    "Doğrulama kodu gönderilemedi. Lütfen email adresinizi kontrol edin.",
                    "Email gönderimi başarısız",
                    new List<string> { emailEx.Message }
                ));
            }

            // Email başarıyla gönderildi, kullanıcıyı oluştur
            var user = new AppUser
            {
                UserName = dto.Email,
                Email = dto.Email,
                FullName = dto.FullName,
                Role = Talabi.Core.Enums.UserRole.Vendor
            };
            var result = await _userManager.CreateAsync(user, dto.Password);

            if (result.Succeeded)
            {
                try
                {
                    // Assign Vendor role
                    await _userManager.AddToRoleAsync(user, "Vendor");

                    // Create Vendor entity
                    var vendor = new Vendor
                    {
                        OwnerId = user.Id,
                        Name = dto.BusinessName,
                        PhoneNumber = dto.Phone,
                        Address = dto.Address ?? string.Empty,
                        City = dto.City,
                        Description = dto.Description,
                        IsActive = false // Admin onayı bekleyecek
                    };
                    await _unitOfWork.Vendors.AddAsync(vendor);
                    await _unitOfWork.SaveChangesAsync();

                    return Ok(new ApiResponse<object>(
                        new { Email = user.Email },
                        "Satıcı hesabı başarıyla oluşturuldu. Email adresinize gönderilen 4 haneli kodu giriniz."
                    ));
                }
                catch (Exception dbEx)
                {
                    var innerExceptionMessage = dbEx.InnerException?.Message ?? dbEx.Message;
                    _logger.LogError(dbEx, "Vendor oluşturulurken hata. UserId: {UserId}, InnerException: {InnerException}",
                        user.Id, innerExceptionMessage);

                    // Kullanıcıyı sil (rollback)
                    await _userManager.DeleteAsync(user);

                    return StatusCode(500, new ApiResponse<object>(
                        "Satıcı hesabı oluşturulurken bir hata oluştu. Lütfen tekrar deneyin.",
                        "DATABASE_ERROR",
                        new List<string> { innerExceptionMessage }
                    ));
                }
            }

            // Kullanıcı oluşturulamadı - cache'den kodu temizle
            var cacheKey = $"verification_code_{dto.Email}";
            _memoryCache.Remove(cacheKey);

            var errorMessages = result.Errors.Select(e => e.Description).ToList();
            return BadRequest(new ApiResponse<object>(
                "Satıcı hesabı oluşturulamadı",
                "VENDOR_CREATION_FAILED",
                errorMessages
            ));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "VendorRegister işlemi sırasında beklenmeyen hata. Email: {Email}", dto.Email);

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
                return BadRequest(new ApiResponse<object>("Kullanıcı bulunamadı.", "USER_NOT_FOUND"));
            }

            // Check if email is already confirmed
            if (await _userManager.IsEmailConfirmedAsync(user))
            {
                return BadRequest(new ApiResponse<object>("Email adresi zaten doğrulanmış.", "EMAIL_ALREADY_CONFIRMED"));
            }

            var cacheKey = $"verification_code_{dto.Email}";
            if (!_memoryCache.TryGetValue(cacheKey, out string? cachedCode))
            {
                return BadRequest(new ApiResponse<object>("Doğrulama kodu süresi dolmuş veya geçersiz.", "CODE_EXPIRED"));
            }

            if (cachedCode != dto.Code)
            {
                return BadRequest(new ApiResponse<object>("Doğrulama kodu hatalı.", "INVALID_CODE"));
            }

            // Confirm email
            var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
            var result = await _userManager.ConfirmEmailAsync(user, token);

            if (result.Succeeded)
            {
                // Remove code from cache
                _memoryCache.Remove(cacheKey);

                return Ok(new ApiResponse<object>(new { }, "Email adresi başarıyla doğrulandı."));
            }

            var errorMessages = result.Errors.Select(e => e.Description).ToList();
            return BadRequest(new ApiResponse<object>(
                "Email doğrulama başarısız.",
                "EMAIL_VERIFICATION_FAILED",
                errorMessages
            ));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                "Doğrulama sırasında bir hata oluştu",
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
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null)
            {
                // Don't reveal if user exists or not for security
                return Ok(new ApiResponse<object>(new { }, "Eğer bu email adresi kayıtlıysa, doğrulama kodu gönderildi."));
            }

            // Check if email is already confirmed
            if (await _userManager.IsEmailConfirmedAsync(user))
            {
                return BadRequest(new ApiResponse<object>("Email adresi zaten doğrulanmış.", "EMAIL_ALREADY_CONFIRMED"));
            }

            // Try to get language from UserPreferences if user has preferences
            string? userLanguage = null;
            var userPreferences = await _unitOfWork.UserPreferences.Query()
                .FirstOrDefaultAsync(up => up.UserId == user.Id);

            if (userPreferences != null)
            {
                userLanguage = userPreferences.Language;
            }

            // Priority: DTO Language > UserPreferences > Accept-Language > Default
            var languageToUse = dto.Language ?? userLanguage;

            // Send new verification code with language preference
            await SendVerificationCodeAsync(user.Email!, user.FullName, languageToUse);

                return Ok(new ApiResponse<object>(new { }, "Doğrulama kodu yeniden gönderildi."));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                "Kod gönderme sırasında bir hata oluştu",
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
                return Ok(new ApiResponse<object>(new { }, "If the email exists, a password reset link has been sent."));
            }

            var token = await _userManager.GeneratePasswordResetTokenAsync(user);

            await _emailSender.SendEmailAsync(new EmailTemplateRequest
            {
                To = user.Email!,
                Subject = "Parolayı sıfırla",
                TemplateName = EmailTemplateNames.ResetPassword,
                Variables = new Dictionary<string, string>
                {
                    ["fullName"] = string.IsNullOrWhiteSpace(user.FullName) ? user.Email! : user.FullName,
                    ["resetToken"] = token
                }
            });

            return Ok(new ApiResponse<object>(new { }, "If the email exists, a password reset link has been sent."));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>(
                "An error occurred",
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
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null)
            {
                return Unauthorized(new ApiResponse<LoginResponseDto>("Invalid email or password", "INVALID_CREDENTIALS"));
            }

            // Check if email is confirmed
            if (!await _userManager.IsEmailConfirmedAsync(user))
            {
                return Unauthorized(new ApiResponse<LoginResponseDto>("Email not confirmed. Please check your email.", "EMAIL_NOT_CONFIRMED"));
            }

            // Check if password hash is valid before attempting to verify
            if (string.IsNullOrEmpty(user.PasswordHash))
            {
                return Unauthorized(new ApiResponse<LoginResponseDto>("Account password not set. Please reset your password.", "PASSWORD_NOT_SET"));
            }

            var result = await _signInManager.CheckPasswordSignInAsync(user, dto.Password, false);

            if (result.Succeeded)
            {
                var token = await GenerateJwtToken(user);
                var refreshToken = GenerateRefreshToken();

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
                    Role = user.Role.ToString()
                };

                return Ok(new ApiResponse<LoginResponseDto>(loginResponse, "Giriş başarılı"));
            }

            return Unauthorized(new ApiResponse<LoginResponseDto>("Invalid email or password", "INVALID_CREDENTIALS"));
        }
        catch (FormatException ex) when (ex.Message.Contains("Base-64"))
        {
            // Password hash is corrupted - reset the password
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user != null)
            {
                // Remove the old password hash and set a new one
                var resetToken = await _userManager.GeneratePasswordResetTokenAsync(user);
                var resetResult = await _userManager.ResetPasswordAsync(user, resetToken, dto.Password);

                if (resetResult.Succeeded)
                {
                    // Try login again
                    var loginResult = await _signInManager.CheckPasswordSignInAsync(user, dto.Password, false);
                    if (loginResult.Succeeded)
                    {
                        var token = await GenerateJwtToken(user);
                        var refreshToken = GenerateRefreshToken();

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
                            Role = user.Role.ToString()
                        };

                        return Ok(new ApiResponse<LoginResponseDto>(loginResponse, "Giriş başarılı"));
                    }
                }
            }

            return StatusCode(500, new ApiResponse<LoginResponseDto>(
                "Account password is corrupted. Please contact support or register a new account.",
                "PASSWORD_CORRUPTED"
            ));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<LoginResponseDto>(
                "An error occurred during login",
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
            return BadRequest(new ApiResponse<LoginResponseDto>("Invalid client request", "INVALID_REQUEST"));

        string? accessToken = dto.Token;
        string? refreshToken = dto.RefreshToken;

        var principal = GetPrincipalFromExpiredToken(accessToken);
        if (principal == null)
            return BadRequest(new ApiResponse<LoginResponseDto>("Invalid access token or refresh token", "INVALID_TOKEN"));

        var email = principal.FindFirstValue(ClaimTypes.Email) ?? principal.FindFirstValue(JwtRegisteredClaimNames.Email);
        if (email == null)
            return BadRequest(new ApiResponse<LoginResponseDto>("Invalid access token or refresh token", "INVALID_TOKEN"));

        var user = await _userManager.FindByEmailAsync(email);

        if (user == null || user.RefreshToken != refreshToken || user.RefreshTokenExpiryTime <= DateTime.UtcNow)
            return BadRequest(new ApiResponse<LoginResponseDto>("Invalid access token or refresh token", "INVALID_TOKEN"));

        var newAccessToken = await GenerateJwtToken(user);
        var newRefreshToken = GenerateRefreshToken();

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

        return Ok(new ApiResponse<LoginResponseDto>(loginResponse, "Token başarıyla yenilendi"));
    }

    private async Task<string> GenerateJwtToken(AppUser user)
    {
        var jwtSettings = _configuration.GetSection("JwtSettings");
        var secret = jwtSettings["Secret"];
        var issuer = jwtSettings["Issuer"];
        var audience = jwtSettings["Audience"];
        var expirationMinutes = int.Parse(jwtSettings["ExpirationInMinutes"]!);

        // Get user roles
        var roles = await _userManager.GetRolesAsync(user);

        var claims = new List<Claim>
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id),
            new Claim(JwtRegisteredClaimNames.Email, user.Email!),
            new Claim(ClaimTypes.Email, user.Email!), // Standard ClaimType for easier extraction
            new Claim(ClaimTypes.MobilePhone, user.PhoneNumber ?? string.Empty),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim("fullName", user.FullName),
            new Claim("role", user.Role.ToString())
        };

        // Add role claims
        foreach (var role in roles)
        {
            claims.Add(new Claim(System.Security.Claims.ClaimTypes.Role, role));
        }

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: issuer,
            audience: audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expirationMinutes),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static string GenerateRefreshToken()
    {
        var randomNumber = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }

    private ClaimsPrincipal? GetPrincipalFromExpiredToken(string? token)
    {
        var jwtSettings = _configuration.GetSection("JwtSettings");
        var secret = jwtSettings["Secret"];

        var tokenValidationParameters = new TokenValidationParameters
        {
            ValidateAudience = false,
            ValidateIssuer = false,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret!)),
            ValidateLifetime = false // Here we are validating that the token is expired, so we don't care about lifetime
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var principal = tokenHandler.ValidateToken(token, tokenValidationParameters, out SecurityToken securityToken);

        if (securityToken is not JwtSecurityToken jwtSecurityToken || !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256, StringComparison.InvariantCultureIgnoreCase))
            throw new SecurityTokenException("Invalid token");

        return principal;
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
                return BadRequest(new ApiResponse<LoginResponseDto>("Invalid provider", "INVALID_PROVIDER"));
            }

            // For now, we trust the token from mobile app
            // In production, you should verify the token with the provider's API
            // Example: For Google, verify with https://oauth2.googleapis.com/tokeninfo?id_token={token}

            if (string.IsNullOrEmpty(dto.Email))
            {
                return BadRequest(new ApiResponse<LoginResponseDto>("Email is required", "EMAIL_REQUIRED"));
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
                await _unitOfWork.Customers.AddAsync(customer);
                await _unitOfWork.SaveChangesAsync();

                _logger.LogInformation($"New user created via {dto.Provider}: {dto.Email}");
            }
            else
            {
                // User exists, just log them in
                _logger.LogInformation($"Existing user logged in via {dto.Provider}: {dto.Email}");
            }

            // Generate JWT token
            var token = await GenerateJwtToken(user);
            var refreshToken = GenerateRefreshToken();

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

            return Ok(new ApiResponse<LoginResponseDto>(loginResponse, "Giriş başarılı"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"External login failed for provider: {dto.Provider}");
            return StatusCode(500, new ApiResponse<LoginResponseDto>(
                "External login failed",
                "INTERNAL_ERROR",
                new List<string> { ex.Message }
            ));
        }
    }
}
