using System.Net.Http.Headers;

namespace Getir.MerchantPortal.Services;

/// <summary>
/// HTTP message handler that automatically adds JWT token from session to API requests
/// </summary>
public class AuthTokenHandler : DelegatingHandler
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly ILogger<AuthTokenHandler> _logger;

    /// <summary>
    /// AuthTokenHandler sınıfının yapıcısı.
    /// </summary>
    /// <param name="httpContextAccessor">HttpContextAccessor</param>
    /// <param name="logger">Logger</param>
    public AuthTokenHandler(
        IHttpContextAccessor httpContextAccessor,
        ILogger<AuthTokenHandler> logger)
    {
        _httpContextAccessor = httpContextAccessor;
        _logger = logger;
    }

    /// <summary>
    /// HTTP isteğini gönderir.
    /// </summary>
    /// <param name="request">HttpRequestMessage</param>
    /// <param name="cancellationToken">CancellationToken</param>
    /// <returns>HttpResponseMessage</returns>
    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        var httpContext = _httpContextAccessor.HttpContext;
        
        if (httpContext != null)
        {
            // Get token from session
            var token = httpContext.Session.GetString("JwtToken");
            
            if (!string.IsNullOrEmpty(token))
            {
                // Add Bearer token to request
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token);
                _logger.LogDebug("Added JWT token to request: {Url}", request.RequestUri);
            }
            else
            {
                _logger.LogWarning("No JWT token found in session for request: {Url}", request.RequestUri);
            }
        }

        return await base.SendAsync(request, cancellationToken);
    }
}

