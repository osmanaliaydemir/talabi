using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MimeKit;
using Talabi.Core.DTOs.Email;
using Talabi.Core.Options;
using Talabi.Core.Services;

namespace Talabi.Infrastructure.Services;

public class EmailSender(
    IOptions<EmailSettings> options,
    IEmailTemplateRenderer templateRenderer,
    ILogger<EmailSender> logger)
    : IEmailSender
{
    private readonly EmailSettings _settings = options.Value;

    public async Task SendEmailAsync(EmailTemplateRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            // Render email template
            var htmlBody = await templateRenderer.RenderAsync(request.TemplateName, request.Variables,
                request.LanguageCode, cancellationToken);

            // Create email message
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress(_settings.SenderName, _settings.SenderEmail));
            message.To.Add(MailboxAddress.Parse(request.To));
            message.Subject = request.Subject;

            var builder = new BodyBuilder
            {
                HtmlBody = htmlBody
            };
            message.Body = builder.ToMessageBody();

            // Send email via SMTP - Basit ve doğrudan yaklaşım (test edildi ve çalışıyor)
            using var client = new SmtpClient();

            // Port 465 için SslOnConnect (test edildi)
            await client.ConnectAsync(_settings.SmtpServer, _settings.SmtpPort, SecureSocketOptions.SslOnConnect,
                cancellationToken);

            // Basit authentication - MailKit otomatik olarak en uygun mekanizmayı seçer
            await client.AuthenticateAsync(_settings.SenderEmail, _settings.SenderPassword, cancellationToken);

            await client.SendAsync(message, cancellationToken);
            await client.DisconnectAsync(true, cancellationToken);

            logger.LogInformation("E-posta başarıyla gönderildi. Alıcı: {Recipient}, Şablon: {Template}",
                request.To, request.TemplateName);
        }
        catch (Exception ex)
        {
            logger.LogError(ex,
                "E-posta gönderimi sırasında bir hata oluştu. Alıcı: {Recipient}, Şablon: {Template}, Hata: {ErrorMessage}",
                request.To, request.TemplateName, ex.Message);
            throw new InvalidOperationException("E-posta gönderimi yapılamadı, lütfen sistem yöneticisine danışın.",
                ex);
        }
    }

}
