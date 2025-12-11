namespace Talabi.Core.Services;

/// <summary>
/// File upload security validation service
/// </summary>
public interface IFileUploadSecurityService
{
    /// <summary>
    /// Validates file extension against whitelist
    /// </summary>
    bool IsAllowedExtension(string fileName);

    /// <summary>
    /// Validates file size
    /// </summary>
    bool IsValidFileSize(long fileSize);

    /// <summary>
    /// Validates file content using magic bytes
    /// </summary>
    Task<bool> IsValidFileContentAsync(Stream fileStream, string fileName);

    /// <summary>
    /// Sanitizes filename to prevent path traversal
    /// </summary>
    string SanitizeFileName(string fileName);
}

