using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace Talabi.Infrastructure.Services;

public interface IEmailTemplateRenderer
{
    Task<string> RenderAsync(string templateName, IDictionary<string, string> variables, string? languageCode = null, CancellationToken cancellationToken = default);
}

public class EmailTemplateRenderer : IEmailTemplateRenderer
{
    private const string TemplateRootNamespace = "Talabi.Infrastructure.Templates.";
    private readonly Assembly _assembly = typeof(EmailTemplateRenderer).Assembly;
    private readonly ConcurrentDictionary<string, string> _templateCache = new(StringComparer.OrdinalIgnoreCase);

    public async Task<string> RenderAsync(string templateName, IDictionary<string, string> variables, string? languageCode = null, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(templateName))
        {
            throw new ArgumentException("Template name must be provided.", nameof(templateName));
        }

        var template = await GetTemplateAsync(templateName, languageCode, cancellationToken);
        if (variables is null || variables.Count == 0)
        {
            return template;
        }

        var builder = new StringBuilder(template);
        foreach (var (key, value) in variables)
        {
            builder.Replace($"{{{{{key}}}}}", value ?? string.Empty);
        }

        return builder.ToString();
    }

    private async Task<string> GetTemplateAsync(string templateName, string? languageCode, CancellationToken cancellationToken)
    {
        // Normalize language code
        languageCode = NormalizeLanguageCode(languageCode);
        
        // Try to get language-specific template first
        var cacheKey = $"{templateName}_{languageCode}";
        if (_templateCache.TryGetValue(cacheKey, out var cached))
        {
            return cached;
        }

        // Try language-specific template
        var languageSpecificResourceName = $"{TemplateRootNamespace}{templateName}_{languageCode}.html";
        var stream = _assembly.GetManifestResourceStream(languageSpecificResourceName);

        // Fallback to default template if language-specific doesn't exist
        if (stream == null)
        {
            var defaultResourceName = $"{TemplateRootNamespace}{templateName}.html";
            stream = _assembly.GetManifestResourceStream(defaultResourceName)
                ?? throw new InvalidOperationException($"E-posta template dosyası bulunamadı: {defaultResourceName}");
        }

        await using (stream)
        {
            using var reader = new StreamReader(stream);
            var content = await reader.ReadToEndAsync();
            _templateCache[cacheKey] = content;
            return content;
        }
    }

    private static string NormalizeLanguageCode(string? languageCode)
    {
        if (string.IsNullOrWhiteSpace(languageCode))
        {
            return "tr"; // Default to Turkish
        }

        // Normalize to lowercase and handle common variations
        var normalized = languageCode.ToLowerInvariant().Trim();
        
        // Map common language codes
        return normalized switch
        {
            "tr" or "turkish" => "tr",
            "en" or "english" => "en",
            "ar" or "arabic" => "ar",
            _ => "tr" // Default fallback
        };
    }
}

