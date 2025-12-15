using Talabi.Core.DTOs.Email;

namespace Talabi.Core.Services;

public interface IEmailSender
{
    Task SendEmailAsync(EmailTemplateRequest request, CancellationToken cancellationToken = default);
}
