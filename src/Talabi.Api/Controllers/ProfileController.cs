using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class ProfileController : ControllerBase
{
    private readonly UserManager<AppUser> _userManager;

    public ProfileController(UserManager<AppUser> userManager)
    {
        _userManager = userManager;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    [HttpGet]
    public async Task<ActionResult<UserProfileDto>> GetProfile()
    {
        var userId = GetUserId();
        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
        {
            return NotFound();
        }

        return Ok(new UserProfileDto
        {
            Id = user.Id,
            Email = user.Email!,
            FullName = user.FullName,
            PhoneNumber = user.PhoneNumber,
            ProfileImageUrl = user.ProfileImageUrl,
            DateOfBirth = user.DateOfBirth
        });
    }

    [HttpPut]
    public async Task<ActionResult> UpdateProfile(UpdateProfileDto dto)
    {
        var userId = GetUserId();
        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
        {
            return NotFound();
        }

        user.FullName = dto.FullName;
        user.PhoneNumber = dto.PhoneNumber;
        user.ProfileImageUrl = dto.ProfileImageUrl;
        user.DateOfBirth = dto.DateOfBirth;

        var result = await _userManager.UpdateAsync(user);

        if (result.Succeeded)
        {
            return Ok(new { Message = "Profile updated successfully" });
        }

        return BadRequest(result.Errors);
    }

    [HttpPut("password")]
    public async Task<ActionResult> ChangePassword(ChangePasswordDto dto)
    {
        var userId = GetUserId();
        var user = await _userManager.FindByIdAsync(userId);

        if (user == null)
        {
            return NotFound();
        }

        var result = await _userManager.ChangePasswordAsync(user, dto.CurrentPassword, dto.NewPassword);

        if (result.Succeeded)
        {
            return Ok(new { Message = "Password changed successfully" });
        }

        return BadRequest(result.Errors);
    }
}
