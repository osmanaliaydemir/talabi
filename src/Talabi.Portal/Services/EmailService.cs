using Talabi.Core.DTOs.Email;
using Talabi.Core.Email;
using Talabi.Core.Services;

namespace Talabi.Portal.Services;

public class EmailService : IEmailService
{
    private readonly IEmailSender _emailSender;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IEmailSender emailSender, ILogger<EmailService> logger)
    {
        _emailSender = emailSender;
        _logger = logger;
    }

    public async Task<bool> SendVendorApprovalEmailAsync(string toEmail, string vendorName, string language)
    {
        try
        {
            var subject = GetApprovalSubject(language);
            
            await _emailSender.SendEmailAsync(new EmailTemplateRequest
            {
                To = toEmail,
                Subject = subject,
                TemplateName = EmailTemplateNames.VendorApproval,
                LanguageCode = language,
                Variables = new Dictionary<string, string>
                {
                    ["vendorName"] = vendorName
                }
            });

            _logger.LogInformation("Vendor approval email sent successfully to {Email}", toEmail);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending vendor approval email to {Email}", toEmail);
            return false;
        }
    }

    public async Task<bool> SendVendorRejectionEmailAsync(string toEmail, string vendorName, string language)
    {
        try
        {
            var subject = GetRejectionSubject(language);
            
            await _emailSender.SendEmailAsync(new EmailTemplateRequest
            {
                To = toEmail,
                Subject = subject,
                TemplateName = EmailTemplateNames.VendorRejection,
                LanguageCode = language,
                Variables = new Dictionary<string, string>
                {
                    ["vendorName"] = vendorName
                }
            });

            _logger.LogInformation("Vendor rejection email sent successfully to {Email}", toEmail);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending vendor rejection email to {Email}", toEmail);
            return false;
        }
    }

    private string GetApprovalSubject(string language)
    {
        return language.ToLower() switch
        {
            "tr" => "Vendor Başvurunuz Onaylandı - Talabi",
            "ar" => "تم قبول طلب البائع الخاص بك - Talabi",
            _ => "Your Vendor Application Has Been Approved - Talabi"
        };
    }

    private string GetRejectionSubject(string language)
    {
        return language.ToLower() switch
        {
            "tr" => "Vendor Başvurunuz Hakkında - Talabi",
            "ar" => "بخصوص طلب البائع الخاص بك - Talabi",
            _ => "Regarding Your Vendor Application - Talabi"
        };
    }
}
