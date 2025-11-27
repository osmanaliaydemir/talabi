using System.ComponentModel.DataAnnotations;

namespace Talabi.Core.DTOs;

public class RegisterDto
{
    [Required]
    public string Email { get; set; } = string.Empty;
    [Required]
    public string Password { get; set; } = string.Empty;
    [Required]
    public string FullName { get; set; } = string.Empty;
    public string? Language { get; set; } // "tr", "en", "ar" - optional, defaults to "tr"
}

public class LoginDto
{
    [Required]
    public string Email { get; set; } = string.Empty;
    [Required]
    public string Password { get; set; } = string.Empty;
}

public class ForgotPasswordDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
}

public class RefreshTokenDto
{
    [Required]
    public string Token { get; set; } = string.Empty;
    [Required]
    public string RefreshToken { get; set; } = string.Empty;
}

public class VerifyEmailCodeDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
    
    [Required]
    [StringLength(4, MinimumLength = 4)]
    public string Code { get; set; } = string.Empty;
}

public class ResendVerificationCodeDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
    public string? Language { get; set; } // "tr", "en", "ar" - optional
}