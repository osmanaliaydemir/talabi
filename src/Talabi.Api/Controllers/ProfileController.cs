using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using AutoMapper;

namespace Talabi.Api.Controllers;

/// <summary>
/// Kullanıcı profil işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class ProfileController : BaseController
{
    private readonly UserManager<AppUser> _userManager;
    private readonly IMapper _mapper;
    private const string ResourceName = "ProfileResources";

    /// <summary>
    /// ProfileController constructor
    /// </summary>
    public ProfileController(
        IUnitOfWork unitOfWork,
        ILogger<ProfileController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        UserManager<AppUser> userManager,
        IMapper mapper)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _userManager = userManager;
        _mapper = mapper;
    }

    /// <summary>
    /// Kullanıcı profil bilgilerini getirir
    /// </summary>
    /// <returns>Kullanıcı profil bilgileri</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<UserProfileDto>>> GetProfile()
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
        {
            return NotFound(new ApiResponse<UserProfileDto>(
                LocalizationService.GetLocalizedString(ResourceName, "UserNotFound", CurrentCulture),
                "USER_NOT_FOUND"));
        }

        var profileDto = _mapper.Map<UserProfileDto>(user);

        return Ok(new ApiResponse<UserProfileDto>(
            profileDto,
            LocalizationService.GetLocalizedString(ResourceName, "ProfileRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kullanıcı profil bilgilerini günceller
    /// </summary>
    /// <param name="dto">Güncellenecek profil bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut]
    public async Task<ActionResult<ApiResponse<object>>> UpdateProfile(UpdateProfileDto dto)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "UserNotFound", CurrentCulture),
                "USER_NOT_FOUND"));
        }

        user.FullName = dto.FullName;
        user.PhoneNumber = dto.PhoneNumber;
        user.ProfileImageUrl = dto.ProfileImageUrl;
        user.DateOfBirth = dto.DateOfBirth;

        var result = await _userManager.UpdateAsync(user);

        if (result.Succeeded)
        {
            return Ok(new ApiResponse<object>(
                new { },
                LocalizationService.GetLocalizedString(ResourceName, "ProfileUpdatedSuccessfully", CurrentCulture)));
        }

        var errorMessages = result.Errors.Select(e => e.Description).ToList();
        return BadRequest(new ApiResponse<object>(
            LocalizationService.GetLocalizedString(ResourceName, "ProfileUpdateFailed", CurrentCulture),
            "PROFILE_UPDATE_FAILED",
            errorMessages
        ));
    }

    /// <summary>
    /// Kullanıcı şifresini değiştirir
    /// </summary>
    /// <param name="dto">Şifre değiştirme bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("password")]
    public async Task<ActionResult<ApiResponse<object>>> ChangePassword(ChangePasswordDto dto)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "UserNotFound", CurrentCulture),
                "USER_NOT_FOUND"));
        }

        var result = await _userManager.ChangePasswordAsync(user, dto.CurrentPassword, dto.NewPassword);

        if (result.Succeeded)
        {
            return Ok(new ApiResponse<object>(
                new { },
                LocalizationService.GetLocalizedString(ResourceName, "PasswordChangedSuccessfully", CurrentCulture)));
        }

        var errorMessages = result.Errors.Select(e => e.Description).ToList();
        return BadRequest(new ApiResponse<object>(
            LocalizationService.GetLocalizedString(ResourceName, "PasswordChangeFailed", CurrentCulture),
            "PASSWORD_CHANGE_FAILED",
            errorMessages
        ));
    }

    /// <summary>
    /// Kullanıcının bildirim ayarlarını getirir
    /// </summary>
    /// <returns>Bildirim ayarları</returns>
    [HttpGet("notification-settings")]
    public async Task<ActionResult<ApiResponse<NotificationSettingsDto>>> GetNotificationSettings()
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var settings = await UnitOfWork.NotificationSettings.Query()
            .FirstOrDefaultAsync(ns => ns.UserId == userId);

        if (settings == null)
        {
            // Create default settings
            settings = new NotificationSettings
            {
                UserId = userId,
                OrderUpdates = true,
                Promotions = true,
                NewProducts = true
            };

            await UnitOfWork.NotificationSettings.AddAsync(settings);
            await UnitOfWork.SaveChangesAsync();
        }

        var dto = new NotificationSettingsDto
        {
            OrderUpdates = settings.OrderUpdates,
            Promotions = settings.Promotions,
            NewProducts = settings.NewProducts
        };

        return Ok(new ApiResponse<NotificationSettingsDto>(
            dto, 
            LocalizationService.GetLocalizedString("NotificationResources", "SettingsRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Kullanıcının bildirim ayarlarını günceller
    /// </summary>
    /// <param name="dto">Güncellenecek bildirim ayarları</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("notification-settings")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateNotificationSettings([FromBody] NotificationSettingsDto dto)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var settings = await UnitOfWork.NotificationSettings.Query()
            .FirstOrDefaultAsync(ns => ns.UserId == userId);

        if (settings == null)
        {
            settings = new NotificationSettings
            {
                UserId = userId
            };
            await UnitOfWork.NotificationSettings.AddAsync(settings);
        }

        settings.OrderUpdates = dto.OrderUpdates;
        settings.Promotions = dto.Promotions;
        settings.NewProducts = dto.NewProducts;

        UnitOfWork.NotificationSettings.Update(settings);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(
            new { }, 
            LocalizationService.GetLocalizedString("NotificationResources", "SettingsUpdatedSuccessfully", CurrentCulture)));
    }
}
