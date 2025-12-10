namespace Talabi.Core.Options;

/// <summary>
/// Password policy configuration options
/// </summary>
public class PasswordPolicyOptions
{
    /// <summary>
    /// Minimum password length (default: 8)
    /// </summary>
    public int MinimumLength { get; init; } = 8;

    /// <summary>
    /// Require at least one digit (0-9)
    /// </summary>
    public bool RequireDigit { get; init; } = true;

    /// <summary>
    /// Require at least one lowercase letter (a-z)
    /// </summary>
    public bool RequireLowercase { get; init; } = true;

    /// <summary>
    /// Require at least one uppercase letter (A-Z)
    /// </summary>
    public bool RequireUppercase { get; init; } = true;

    /// <summary>
    /// Require at least one non-alphanumeric character (!@#$%^&* etc.)
    /// </summary>
    public bool RequireNonAlphanumeric { get; init; } = true;

    /// <summary>
    /// Maximum number of failed login attempts before account lockout (default: 5)
    /// </summary>
    public int MaxFailedAttempts { get; init; } = 5;

    /// <summary>
    /// Account lockout duration in minutes (default: 15)
    /// </summary>
    public int LockoutDurationMinutes { get; init; } = 15;
}

