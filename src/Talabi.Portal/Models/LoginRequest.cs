using System.ComponentModel.DataAnnotations;

namespace Talabi.Portal.Models;

public class LoginRequest
{
    [Required(ErrorMessage = "Email gereklidir")]
    [EmailAddress(ErrorMessage = "Geçerli bir email adresi giriniz")]
    public string Email { get; set; } = string.Empty;

    [Required(ErrorMessage = "Şifre gereklidir")]
    public string Password { get; set; } = string.Empty;

    public bool RememberMe { get; set; }
}
