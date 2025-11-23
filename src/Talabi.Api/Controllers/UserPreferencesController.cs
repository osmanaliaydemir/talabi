using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.DTOs;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class UserPreferencesController : ControllerBase
{
    private readonly TalabiDbContext _context;

    public UserPreferencesController(TalabiDbContext context)
    {
        _context = context;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    [HttpGet]
    public async Task<ActionResult<UserPreferencesDto>> GetPreferences()
    {
        var userId = GetUserId();

        var preferences = await _context.UserPreferences
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

            _context.UserPreferences.Add(preferences);
            await _context.SaveChangesAsync();
        }

        return Ok(new UserPreferencesDto
        {
            Language = preferences.Language,
            Currency = preferences.Currency,
            TimeZone = preferences.TimeZone,
            DateFormat = preferences.DateFormat,
            TimeFormat = preferences.TimeFormat
        });
    }

    [HttpPut]
    public async Task<ActionResult> UpdatePreferences(UpdateUserPreferencesDto dto)
    {
        var userId = GetUserId();

        var preferences = await _context.UserPreferences
            .FirstOrDefaultAsync(up => up.UserId == userId);

        if (preferences == null)
        {
            preferences = new Core.Entities.UserPreferences
            {
                UserId = userId
            };
            _context.UserPreferences.Add(preferences);
        }

        // Validate and update
        if (!string.IsNullOrEmpty(dto.Language) && 
            (dto.Language == "tr" || dto.Language == "en" || dto.Language == "ar"))
        {
            preferences.Language = dto.Language;
        }

        if (!string.IsNullOrEmpty(dto.Currency) && 
            (dto.Currency == "TRY" || dto.Currency == "USDT"))
        {
            preferences.Currency = dto.Currency;
        }

        if (dto.TimeZone != null)
        {
            preferences.TimeZone = dto.TimeZone;
        }

        if (dto.DateFormat != null)
        {
            preferences.DateFormat = dto.DateFormat;
        }

        if (dto.TimeFormat != null && (dto.TimeFormat == "12h" || dto.TimeFormat == "24h"))
        {
            preferences.TimeFormat = dto.TimeFormat;
        }

        preferences.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();

        return Ok(new { Message = "Preferences updated successfully" });
    }

    [HttpGet("supported-languages")]
    [AllowAnonymous]
    public ActionResult<List<SupportedLanguageDto>> GetSupportedLanguages()
    {
        return Ok(new List<SupportedLanguageDto>
        {
            new() { Code = "tr", Name = "Turkish", NativeName = "Türkçe" },
            new() { Code = "en", Name = "English", NativeName = "English" },
            new() { Code = "ar", Name = "Arabic", NativeName = "العربية" }
        });
    }

    [HttpGet("supported-currencies")]
    [AllowAnonymous]
    public ActionResult<List<SupportedCurrencyDto>> GetSupportedCurrencies()
    {
        // TODO: Get real-time exchange rates from an API
        return Ok(new List<SupportedCurrencyDto>
        {
            new() { Code = "TRY", Name = "Turkish Lira", Symbol = "₺", ExchangeRate = 1.0m },
            new() { Code = "USDT", Name = "Tether", Symbol = "USDT", ExchangeRate = 0.034m } // Example rate
        });
    }
}

