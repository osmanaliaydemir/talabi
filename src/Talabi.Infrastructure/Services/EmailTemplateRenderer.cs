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
    Task<string> RenderAsync(string templateName, IDictionary<string, string> variables, CancellationToken cancellationToken = default);
}

public class EmailTemplateRenderer : IEmailTemplateRenderer
{
    private const string TemplateRootNamespace = "Talabi.Infrastructure.Templates.";
    private readonly Assembly _assembly = typeof(EmailTemplateRenderer).Assembly;
    private readonly ConcurrentDictionary<string, string> _templateCache = new(StringComparer.OrdinalIgnoreCase);

    public async Task<string> RenderAsync(string templateName, IDictionary<string, string> variables, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(templateName))
        {
            throw new ArgumentException("Template name must be provided.", nameof(templateName));
        }

        var template = await GetTemplateAsync(templateName, cancellationToken);
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

    private async Task<string> GetTemplateAsync(string templateName, CancellationToken cancellationToken)
    {
        if (_templateCache.TryGetValue(templateName, out var cached))
        {
            return cached;
        }

        var resourceName = $"{TemplateRootNamespace}{templateName}.html";
        await using var stream = _assembly.GetManifestResourceStream(resourceName)
            ?? throw new InvalidOperationException($"E-posta template dosyası bulunamadı: {resourceName}");

        using var reader = new StreamReader(stream);
        var content = await reader.ReadToEndAsync();
        _templateCache[templateName] = content;

        return content;
    }
}

