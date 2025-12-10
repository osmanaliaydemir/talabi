namespace Talabi.Core.Interfaces;

/// <summary>
/// Input sanitization service for XSS protection
/// </summary>
public interface IInputSanitizationService
{
    /// <summary>
    /// Sanitizes HTML content by removing potentially dangerous scripts and tags
    /// </summary>
    /// <param name="input">Input string to sanitize</param>
    /// <returns>Sanitized string</returns>
    string SanitizeHtml(string? input);

    /// <summary>
    /// Sanitizes a collection of strings
    /// </summary>
    /// <param name="inputs">Collection of strings to sanitize</param>
    /// <returns>Collection of sanitized strings</returns>
    IEnumerable<string> SanitizeHtml(IEnumerable<string?> inputs);

    /// <summary>
    /// Checks if input contains potentially dangerous content
    /// </summary>
    /// <param name="input">Input string to check</param>
    /// <returns>True if input contains dangerous content</returns>
    bool ContainsDangerousContent(string? input);
}

