using Ganss.Xss;
using Talabi.Core.Interfaces;

namespace Talabi.Infrastructure.Services;

/// <summary>
/// Input sanitization service implementation for XSS protection
/// </summary>
public class InputSanitizationService : IInputSanitizationService
{
    private readonly HtmlSanitizer _htmlSanitizer;

    public InputSanitizationService()
    {
        _htmlSanitizer = new HtmlSanitizer();
        
        // Allow safe HTML tags and attributes
        _htmlSanitizer.AllowedTags.Clear();
        _htmlSanitizer.AllowedTags.UnionWith(new[] { "p", "br", "strong", "em", "u", "ul", "ol", "li", "h1", "h2", "h3", "h4", "h5", "h6" });
        
        // Allow safe attributes
        _htmlSanitizer.AllowedAttributes.Clear();
        _htmlSanitizer.AllowedAttributes.UnionWith(new[] { "class", "id" });
        
        // Remove all CSS
        _htmlSanitizer.AllowedCssProperties.Clear();
        
        // Remove all schemes (javascript:, data:, etc.)
        _htmlSanitizer.AllowedSchemes.Clear();
        _htmlSanitizer.AllowedSchemes.UnionWith(new[] { "http", "https" });
        
        // Remove dangerous attributes
        _htmlSanitizer.AllowDataAttributes = false;
    }

    public string SanitizeHtml(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return string.Empty;
        }

        return _htmlSanitizer.Sanitize(input);
    }

    public IEnumerable<string> SanitizeHtml(IEnumerable<string?> inputs)
    {
        if (inputs == null)
        {
            return Enumerable.Empty<string>();
        }

        return inputs.Select(SanitizeHtml);
    }

    public bool ContainsDangerousContent(string? input)
    {
        if (string.IsNullOrWhiteSpace(input))
        {
            return false;
        }

        var sanitized = SanitizeHtml(input);
        return sanitized != input;
    }
}

