using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Talabi.Core.Services;

namespace Talabi.Infrastructure.Services;

/// <summary>
/// External authentication token verification service implementation
/// </summary>
public class ExternalAuthTokenVerifier : IExternalAuthTokenVerifier
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<ExternalAuthTokenVerifier> _logger;
    private readonly IConfiguration _configuration;

    public ExternalAuthTokenVerifier(
        HttpClient httpClient,
        ILogger<ExternalAuthTokenVerifier> logger,
        IConfiguration configuration)
    {
        _httpClient = httpClient;
        _logger = logger;
        _configuration = configuration;
    }

    public async Task<bool> VerifyTokenAsync(string provider, string idToken, string? expectedEmail = null)
    {
        if (string.IsNullOrWhiteSpace(idToken))
        {
            _logger.LogWarning("Empty token provided for provider: {Provider}", provider);
            return false;
        }

        try
        {
            return provider switch
            {
                "Google" => await VerifyGoogleTokenAsync(idToken, expectedEmail),
                "Apple" => await VerifyAppleTokenAsync(idToken, expectedEmail),
                "Facebook" => await VerifyFacebookTokenAsync(idToken, expectedEmail),
                _ => false
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying token for provider: {Provider}", provider);
            return false;
        }
    }

    public async Task<string?> GetEmailFromTokenAsync(string provider, string idToken)
    {
        if (string.IsNullOrWhiteSpace(idToken))
        {
            return null;
        }

        try
        {
            return provider switch
            {
                "Google" => await GetEmailFromGoogleTokenAsync(idToken),
                "Apple" => await GetEmailFromAppleTokenAsync(idToken),
                "Facebook" => await GetEmailFromFacebookTokenAsync(idToken),
                _ => null
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting email from token for provider: {Provider}", provider);
            return null;
        }
    }

    private async Task<bool> VerifyGoogleTokenAsync(string idToken, string? expectedEmail)
    {
        try
        {
            // Google token verification endpoint
            var response = await _httpClient.GetAsync($"https://oauth2.googleapis.com/tokeninfo?id_token={idToken}");
            
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Google token verification failed. Status: {Status}", response.StatusCode);
                return false;
            }

            var tokenInfo = await response.Content.ReadFromJsonAsync<GoogleTokenInfo>();
            
            if (tokenInfo == null)
            {
                _logger.LogWarning("Google tokeninfo response is null");
                return false;
            }

            _logger.LogDebug("Google token verification - Email: {Email}, Exp: {Exp}, ExpiresIn: {ExpiresIn}", 
                tokenInfo.Email, tokenInfo.Exp, tokenInfo.ExpiresIn);

            // Verify email matches if provided
            if (!string.IsNullOrEmpty(expectedEmail) && 
                !string.Equals(tokenInfo.Email, expectedEmail, StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogWarning("Email mismatch in Google token. Expected: {Expected}, Got: {Actual}", 
                    expectedEmail, tokenInfo.Email);
                return false;
            }

            // Verify token is not expired
            // Google tokeninfo returns 'exp' as Unix timestamp, not 'expires_in'
            if (tokenInfo.Exp.HasValue)
            {
                var expirationTime = DateTimeOffset.FromUnixTimeSeconds(tokenInfo.Exp.Value);
                if (expirationTime < DateTimeOffset.UtcNow)
                {
                    _logger.LogWarning("Google token has expired. Expiration: {Expiration}, Current: {Current}", 
                        expirationTime, DateTimeOffset.UtcNow);
                    return false;
                }
            }
            else if (tokenInfo.ExpiresIn.HasValue && tokenInfo.ExpiresIn.Value <= 0)
            {
                // Fallback to ExpiresIn if Exp is not available (legacy)
                _logger.LogWarning("Google token has expired (using ExpiresIn)");
                return false;
            }

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying Google token");
            return false;
        }
    }

    private async Task<string?> GetEmailFromGoogleTokenAsync(string idToken)
    {
        try
        {
            var response = await _httpClient.GetAsync($"https://oauth2.googleapis.com/tokeninfo?id_token={idToken}");
            
            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            var tokenInfo = await response.Content.ReadFromJsonAsync<GoogleTokenInfo>();
            return tokenInfo?.Email;
        }
        catch
        {
            return null;
        }
    }

    private async Task<bool> VerifyAppleTokenAsync(string idToken, string? expectedEmail)
    {
        try
        {
            // Apple token verification requires JWT validation
            // For now, we'll do basic validation
            // In production, you should use Apple's public keys to verify the JWT signature
            
            // Apple tokens are JWTs, we can decode and check basic claims
            var parts = idToken.Split('.');
            if (parts.Length != 3)
            {
                _logger.LogWarning("Invalid Apple token format");
                return false;
            }

            // Decode payload (base64url)
            var payload = parts[1];
            // Add padding if needed
            while (payload.Length % 4 != 0)
            {
                payload += "=";
            }

            var payloadBytes = Convert.FromBase64String(payload.Replace('-', '+').Replace('_', '/'));
            var payloadJson = System.Text.Encoding.UTF8.GetString(payloadBytes);
            var payloadData = JsonSerializer.Deserialize<JsonElement>(payloadJson);

            // Check expiration
            if (payloadData.TryGetProperty("exp", out var expElement))
            {
                var exp = expElement.GetInt64();
                var expirationTime = DateTimeOffset.FromUnixTimeSeconds(exp);
                if (expirationTime < DateTimeOffset.UtcNow)
                {
                    _logger.LogWarning("Apple token has expired");
                    return false;
                }
            }

            // Verify email if provided
            if (!string.IsNullOrEmpty(expectedEmail) && payloadData.TryGetProperty("email", out var emailElement))
            {
                var email = emailElement.GetString();
                if (!string.Equals(email, expectedEmail, StringComparison.OrdinalIgnoreCase))
                {
                    _logger.LogWarning("Email mismatch in Apple token");
                    return false;
                }
            }

            // Note: Full JWT signature verification with Apple's public keys should be implemented
            // for production use. This is a basic validation.
            _logger.LogWarning("Apple token validation is using basic checks. Full JWT signature verification should be implemented for production.");

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying Apple token");
            return false;
        }
    }

    private async Task<string?> GetEmailFromAppleTokenAsync(string idToken)
    {
        try
        {
            var parts = idToken.Split('.');
            if (parts.Length != 3)
            {
                return null;
            }

            var payload = parts[1];
            while (payload.Length % 4 != 0)
            {
                payload += "=";
            }

            var payloadBytes = Convert.FromBase64String(payload.Replace('-', '+').Replace('_', '/'));
            var payloadJson = System.Text.Encoding.UTF8.GetString(payloadBytes);
            var payloadData = JsonSerializer.Deserialize<JsonElement>(payloadJson);

            if (payloadData.TryGetProperty("email", out var emailElement))
            {
                return emailElement.GetString();
            }

            return null;
        }
        catch
        {
            return null;
        }
    }

    private async Task<bool> VerifyFacebookTokenAsync(string accessToken, string? expectedEmail)
    {
        try
        {
            // Facebook token verification
            var appId = _configuration["Facebook:AppId"];
            var appSecret = _configuration["Facebook:AppSecret"];

            if (string.IsNullOrEmpty(appId) || string.IsNullOrEmpty(appSecret))
            {
                _logger.LogWarning("Facebook AppId or AppSecret not configured");
                // In development, we might allow this, but log a warning
                return false;
            }

            // Verify token with Facebook
            var response = await _httpClient.GetAsync(
                $"https://graph.facebook.com/debug_token?input_token={accessToken}&access_token={appId}|{appSecret}");

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Facebook token verification failed. Status: {Status}", response.StatusCode);
                return false;
            }

            var debugInfo = await response.Content.ReadFromJsonAsync<FacebookDebugTokenResponse>();
            
            if (debugInfo?.Data == null || !debugInfo.Data.IsValid)
            {
                _logger.LogWarning("Facebook token is invalid");
                return false;
            }

            // Get user info to verify email
            if (!string.IsNullOrEmpty(expectedEmail))
            {
                var userResponse = await _httpClient.GetAsync(
                    $"https://graph.facebook.com/me?fields=email&access_token={accessToken}");

                if (userResponse.IsSuccessStatusCode)
                {
                    var userInfo = await userResponse.Content.ReadFromJsonAsync<FacebookUserInfo>();
                    if (userInfo?.Email != null && 
                        !string.Equals(userInfo.Email, expectedEmail, StringComparison.OrdinalIgnoreCase))
                    {
                        _logger.LogWarning("Email mismatch in Facebook token");
                        return false;
                    }
                }
            }

            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error verifying Facebook token");
            return false;
        }
    }

    private async Task<string?> GetEmailFromFacebookTokenAsync(string accessToken)
    {
        try
        {
            var response = await _httpClient.GetAsync(
                $"https://graph.facebook.com/me?fields=email&access_token={accessToken}");

            if (!response.IsSuccessStatusCode)
            {
                return null;
            }

            var userInfo = await response.Content.ReadFromJsonAsync<FacebookUserInfo>();
            return userInfo?.Email;
        }
        catch
        {
            return null;
        }
    }

    // Helper classes for API responses
    private class GoogleTokenInfo
    {
        public string? Email { get; set; }
        public long? Exp { get; set; } // Expiration timestamp (Unix time)
        public int? ExpiresIn { get; set; } // Legacy field, may not be present
    }

    private class FacebookDebugTokenResponse
    {
        public FacebookDebugTokenData? Data { get; set; }
    }

    private class FacebookDebugTokenData
    {
        public bool IsValid { get; set; }
    }

    private class FacebookUserInfo
    {
        public string? Email { get; set; }
    }
}

