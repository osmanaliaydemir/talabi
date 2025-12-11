using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Interfaces;
using Talabi.Core.Services;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class UploadController : BaseController
{
    private readonly IWebHostEnvironment _environment;
    private readonly IFileUploadSecurityService _securityService;
    private const string ResourceName = "UploadResources";

    public UploadController(
        IUnitOfWork unitOfWork,
        ILogger<UploadController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        IWebHostEnvironment environment,
        IFileUploadSecurityService securityService)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _environment = environment;
        _securityService = securityService;
    }

    [HttpPost]
    public async Task<IActionResult> Upload(IFormFile file)
    {
        // Validate file exists
        if (file == null || file.Length == 0)
        {
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "NoFileUploaded", CurrentCulture),
                "NO_FILE_UPLOADED"));
        }

        // Validate file extension
        if (!_securityService.IsAllowedExtension(file.FileName))
        {
            Logger.LogWarning("Invalid file extension attempted: {FileName}", file.FileName);
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "InvalidFileType", CurrentCulture),
                "INVALID_FILE_TYPE"));
        }

        // Validate file size
        if (!_securityService.IsValidFileSize(file.Length))
        {
            Logger.LogWarning("File size too large: {FileSize} bytes", file.Length);
            return BadRequest(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "FileTooLarge", CurrentCulture),
                "FILE_TOO_LARGE"));
        }

        // Validate file content (magic bytes)
        using (var fileStream = file.OpenReadStream())
        {
            var isValidContent = await _securityService.IsValidFileContentAsync(fileStream, file.FileName);
            if (!isValidContent)
            {
                Logger.LogWarning("Invalid file content detected: {FileName}", file.FileName);
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString(ResourceName, "InvalidFileContent", CurrentCulture),
                    "INVALID_FILE_CONTENT"));
            }
        }

        try
        {
            // Sanitize filename
            var sanitizedFileName = _securityService.SanitizeFileName(file.FileName);
            var extension = Path.GetExtension(sanitizedFileName);
            
            // Generate unique filename
            var fileName = $"{Guid.NewGuid()}{extension}";

            // Ensure images directory exists
            var imagesPath = Path.Combine(_environment.WebRootPath, "images");
            if (!Directory.Exists(imagesPath))
            {
                Directory.CreateDirectory(imagesPath);
            }

            var filePath = Path.Combine(imagesPath, fileName);

            // Save file
            using (var fileStream = file.OpenReadStream())
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await fileStream.CopyToAsync(stream);
            }

            // Return URL
            var request = HttpContext.Request;
            var baseUrl = $"{request.Scheme}://{request.Host}";
            var url = $"{baseUrl}/images/{fileName}";

            Logger.LogInformation("File uploaded successfully: {FileName}, Size: {Size} bytes", fileName, file.Length);

            return Ok(new ApiResponse<object>(new { Url = url }, 
                LocalizationService.GetLocalizedString(ResourceName, "FileUploadedSuccessfully", CurrentCulture)));
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error uploading file: {FileName}", file.FileName);
            return StatusCode(500, new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "UploadError", CurrentCulture),
                "UPLOAD_ERROR"));
        }
    }
}
