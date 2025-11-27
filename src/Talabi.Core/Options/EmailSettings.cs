namespace Talabi.Core.Options;

public class EmailSettings
{
    // SMTP Server Settings
    public required string SmtpServer { get; init; }
    public int SmtpPort { get; init; } = 587;
    public bool UseSsl { get; init; } = true;
    public bool UseTls { get; init; } = true;
    
    // Authentication
    public required string SenderEmail { get; init; }
    public required string SenderPassword { get; init; }
    public string SenderName { get; init; } = "Talabi";
    
    // Optional: Timeout settings
    public int Timeout { get; init; } = 30000; // milliseconds
}

