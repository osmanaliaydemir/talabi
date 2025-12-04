using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;

namespace Talabi.Api.Controllers;

/// <summary>
/// Kullanıcı profil işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class ProfileController : ControllerBase
{
    private readonly UserManager<AppUser> _userManager;

    /// <summary>
    /// ProfileController constructor
    /// </summary>
    public ProfileController(UserManager<AppUser> userManager)
    {
        _userManager = userManager;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    /// <summary>
    /// Kullanıcı profil bilgilerini getirir
    /// </summary>
    /// <returns>Kullanıcı profil bilgileri</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<UserProfileDto>>> GetProfile()
    {
        var userId = GetUserId();
        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
        {
            return NotFound(new ApiResponse<UserProfileDto>("Kullanıcı bulunamadı", "USER_NOT_FOUND"));
        }

        var profileDto = new UserProfileDto
        {
            Id = user.Id,
            Email = user.Email!,
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            ProfileImageUrl = user.ProfileImageUrl,
            DateOfBirth = user.DateOfBirth
        };

        return Ok(new ApiResponse<UserProfileDto>(profileDto, "Profil bilgileri başarıyla getirildi"));
    }

    /// <summary>
    /// Kullanıcı profil bilgilerini günceller
    /// </summary>
    /// <param name="dto">Güncellenecek profil bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut]
    public async Task<ActionResult<ApiResponse<object>>> UpdateProfile(UpdateProfileDto dto)
    {
        var userId = GetUserId();
        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
        {
            return NotFound(new ApiResponse<object>("Kullanıcı bulunamadı", "USER_NOT_FOUND"));
        }

        user.FullName = dto.FullName;
        user.PhoneNumber = dto.PhoneNumber;
        user.ProfileImageUrl = dto.ProfileImageUrl;
        user.DateOfBirth = dto.DateOfBirth;

        var result = await _userManager.UpdateAsync(user);

        if (result.Succeeded)
        {
            return Ok(new ApiResponse<object>(new { }, "Profil başarıyla güncellendi"));
        }

        var errorMessages = result.Errors.Select(e => e.Description).ToList();
        return BadRequest(new ApiResponse<object>(
            "Profil güncellenemedi",
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
        var userId = GetUserId();
        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
        {
            return NotFound(new ApiResponse<object>("Kullanıcı bulunamadı", "USER_NOT_FOUND"));
        }

        var result = await _userManager.ChangePasswordAsync(user, dto.CurrentPassword, dto.NewPassword);

        if (result.Succeeded)
        {
            return Ok(new ApiResponse<object>(new { }, "Şifre başarıyla değiştirildi"));
        }

        var errorMessages = result.Errors.Select(e => e.Description).ToList();
        return BadRequest(new ApiResponse<object>(
            "Şifre değiştirilemedi",
            "PASSWORD_CHANGE_FAILED",
            errorMessages
        ));
    }
}
