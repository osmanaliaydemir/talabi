using System.ComponentModel.DataAnnotations;

namespace Talabi.Portal.Models;

public class ApiResponse<T>
{
    public bool Success { get; set; }
    public T? Data { get; set; }
    public string? Error { get; set; }
}

public class LoginResponse
{
    public string Token { get; set; } = default!;
    public string RefreshToken { get; set; } = default!;
    public DateTime ExpiresAt { get; set; }
    public string Role { get; set; } = default!;
    public string UserId { get; set; } = default!;
    public string Email { get; set; } = default!;
    public string FullName { get; set; } = default!;
    public Guid? VendorId { get; set; }

    // Backward compatibility if needed, but better to migrate
    public string AccessToken => Token;
}
