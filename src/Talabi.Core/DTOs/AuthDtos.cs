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

public class LoginResponseDto
{
    public string Token { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? FullName { get; set; }
    public string Role { get; set; } = string.Empty;
    public string? Provider { get; set; }
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

public class VendorRegisterDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
    
    [Required]
    public string Password { get; set; } = string.Empty;
    
    [Required]
    public string FullName { get; set; } = string.Empty;
    
    [Required]
    public string BusinessName { get; set; } = string.Empty;
    
    [Required]
    [Phone]
    public string Phone { get; set; } = string.Empty;
    
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? Description { get; set; }
    public string? Language { get; set; } // "tr", "en", "ar" - optional
    
    [Required]
    public Talabi.Core.Enums.VendorType VendorType { get; set; } = Talabi.Core.Enums.VendorType.Restaurant;
}

public class CourierRegisterDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;
    
    [Required]
    public string Password { get; set; } = string.Empty;
    
    [Required]
    public string FullName { get; set; } = string.Empty;
    
    [Phone]
    public string? Phone { get; set; }
    
    public string? Language { get; set; } // "tr", "en", "ar" - optional
}