using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Talabi.Core.Services;

namespace Talabi.Infrastructure.Services;

/// <summary>
/// File upload security validation service implementation
/// </summary>
public class FileUploadSecurityService : IFileUploadSecurityService
{
    private readonly ILogger<FileUploadSecurityService> _logger;
    private readonly FileUploadSecurityOptions _options;

    // Allowed file extensions (whitelist approach)
    private static readonly string[] AllowedImageExtensions = { ".jpg", ".jpeg", ".png", ".gif", ".webp" };
    
    // Maximum file size: 5MB
    private const long MaxFileSizeBytes = 5 * 1024 * 1024;

    // Magic bytes for image validation
    private static readonly Dictionary<string, byte[][]> MagicBytes = new()
    {
        { ".jpg", new[] { new byte[] { 0xFF, 0xD8, 0xFF } } },
        { ".jpeg", new[] { new byte[] { 0xFF, 0xD8, 0xFF } } },
        { ".png", new[] { new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A } } },
        { ".gif", new[] { new byte[] { 0x47, 0x49, 0x46, 0x38, 0x37, 0x61 }, new byte[] { 0x47, 0x49, 0x46, 0x38, 0x39, 0x61 } } },
        { ".webp", new[] { new byte[] { 0x52, 0x49, 0x46, 0x46 } } } // RIFF header, WebP check needs more bytes
    };

    public FileUploadSecurityService(
        ILogger<FileUploadSecurityService> logger,
        IOptions<FileUploadSecurityOptions> options)
    {
        _logger = logger;
        _options = options.Value;
    }

    public bool IsAllowedExtension(string fileName)
    {
        if (string.IsNullOrWhiteSpace(fileName))
        {
            return false;
        }

        var extension = Path.GetExtension(fileName).ToLowerInvariant();
        
        // Check for double extension attack (e.g., image.jpg.exe)
        var fileNameWithoutExtension = Path.GetFileNameWithoutExtension(fileName);
        if (Path.HasExtension(fileNameWithoutExtension))
        {
            _logger.LogWarning("Double extension detected in filename: {FileName}", fileName);
            return false;
        }

        return AllowedImageExtensions.Contains(extension);
    }

    public bool IsValidFileSize(long fileSize)
    {
        return fileSize > 0 && fileSize <= MaxFileSizeBytes;
    }

    public async Task<bool> IsValidFileContentAsync(Stream fileStream, string fileName)
    {
        if (fileStream == null || fileStream.Length == 0)
        {
            return false;
        }

        var extension = Path.GetExtension(fileName).ToLowerInvariant();
        
        if (!MagicBytes.TryGetValue(extension, out var expectedMagicBytes))
        {
            _logger.LogWarning("No magic bytes defined for extension: {Extension}", extension);
            return false;
        }

        // Read first bytes to check magic bytes
        var buffer = new byte[Math.Min(16, fileStream.Length)];
        var originalPosition = fileStream.Position;
        
        try
        {
            fileStream.Position = 0;
            var bytesRead = await fileStream.ReadAsync(buffer, 0, buffer.Length);
            
            if (bytesRead < buffer.Length)
            {
                return false;
            }

            // Check against all possible magic byte patterns for this extension
            foreach (var magicBytesPattern in expectedMagicBytes)
            {
                if (magicBytesPattern.Length > bytesRead)
                {
                    continue;
                }

                var matches = true;
                for (int i = 0; i < magicBytesPattern.Length; i++)
                {
                    if (buffer[i] != magicBytesPattern[i])
                    {
                        matches = false;
                        break;
                    }
                }

                if (matches)
                {
                    // For WebP, additional check needed (RIFF...WEBP)
                    if (extension == ".webp" && bytesRead >= 12)
                    {
                        var webpSignature = System.Text.Encoding.ASCII.GetString(buffer, 8, 4);
                        if (webpSignature != "WEBP")
                        {
                            return false;
                        }
                    }
                    return true;
                }
            }

            _logger.LogWarning("File content does not match expected magic bytes for extension: {Extension}", extension);
            return false;
        }
        finally
        {
            fileStream.Position = originalPosition;
        }
    }

    public string SanitizeFileName(string fileName)
    {
        if (string.IsNullOrWhiteSpace(fileName))
        {
            return Guid.NewGuid().ToString();
        }

        // Remove path traversal attempts
        fileName = fileName.Replace("..", string.Empty);
        fileName = fileName.Replace("\\", string.Empty);
        fileName = fileName.Replace("/", string.Empty);

        // Remove any invalid characters
        var invalidChars = Path.GetInvalidFileNameChars();
        foreach (var invalidChar in invalidChars)
        {
            fileName = fileName.Replace(invalidChar, '_');
        }

        // Remove leading/trailing dots and spaces
        fileName = fileName.Trim('.', ' ');

        // If filename is empty after sanitization, generate a new one
        if (string.IsNullOrWhiteSpace(fileName))
        {
            fileName = Guid.NewGuid().ToString();
        }

        // Limit filename length
        if (fileName.Length > 255)
        {
            var extension = Path.GetExtension(fileName);
            var nameWithoutExtension = Path.GetFileNameWithoutExtension(fileName);
            fileName = nameWithoutExtension.Substring(0, Math.Min(255 - extension.Length, nameWithoutExtension.Length)) + extension;
        }

        return fileName;
    }
}

/// <summary>
/// File upload security options
/// </summary>
public class FileUploadSecurityOptions
{
    public long MaxFileSizeBytes { get; set; } = 5 * 1024 * 1024; // 5MB default
    public string[] AllowedExtensions { get; set; } = Array.Empty<string>(); // If empty, uses default
}

