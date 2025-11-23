using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly UserManager<AppUser> _userManager;
    private readonly SignInManager<AppUser> _signInManager;
    private readonly IConfiguration _configuration;

    public AuthController(UserManager<AppUser> userManager, SignInManager<AppUser> signInManager, IConfiguration configuration)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _configuration = configuration;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterDto dto)
    {
        var user = new AppUser { UserName = dto.Email, Email = dto.Email, FullName = dto.FullName };
        var result = await _userManager.CreateAsync(user, dto.Password);

        if (result.Succeeded)
        {
            var token = await GenerateJwtToken(user);
            return Ok(new { Token = token, UserId = user.Id, Email = user.Email, FullName = user.FullName });
        }

        return BadRequest(result.Errors);
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordDto dto)
    {
        try
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null)
            {
                // Don't reveal if user exists or not for security
                return Ok(new { Message = "If the email exists, a password reset link has been sent." });
            }

            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            
            // TODO: Send email with reset token
            // For now, we'll just return success
            // In production, you should send an email with the reset link
            
            return Ok(new { Message = "If the email exists, a password reset link has been sent." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Message = "An error occurred", Error = ex.Message });
        }
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginDto dto)
    {
        try
        {
            var user = await _userManager.FindByEmailAsync(dto.Email);
            if (user == null)
            {
                return Unauthorized(new { Message = "Invalid email or password" });
            }

            // Check if password hash is valid before attempting to verify
            if (string.IsNullOrEmpty(user.PasswordHash))
            {
                return Unauthorized(new { Message = "Account password not set. Please reset your password." });
            }

            var result = await _signInManager.CheckPasswordSignInAsync(user, dto.Password, false);

            if (result.Succeeded)
            {
                var token = await GenerateJwtToken(user);
                return Ok(new { Token = token, UserId = user.Id, Email = user.Email, FullName = user.FullName });
            }

            return Unauthorized(new { Message = "Invalid email or password" });
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
                        return Ok(new { Token = token, UserId = user.Id, Email = user.Email, FullName = user.FullName });
                    }
                }
            }
            
            return StatusCode(500, new { Message = "Account password is corrupted. Please contact support or register a new account." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Message = "An error occurred during login", Error = ex.Message });
        }
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
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            new Claim("fullName", user.FullName)
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
}

