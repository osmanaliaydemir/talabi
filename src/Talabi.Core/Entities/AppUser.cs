using Microsoft.AspNetCore.Identity;
using Talabi.Core.Enums;

namespace Talabi.Core.Entities;

public class AppUser : IdentityUser
{
    public string FullName { get; set; } = string.Empty;
    public string? Address { get; set; }
    public string? ProfileImageUrl { get; set; }
    public DateTime? DateOfBirth { get; set; }
    public string? RefreshToken { get; set; }
    public DateTime RefreshTokenExpiryTime { get; set; }
    public UserRole Role { get; set; } = UserRole.Customer;
}
