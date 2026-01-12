namespace Talabi.Portal.Services;

public interface IEmailService
{
    Task<bool> SendVendorApprovalEmailAsync(string toEmail, string vendorName, string language);
    Task<bool> SendVendorRejectionEmailAsync(string toEmail, string vendorName, string language);
}
