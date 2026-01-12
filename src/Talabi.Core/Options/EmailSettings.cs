namespace Talabi.Core.Options;

public class EmailSettings
{
    // SMTP Server Settings
    public required string SmtpServer { get; init; }
    public int SmtpPort { get; init; } = 587;

    // Authentication
    public required string SenderEmail { get; init; }
    public required string SenderPassword { get; init; }
    public string SenderName { get; init; } = "Talabi";

    // SSL/TLS Settings
    public bool UseSsl { get; init; } = true;
    public bool UseTls { get; init; } = false;

    // Timeout
    public int Timeout { get; init; } = 30000;

    // Admin Email
    public string? AdminEmail { get; init; }
}

