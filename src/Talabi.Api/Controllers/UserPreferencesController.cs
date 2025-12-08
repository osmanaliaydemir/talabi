using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Kullanıcı tercihleri işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class UserPreferencesController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    /// <summary>
    /// UserPreferencesController constructor
    /// </summary>
    public UserPreferencesController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    /// <summary>
    /// Kullanıcı tercihlerini getirir (yoksa varsayılan tercihleri oluşturur)
    /// </summary>
    /// <returns>Kullanıcı tercihleri</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<UserPreferencesDto>>> GetPreferences()
    {
        var userId = GetUserId();

        var preferences = await _unitOfWork.UserPreferences.Query()
            .FirstOrDefaultAsync(up => up.UserId == userId);

        if (preferences == null)
        {
            // Create default preferences
            preferences = new Core.Entities.UserPreferences
            {
                UserId = userId,
                Language = "tr",
                Currency = "TRY",
                TimeFormat = "24h",
                DateFormat = "dd/MM/yyyy"
            };

            await _unitOfWork.UserPreferences.AddAsync(preferences);
            await _unitOfWork.SaveChangesAsync();
        }

        var preferencesDto = new UserPreferencesDto
        {
            Language = preferences.Language,
            Currency = preferences.Currency,
            TimeZone = preferences.TimeZone,
            DateFormat = preferences.DateFormat,
            TimeFormat = preferences.TimeFormat
        };

        return Ok(new ApiResponse<UserPreferencesDto>(preferencesDto, "Kullanıcı tercihleri başarıyla getirildi"));
    }

    /// <summary>
    /// Kullanıcı tercihlerini günceller
    /// </summary>
    /// <param name="dto">Güncellenecek tercih bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut]
    public async Task<ActionResult<ApiResponse<object>>> UpdatePreferences([FromBody] UpdateUserPreferencesDto dto)
    {
        try
        {
            if (dto == null)
            {
                return BadRequest(new ApiResponse<object>("Geçersiz istek", "INVALID_REQUEST"));
            }

            var userId = GetUserId();

            var existingPreferences = await _unitOfWork.UserPreferences.Query()
                .FirstOrDefaultAsync(up => up.UserId == userId);

            if (existingPreferences == null)
            {
                // Yeni preferences oluştur
                var newPreferences = new Core.Entities.UserPreferences
                {
                    UserId = userId,
                    Language = dto.Language ?? "tr",
                    Currency = dto.Currency ?? "TRY",
                    TimeFormat = dto.TimeFormat ?? "24h",
                    DateFormat = dto.DateFormat ?? "dd/MM/yyyy",
                    TimeZone = dto.TimeZone
                };

                // Validate language
                if (!string.IsNullOrEmpty(newPreferences.Language) && 
                    !(newPreferences.Language == "tr" || newPreferences.Language == "en" || newPreferences.Language == "ar"))
                {
                    newPreferences.Language = "tr";
                }

                // Validate currency
                if (!string.IsNullOrEmpty(newPreferences.Currency) && 
                    !(newPreferences.Currency == "TRY" || newPreferences.Currency == "USDT"))
                {
                    newPreferences.Currency = "TRY";
                }

                // Validate time format
                if (!string.IsNullOrEmpty(newPreferences.TimeFormat) && 
                    !(newPreferences.TimeFormat == "12h" || newPreferences.TimeFormat == "24h"))
                {
                    newPreferences.TimeFormat = "24h";
                }

                await _unitOfWork.UserPreferences.AddAsync(newPreferences);
                await _unitOfWork.SaveChangesAsync();
            }
            else
            {
                // Mevcut preferences'ı güncelle - entity zaten tracked
                // Validate and update
                if (!string.IsNullOrEmpty(dto.Language) && 
                    (dto.Language == "tr" || dto.Language == "en" || dto.Language == "ar"))
                {
                    existingPreferences.Language = dto.Language;
                }

                if (!string.IsNullOrEmpty(dto.Currency) && 
                    (dto.Currency == "TRY" || dto.Currency == "USDT"))
                {
                    existingPreferences.Currency = dto.Currency;
                }

                if (dto.TimeZone != null)
                {
                    existingPreferences.TimeZone = dto.TimeZone;
                }

                if (dto.DateFormat != null)
                {
                    existingPreferences.DateFormat = dto.DateFormat;
                }

                if (dto.TimeFormat != null && (dto.TimeFormat == "12h" || dto.TimeFormat == "24h"))
                {
                    existingPreferences.TimeFormat = dto.TimeFormat;
                }

                existingPreferences.UpdatedAt = DateTime.UtcNow;
                
                // Entity zaten tracked olduğu için Update çağrısına gerek yok
                // Sadece property değişiklikleri yeterli
                await _unitOfWork.SaveChangesAsync();
            }

            return Ok(new ApiResponse<object>(new { }, "Tercihler başarıyla güncellendi"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, new ApiResponse<object>($"Tercihler güncellenirken bir hata oluştu: {ex.Message}", "INTERNAL_SERVER_ERROR"));
        }
    }

    /// <summary>
    /// Desteklenen dilleri getirir
    /// </summary>
    /// <returns>Desteklenen diller listesi</returns>
    [HttpGet("supported-languages")]
    [AllowAnonymous]
    public ActionResult<ApiResponse<List<SupportedLanguageDto>>> GetSupportedLanguages()
    {
        var languages = new List<SupportedLanguageDto>
        {
            new() { Code = "tr", Name = "Turkish", NativeName = "Türkçe" },
            new() { Code = "en", Name = "English", NativeName = "English" },
            new() { Code = "ar", Name = "Arabic", NativeName = "العربية" }
        };

        return Ok(new ApiResponse<List<SupportedLanguageDto>>(languages, "Desteklenen diller başarıyla getirildi"));
    }

    /// <summary>
    /// Desteklenen para birimlerini getirir
    /// </summary>
    /// <returns>Desteklenen para birimleri listesi</returns>
    [HttpGet("supported-currencies")]
    [AllowAnonymous]
    public ActionResult<ApiResponse<List<SupportedCurrencyDto>>> GetSupportedCurrencies()
    {
        // TODO: Get real-time exchange rates from an API
        var currencies = new List<SupportedCurrencyDto>
        {
            new() { Code = "TRY", Name = "Turkish Lira", Symbol = "₺", ExchangeRate = 1.0m },
            new() { Code = "USD", Name = "Dolar", Symbol = "USD", ExchangeRate = 0.034m } // Example rate
        };

        return Ok(new ApiResponse<List<SupportedCurrencyDto>>(currencies, "Desteklenen para birimleri başarıyla getirildi"));
    }
}

