using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class UploadController : ControllerBase
{
    private readonly IWebHostEnvironment _environment;
    private readonly ILogger<UploadController> _logger;
    private readonly IStringLocalizer<UploadController> _localizer;

    public UploadController(
        IWebHostEnvironment environment,
        ILogger<UploadController> logger,
        IStringLocalizer<UploadController> localizer)
    {
        _environment = environment;
        _logger = logger;
        _localizer = localizer;
    }

    [HttpPost]
    public async Task<IActionResult> Upload(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { Message = _localizer["NoFileUploaded"] });

        try
        {
            // Ensure images directory exists
            var imagesPath = Path.Combine(_environment.WebRootPath, "images");
            if (!Directory.Exists(imagesPath))
                Directory.CreateDirectory(imagesPath);

            // Generate unique filename
            var extension = Path.GetExtension(file.FileName);
            var fileName = $"{Guid.NewGuid()}{extension}";
            var filePath = Path.Combine(imagesPath, fileName);

            // Save file
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Return URL
            var request = HttpContext.Request;
            var baseUrl = $"{request.Scheme}://{request.Host}";
            var url = $"{baseUrl}/images/{fileName}";

            return Ok(new { Url = url });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error uploading file");
            return StatusCode(500, new { Message = _localizer["InternalServerErrorDuringUpload"] });
        }
    }
}
