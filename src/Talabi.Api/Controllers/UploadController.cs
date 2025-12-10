using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Globalization;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class UploadController : BaseController
{
    private readonly IWebHostEnvironment _environment;
    private const string ResourceName = "UploadResources";

    public UploadController(
        IUnitOfWork unitOfWork,
        ILogger<UploadController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        IWebHostEnvironment environment)
        : base(unitOfWork, logger, localizationService, userContext)
    {
        _environment = environment;
    }

    [HttpPost]
    public async Task<IActionResult> Upload(IFormFile file)
    {
        if (file == null || file.Length == 0)
            return BadRequest(new { Message = LocalizationService.GetLocalizedString(ResourceName, "NoFileUploaded", CurrentCulture) });
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
}
