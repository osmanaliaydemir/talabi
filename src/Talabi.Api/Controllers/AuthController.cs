using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Email;
using Talabi.Core.Email;
using Talabi.Core.Entities;
using Talabi.Core.Services;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly UserManager<AppUser> _userManager;
    private readonly SignInManager<AppUser> _signInManager;
    private readonly IConfiguration _configuration;
    private readonly IEmailSender _emailSender;

    public AuthController(
        UserManager<AppUser> userManager, 
        SignInManager<AppUser> signInManager, 
        IConfiguration configuration,
        IEmailSender emailSender)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _configuration = configuration;
        _emailSender = emailSender;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterDto dto)
    {
        try
        {
            var user = new AppUser { UserName = dto.Email, Email = dto.Email, FullName = dto.FullName };
            var result = await _userManager.CreateAsync(user, dto.Password);

            if (result.Succeeded)
            {
                try
                {
                    // Generate email confirmation token
                    var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
                    var confirmationLink = Url.Action(nameof(ConfirmEmail), "Auth", new { token, email = user.Email }, Request.Scheme);
                    
                    await _emailSender.SendEmailAsync(new EmailTemplateRequest
                    {
                        To = user.Email!,
                        Subject = "Email adresini doğrula",
                        TemplateName = EmailTemplateNames.ConfirmEmail,
                        Variables = new Dictionary<string, string>
                        {
                            ["fullName"] = string.IsNullOrWhiteSpace(user.FullName) ? user.Email! : user.FullName,
                            ["actionLink"] = confirmationLink!
                        }
                    });

                    // For now, we return the token directly to make testing easier without a real email server
                    // In production, you would only return a success message
                    return Ok(new { Message = "User registered successfully. Please check your email to confirm your account.", ConfirmationToken = token });
                }
                catch (Exception emailEx)
                {
                    // Log email error but don't fail registration
                    // User is already created, so we return success with token
                    var token = await _userManager.GenerateEmailConfirmationTokenAsync(user);
                    return Ok(new { 
                        Message = "User registered successfully. Email confirmation could not be sent. Please contact support.", 
                        ConfirmationToken = token,
                        Warning = emailEx.Message 
                    });
                }
            }

            return BadRequest(result.Errors);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { Message = "An error occurred during registration", Error = ex.Message, StackTrace = ex.StackTrace });
        }
    }

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

            // Check if email is confirmed
            if (!await _userManager.IsEmailConfirmedAsync(user))
            {
                return Unauthorized(new { Message = "Email not confirmed. Please check your email." });
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
                var refreshToken = GenerateRefreshToken();

                user.RefreshToken = refreshToken;
                user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(7);
                await _userManager.UpdateAsync(user);

                return Ok(new { Token = token, RefreshToken = refreshToken, UserId = user.Id, Email = user.Email, FullName = user.FullName, Role = user.Role.ToString() });
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
                        var refreshToken = GenerateRefreshToken();

                        user.RefreshToken = refreshToken;
                        user.RefreshTokenExpiryTime = DateTime.UtcNow.AddDays(7);
                        await _userManager.UpdateAsync(user);

                        return Ok(new { Token = token, RefreshToken = refreshToken, UserId = user.Id, Email = user.Email, FullName = user.FullName, Role = user.Role.ToString() });
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

    [HttpPost("refresh-token")]
    public async Task<IActionResult> RefreshToken(RefreshTokenDto dto)
    {
        if (dto is null)
            return BadRequest("Invalid client request");

        string? accessToken = dto.Token;
        string? refreshToken = dto.RefreshToken;

        var principal = GetPrincipalFromExpiredToken(accessToken);
        if (principal == null)
            return BadRequest("Invalid access token or refresh token");

        var email = principal.FindFirstValue(ClaimTypes.Email) ?? principal.FindFirstValue(JwtRegisteredClaimNames.Email);
        if (email == null)
             return BadRequest("Invalid access token or refresh token");

        var user = await _userManager.FindByEmailAsync(email);

        if (user == null || user.RefreshToken != refreshToken || user.RefreshTokenExpiryTime <= DateTime.UtcNow)
            return BadRequest("Invalid access token or refresh token");

        var newAccessToken = await GenerateJwtToken(user);
        var newRefreshToken = GenerateRefreshToken();

        user.RefreshToken = newRefreshToken;
        await _userManager.UpdateAsync(user);

        return Ok(new { Token = newAccessToken, RefreshToken = newRefreshToken });
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
}
