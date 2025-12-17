using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Email;
using Talabi.Core.Email;
using Talabi.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Core.Services;

namespace Talabi.Infrastructure.Services;

/// <summary>
/// Authentication işlemleri için service implementation
/// </summary>
public class AuthService : IAuthService
{
    private readonly UserManager<AppUser> _userManager;
    private readonly SignInManager<AppUser> _signInManager;
    private readonly IConfiguration _configuration;
    private readonly IEmailSender _emailSender;
    private readonly IMemoryCache _memoryCache;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<AuthService> _logger;
    private readonly ILocalizationService _localizationService;
    private const int VerificationCodeExpirationMinutes = 3;
    private const string ResourceName = "AuthResources";

    public AuthService(
        UserManager<AppUser> userManager,
        SignInManager<AppUser> signInManager,
        IConfiguration configuration,
        IEmailSender emailSender,
        IMemoryCache memoryCache,
        IUnitOfWork unitOfWork,
        ILogger<AuthService> logger,
        ILocalizationService localizationService)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _configuration = configuration;
        _emailSender = emailSender;
        _memoryCache = memoryCache;
        _unitOfWork = unitOfWork;
        _logger = logger;
        _localizationService = localizationService;
    }

    /// <summary>
    /// JWT token üretir
    /// </summary>
    public async Task<string> GenerateJwtTokenAsync(AppUser user)
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

        // Determine IsActive status
        bool isActive = true; // Default for Customer and Admin
        bool isProfileComplete = true; // Default

        if (user.Role == UserRole.Vendor)
        {
            var vendor = await _unitOfWork.Vendors.Query().FirstOrDefaultAsync(v => v.OwnerId == user.Id);
            if (vendor != null)
            {
                isActive = vendor.IsActive;
                isProfileComplete = !string.IsNullOrWhiteSpace(vendor.Address) &&
                                    vendor.Latitude.HasValue &&
                                    vendor.Longitude.HasValue &&
                                    !string.IsNullOrWhiteSpace(vendor.Name);
            }
        }
        else if (user.Role == UserRole.Courier)
        {
            var courier = await _unitOfWork.Couriers.Query().FirstOrDefaultAsync(c => c.UserId == user.Id);
            if (courier != null) isActive = courier.IsActive;
        }

        claims.Add(new Claim("isActive", isActive.ToString().ToLowerInvariant()));
        claims.Add(new Claim("isProfileComplete", isProfileComplete.ToString().ToLowerInvariant()));

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

    /// <summary>
    /// Refresh token üretir
    /// </summary>
    public string GenerateRefreshToken()
    {
        var randomNumber = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }

    /// <summary>
    /// Expired token'dan principal çıkarır
    /// </summary>
    public ClaimsPrincipal? GetPrincipalFromExpiredToken(string? token)
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
    /// Email doğrulama kodu gönderir
    /// </summary>
    public async Task SendVerificationCodeAsync(string email, string? fullName, string? languageCode)
    {
        var code = GenerateVerificationCode();
        var cacheKey = $"verification_code_{email}";
        var cacheOptions = new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(VerificationCodeExpirationMinutes)
        };

        _memoryCache.Set(cacheKey, code, cacheOptions);

        // Normalize language code
        var lang = NormalizeLanguageCode(languageCode);

        var culture = new CultureInfo(lang);
        var subject = _localizationService.GetLocalizedString(ResourceName, "EmailVerificationSubject", culture);

        await _emailSender.SendEmailAsync(new EmailTemplateRequest
        {
            To = email,
            Subject = subject,
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
    /// Kullanıcı girişi yapar
    /// </summary>
    public async Task<LoginResponseDto> LoginAsync(LoginDto dto, string? languageCode)
    {
        // Determine culture from languageCode
        var culture = string.IsNullOrEmpty(languageCode)
            ? CultureInfo.CurrentCulture
            : new CultureInfo(languageCode);

        var user = await _userManager.FindByEmailAsync(dto.Email);
        if (user == null)
        {
            var errorMessage = _localizationService.GetLocalizedString(ResourceName, "InvalidCredentials", culture);
            throw new UnauthorizedAccessException(errorMessage);
        }

        // Check if email is confirmed
        if (!await _userManager.IsEmailConfirmedAsync(user))
        {
            var errorMessage = _localizationService.GetLocalizedString(ResourceName, "EmailNotConfirmed", culture);
            throw new UnauthorizedAccessException(errorMessage);
        }

        // Check if password hash is valid before attempting to verify
        if (string.IsNullOrEmpty(user.PasswordHash))
        {
            var errorMessage = _localizationService.GetLocalizedString(ResourceName, "PasswordNotSet", culture);
            throw new UnauthorizedAccessException(errorMessage);
        }

        var result = await _signInManager.CheckPasswordSignInAsync(user, dto.Password, false);

        if (result.Succeeded)
        {
            var token = await GenerateJwtTokenAsync(user);
            var refreshToken = GenerateRefreshToken();

            user.RefreshToken = refreshToken;
            user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(7);
            await _userManager.UpdateAsync(user);

            var response = new LoginResponseDto
            {
                Token = token,
                RefreshToken = refreshToken,
                UserId = user.Id,
                Email = user.Email!,
                FullName = user.FullName,
                Role = user.Role.ToString(),
                IsActive = true // Default
            };

            // Check specific role active status
            if (user.Role == UserRole.Vendor)
            {
                var vendor = await _unitOfWork.Vendors.Query().FirstOrDefaultAsync(v => v.OwnerId == user.Id);
                if (vendor != null)
                {
                    response.IsActive = vendor.IsActive;
                    // Check profile completeness (Address, Lat, Lng, Name required)
                    response.IsProfileComplete = !string.IsNullOrWhiteSpace(vendor.Address) &&
                                                 vendor.Latitude.HasValue &&
                                                 vendor.Longitude.HasValue &&
                                                 !string.IsNullOrWhiteSpace(vendor.Name) &&
                                                 !string.IsNullOrWhiteSpace(vendor.PhoneNumber);
                }
            }
            else if (user.Role == UserRole.Courier)
            {
                var courier = await _unitOfWork.Couriers.Query().FirstOrDefaultAsync(c => c.UserId == user.Id);
                if (courier != null) response.IsActive = courier.IsActive;
            }

            return response;
        }

        // Handle locked out account
        if (result.IsLockedOut)
        {
            var errorMessage = _localizationService.GetLocalizedString(ResourceName, "AccountLockedOut", culture);
            throw new InvalidOperationException(errorMessage);
        }

        // Invalid password - return same message as invalid user for security
        var invalidCredsMessage = _localizationService.GetLocalizedString(ResourceName, "InvalidCredentials", culture);
        throw new UnauthorizedAccessException(invalidCredsMessage);
    }

    /// <summary>
    /// Yeni kullanıcı kaydı oluşturur
    /// </summary>
    public async Task<object> RegisterAsync(RegisterDto dto, CultureInfo culture)
    {
        // Check if user exists
        var existingUser = await _userManager.FindByEmailAsync(dto.Email);
        if (existingUser != null)
        {
            if (await _userManager.IsEmailConfirmedAsync(existingUser))
            {
                throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "DuplicateEmail", culture));
            }
            else
            {
                // Email not confirmed, send new code
                await SendVerificationCodeAsync(dto.Email, dto.FullName, dto.Language);
                return new { Email = dto.Email };
            }
        }

        // Send verification code
        try
        {
            await SendVerificationCodeAsync(dto.Email, dto.FullName, dto.Language);
        }
        catch (Exception emailEx)
        {
            _logger.LogError(emailEx, "Email gönderimi başarısız. Email: {Email}", dto.Email);
            throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "EmailSendFailedWithDetails", culture));
        }

        // Create user
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

                return new { Email = user.Email };
            }
            catch (Exception dbEx)
            {
                _logger.LogError(dbEx, "Kullanıcı oluşturuldu ancak Customer entity veya role ataması başarısız. UserId: {UserId}", user.Id);

                // Rollback - delete user
                await _userManager.DeleteAsync(user);

                // Clear verification code cache
                var cacheKey = $"verification_code_{dto.Email}";
                _memoryCache.Remove(cacheKey);

                throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "UserCreationError", culture));
            }
        }

        // User creation failed - clear verification code cache
        var cacheKey2 = $"verification_code_{dto.Email}";
        _memoryCache.Remove(cacheKey2);

        var errorMessages = result.Errors.Select(e => e.Description).ToList();
        throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "UserCreationFailed", culture));
    }

    /// <summary>
    /// Vendor kaydı oluşturur
    /// </summary>
    public async Task<object> VendorRegisterAsync(VendorRegisterDto dto, CultureInfo culture)
    {
        // Check if user exists
        var existingUser = await _userManager.FindByEmailAsync(dto.Email);
        if (existingUser != null)
        {
            if (await _userManager.IsEmailConfirmedAsync(existingUser))
            {
                throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "DuplicateEmail", culture));
            }
            else
            {
                // Email not confirmed, send new code
                await SendVerificationCodeAsync(dto.Email, dto.FullName, dto.Language);
                return new { Email = dto.Email };
            }
        }

        // Send verification code
        try
        {
            await SendVerificationCodeAsync(dto.Email, dto.FullName, dto.Language);
        }
        catch (Exception emailEx)
        {
            _logger.LogError(emailEx, "Email gönderimi başarısız. Email: {Email}", dto.Email);
            throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "EmailSendFailedWithDetails", culture));
        }

        // Create user
        var user = new AppUser
        {
            UserName = dto.Email,
            Email = dto.Email,
            FullName = dto.FullName,
            Role = UserRole.Vendor
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
                    Type = dto.VendorType,
                    Name = dto.BusinessName,
                    PhoneNumber = dto.Phone,
                    Address = dto.Address ?? string.Empty,
                    City = dto.City,
                    Description = dto.Description,
                    IsActive = false // Admin onayı bekleyecek
                };
                await _unitOfWork.Vendors.AddAsync(vendor);
                await _unitOfWork.SaveChangesAsync();

                return new { Email = user.Email };
            }
            catch (Exception dbEx)
            {
                _logger.LogError(dbEx, "Vendor oluşturulurken hata. UserId: {UserId}", user.Id);

                // Rollback - delete user
                await _userManager.DeleteAsync(user);

                // Clear verification code cache
                var cacheKey = $"verification_code_{dto.Email}";
                _memoryCache.Remove(cacheKey);

                throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "VendorCreationError", culture));
            }
        }

        // User creation failed - clear verification code cache
        var cacheKey2 = $"verification_code_{dto.Email}";
        _memoryCache.Remove(cacheKey2);

        var errorMessages = result.Errors.Select(e => e.Description).ToList();
        throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "VendorCreationFailed", culture));
    }

    /// <summary>
    /// Courier kaydı oluşturur
    /// </summary>
    public async Task<object> CourierRegisterAsync(CourierRegisterDto dto, CultureInfo culture)
    {
        // Check if user exists
        var existingUser = await _userManager.FindByEmailAsync(dto.Email);
        if (existingUser != null)
        {
            if (await _userManager.IsEmailConfirmedAsync(existingUser))
            {
                throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "DuplicateEmail", culture));
            }
            else
            {
                // Email not confirmed, send new code
                await SendVerificationCodeAsync(dto.Email, dto.FullName, dto.Language);
                return new { Email = dto.Email };
            }
        }

        // Send verification code
        try
        {
            await SendVerificationCodeAsync(dto.Email, dto.FullName, dto.Language);
        }
        catch (Exception emailEx)
        {
            _logger.LogError(emailEx, "Email gönderimi başarısız. Email: {Email}", dto.Email);
            throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "EmailSendFailedWithDetails", culture));
        }

        // Create user
        var user = new AppUser
        {
            UserName = dto.Email,
            Email = dto.Email,
            FullName = dto.FullName,
            PhoneNumber = dto.Phone,
            Role = UserRole.Courier
        };
        var result = await _userManager.CreateAsync(user, dto.Password);

        if (result.Succeeded)
        {
            try
            {
                // Assign Courier role
                await _userManager.AddToRoleAsync(user, "Courier");

                // Create Courier entity
                var courier = new Courier
                {
                    UserId = user.Id,
                    Name = dto.FullName,
                    PhoneNumber = dto.Phone,
                    VehicleType = dto.VehicleType,
                    IsActive = false,
                    Status = CourierStatus.Offline
                };
                await _unitOfWork.Couriers.AddAsync(courier);
                await _unitOfWork.SaveChangesAsync();

                return new { Email = user.Email };
            }
            catch (Exception dbEx)
            {
                _logger.LogError(dbEx, "Courier oluşturulurken hata. UserId: {UserId}", user.Id);

                // Rollback - delete user
                await _userManager.DeleteAsync(user);

                // Clear verification code cache
                var cacheKey = $"verification_code_{dto.Email}";
                _memoryCache.Remove(cacheKey);

                throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "CourierCreationError", culture));
            }
        }

        // User creation failed - clear verification code cache
        var cacheKey2 = $"verification_code_{dto.Email}";
        _memoryCache.Remove(cacheKey2);

        var errorMessages = result.Errors.Select(e => e.Description).ToList();
        throw new InvalidOperationException(_localizationService.GetLocalizedString(ResourceName, "CourierCreationFailed", culture));
    }

    /// <summary>
    /// Doğrulama kodu üretir
    /// </summary>
    private string GenerateVerificationCode()
    {
        var random = new Random();
        return random.Next(1000, 9999).ToString(); // 4 haneli kod
    }

    /// <summary>
    /// Dil kodunu normalize eder
    /// </summary>
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
}

