namespace Talabi.Core.Options;

public class EmailSettings
{
    public required string ApiBaseUrl { get; init; }
    public string SendEndpoint { get; init; } = "/emails/send";
    public required string ApiKey { get; init; }
    public required string SenderEmail { get; init; }
    public string SenderName { get; init; } = "Talabi";
    public string ApiKeyHeaderName { get; init; } = "Authorization";
    public string AuthorizationScheme { get; init; } = "Bearer";
}

