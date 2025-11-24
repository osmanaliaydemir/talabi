using Talabi.Core.Services;

namespace Talabi.Infrastructure.Services;

public class EmailSender : IEmailSender
{
    public Task SendEmailAsync(string email, string subject, string message)
    {
        // Mock implementation - log to console
        Console.WriteLine($"[Email Sent] To: {email}, Subject: {subject}");
        Console.WriteLine($"Message: {message}");
        return Task.CompletedTask;
    }
}
