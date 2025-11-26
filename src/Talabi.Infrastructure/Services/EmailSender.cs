using System;
using System.Net.Http;
using System.Net.Http.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Talabi.Core.DTOs.Email;
using Talabi.Core.Options;
using Talabi.Core.Services;

namespace Talabi.Infrastructure.Services;

public class EmailSender : IEmailSender
{
    private readonly HttpClient _httpClient;
    private readonly EmailSettings _settings;
    private readonly IEmailTemplateRenderer _templateRenderer;
    private readonly ILogger<EmailSender> _logger;

    public EmailSender(
        HttpClient httpClient,
        IOptions<EmailSettings> options,
        IEmailTemplateRenderer templateRenderer,
        ILogger<EmailSender> logger)
    {
        _httpClient = httpClient;
        _settings = options.Value;
        _templateRenderer = templateRenderer;
        _logger = logger;

        ConfigureHttpClient();
    }

    public async Task SendEmailAsync(EmailTemplateRequest request, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        var htmlBody = await _templateRenderer.RenderAsync(request.TemplateName, request.Variables, cancellationToken);

        var payload = new EmailApiPayload(
            new EmailPerson(_settings.SenderEmail, _settings.SenderName),
            request.To,
            request.Subject,
            htmlBody);

        var endpoint = BuildEndpointPath();
        var response = await _httpClient.PostAsJsonAsync(endpoint, payload, cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            var errorContent = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogError(
                "E-posta servisi başarısız yanıt döndürdü. StatusCode: {StatusCode}, Body: {Body}",
                response.StatusCode,
                errorContent);

            throw new InvalidOperationException("E-posta gönderimi yapılamadı, lütfen sistem yöneticisine danışın.");
        }

        _logger.LogInformation("E-posta API üzerinden gönderildi. Alıcı: {Recipient}, Şablon: {Template}", request.To, request.TemplateName);
    }

    private void ConfigureHttpClient()
    {
        if (string.IsNullOrWhiteSpace(_settings.ApiBaseUrl))
        {
            throw new InvalidOperationException("Email API BaseUrl değeri yapılandırılmamış.");
        }

        _httpClient.BaseAddress = new Uri(_settings.ApiBaseUrl.Trim(), UriKind.Absolute);

        if (string.IsNullOrWhiteSpace(_settings.ApiKey))
        {
            _logger.LogWarning("Email API anahtarı yapılandırılmamış. Talepler yetkisiz kalabilir.");
            return;
        }

        var headerName = string.IsNullOrWhiteSpace(_settings.ApiKeyHeaderName)
            ? "Authorization"
            : _settings.ApiKeyHeaderName;

        if (_httpClient.DefaultRequestHeaders.Contains(headerName))
        {
            _httpClient.DefaultRequestHeaders.Remove(headerName);
        }

        var headerValue = headerName.Equals("Authorization", StringComparison.OrdinalIgnoreCase)
            ? $"{_settings.AuthorizationScheme} {_settings.ApiKey}".Trim()
            : _settings.ApiKey;

        _httpClient.DefaultRequestHeaders.Add(headerName, headerValue);
    }

    private string BuildEndpointPath()
    {
        if (string.IsNullOrWhiteSpace(_settings.SendEndpoint))
        {
            return "/emails/send";
        }

        return _settings.SendEndpoint.StartsWith("/")
            ? _settings.SendEndpoint
            : $"/{_settings.SendEndpoint}";
    }

    private sealed record EmailApiPayload(EmailPerson From, string To, string Subject, string Html);
    private sealed record EmailPerson(string Email, string? Name);
}
