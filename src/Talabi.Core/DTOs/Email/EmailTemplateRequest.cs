using System;
using System.Collections.Generic;

namespace Talabi.Core.DTOs.Email;

public class EmailTemplateRequest
{
    public required string To { get; init; }
    public required string Subject { get; init; }
    public required string TemplateName { get; init; }
    public IDictionary<string, string> Variables { get; init; } = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
    public string? LanguageCode { get; init; }
}

