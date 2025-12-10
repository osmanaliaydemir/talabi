using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Kullanıcı tercihleri işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class UserPreferencesController : BaseController
{
    private const string ResourceName = "UserPreferenceResources";

    /// <summary>
    /// UserPreferencesController constructor
    /// </summary>
    public UserPreferencesController(
        IUnitOfWork unitOfWork,
        ILogger<UserPreferencesController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
    }

    /// <summary>
    /// Kullanıcı tercihlerini getirir (yoksa varsayılan tercihleri oluşturur)
    /// </summary>
    /// <returns>Kullanıcı tercihleri</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<UserPreferencesDto>>> GetPreferences()
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var preferences = await UnitOfWork.UserPreferences.Query()
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

            await UnitOfWork.UserPreferences.AddAsync(preferences);
            await UnitOfWork.SaveChangesAsync();
        }

        var preferencesDto = new UserPreferencesDto
        {
            Language = preferences.Language,
            Currency = preferences.Currency,
            TimeZone = preferences.TimeZone,
            DateFormat = preferences.DateFormat,
            TimeFormat = preferences.TimeFormat
        };

        return Ok(new ApiResponse<UserPreferencesDto>(
            preferencesDto,
            LocalizationService.GetLocalizedString(ResourceName, "PreferencesRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kullanıcı tercihlerini günceller
    /// </summary>
    /// <param name="dto">Güncellenecek tercih bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut]
    public async Task<ActionResult<ApiResponse<object>>> UpdatePreferences([FromBody] UpdateUserPreferencesDto dto)
    {
        if (dto == null)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidRequest", CurrentCulture),
                "INVALID_REQUEST"));
        }

        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var existingPreferences = await UnitOfWork.UserPreferences.Query()
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

            await UnitOfWork.UserPreferences.AddAsync(newPreferences);
            await UnitOfWork.SaveChangesAsync();
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
            await UnitOfWork.SaveChangesAsync();
        }

        return Ok(new ApiResponse<object>(
            new { },
            LocalizationService.GetLocalizedString(ResourceName, "PreferencesUpdatedSuccessfully", CurrentCulture)));
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

        return Ok(new ApiResponse<List<SupportedLanguageDto>>(
            languages,
            LocalizationService.GetLocalizedString(ResourceName, "SupportedLanguagesRetrievedSuccessfully", CurrentCulture)));
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

        return Ok(new ApiResponse<List<SupportedCurrencyDto>>(
            currencies,
            LocalizationService.GetLocalizedString(ResourceName, "SupportedCurrenciesRetrievedSuccessfully", CurrentCulture)));
    }
}

