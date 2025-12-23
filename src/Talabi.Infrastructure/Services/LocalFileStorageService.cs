using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Talabi.Core.Interfaces;
using Talabi.Core.Services;

namespace Talabi.Infrastructure.Services;

public class LocalFileStorageService : IFileStorageService
{
    private readonly IWebHostEnvironment _environment;
    private readonly IFileUploadSecurityService _securityService;
    private readonly ILogger<LocalFileStorageService> _logger;

    public LocalFileStorageService(
        IWebHostEnvironment environment,
        IFileUploadSecurityService securityService,
        ILogger<LocalFileStorageService> logger)
    {
        _environment = environment;
        _securityService = securityService;
        _logger = logger;
    }

    public async Task<string> SaveFileAsync(IFormFile file, string folderName, CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
        {
            throw new ArgumentException("File is empty", nameof(file));
        }

        // 1. Validation
        if (!_securityService.IsValidFileSize(file.Length))
        {
            throw new ArgumentException("File size exceeds limit");
        }

        if (!_securityService.IsAllowedExtension(file.FileName))
        {
            throw new ArgumentException("File extension not allowed");
        }

        using (var stream = file.OpenReadStream())
        {
            if (!await _securityService.IsValidFileContentAsync(stream, file.FileName))
            {
                throw new ArgumentException("File content is invalid or corrupted");
            }
        }

        // 2. Prepare Path
        var uploadsFolder = Path.Combine(_environment.WebRootPath, "uploads", folderName);
        if (!Directory.Exists(uploadsFolder))
        {
            Directory.CreateDirectory(uploadsFolder);
        }

        // 3. Generate Secure Filename
        var extension = Path.GetExtension(file.FileName);
        var originalName = Path.GetFileNameWithoutExtension(file.FileName);
        var safeName = _securityService.SanitizeFileName(originalName);
        var fileName = $"{safeName}_{Guid.NewGuid().ToString().Substring(0, 8)}{extension}";
        
        var filePath = Path.Combine(uploadsFolder, fileName);

        // 4. Save
        using (var stream = new FileStream(filePath, FileMode.Create))
        {
            await file.CopyToAsync(stream, cancellationToken);
        }

        _logger.LogInformation("File saved locally: {Path}", filePath);

        // Return relative URL for database
        return $"/uploads/{folderName}/{fileName}";
    }

    public Task DeleteFileAsync(string filePath, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrEmpty(filePath)) return Task.CompletedTask;

        try
        {
            // Convert relative URL to physical path
            // Assumes filePath starts with /uploads/
            var relativePath = filePath.TrimStart('/');
            var physicalPath = Path.Combine(_environment.WebRootPath, relativePath);

            if (File.Exists(physicalPath))
            {
                File.Delete(physicalPath);
                _logger.LogInformation("File deleted: {Path}", physicalPath);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting file: {Path}", filePath);
            // We usually don't throw here to avoid breaking the main transaction flow
        }

        return Task.CompletedTask;
    }
}
