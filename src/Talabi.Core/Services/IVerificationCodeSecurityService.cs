namespace Talabi.Core.Services;

/// <summary>
/// Email verification code security service
/// Provides protection against brute force attacks
/// </summary>
public interface IVerificationCodeSecurityService
{
    /// <summary>
    /// Checks if verification attempts are within limits
    /// </summary>
    /// <param name="email">Email address</param>
    /// <returns>True if attempts are within limits, false if exceeded</returns>
    Task<bool> CanAttemptVerificationAsync(string email);

    /// <summary>
    /// Records a failed verification attempt
    /// </summary>
    /// <param name="email">Email address</param>
    Task RecordFailedAttemptAsync(string email);

    /// <summary>
    /// Records a successful verification and clears attempts
    /// </summary>
    /// <param name="email">Email address</param>
    Task RecordSuccessAsync(string email);

    /// <summary>
    /// Gets remaining attempts for an email
    /// </summary>
    /// <param name="email">Email address</param>
    /// <returns>Remaining attempts count</returns>
    Task<int> GetRemainingAttemptsAsync(string email);

    /// <summary>
    /// Gets lockout expiration time if locked
    /// </summary>
    /// <param name="email">Email address</param>
    /// <returns>Lockout expiration time or null if not locked</returns>
    Task<DateTime?> GetLockoutExpirationAsync(string email);
}

