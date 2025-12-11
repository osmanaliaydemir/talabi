namespace Talabi.Core.Services;

/// <summary>
/// External authentication provider token verification service
/// </summary>
public interface IExternalAuthTokenVerifier
{
    /// <summary>
    /// Verifies the token from external authentication provider
    /// </summary>
    /// <param name="provider">Provider name (Google, Apple, Facebook)</param>
    /// <param name="idToken">ID token from the provider</param>
    /// <param name="expectedEmail">Expected email address from the token</param>
    /// <returns>True if token is valid, false otherwise</returns>
    Task<bool> VerifyTokenAsync(string provider, string idToken, string? expectedEmail = null);

    /// <summary>
    /// Gets the email from the verified token
    /// </summary>
    /// <param name="provider">Provider name</param>
    /// <param name="idToken">ID token from the provider</param>
    /// <returns>Email address from the token, or null if invalid</returns>
    Task<string?> GetEmailFromTokenAsync(string provider, string idToken);
}

