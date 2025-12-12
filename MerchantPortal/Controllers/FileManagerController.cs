using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize(Roles = "MerchantOwner,Admin")]
public class FileManagerController : Controller
{
    private readonly IFileManagerService _fileManagerService;
    private readonly ILogger<FileManagerController> _logger;

    public FileManagerController(
        IFileManagerService fileManagerService,
        ILogger<FileManagerController> logger)
    {
        _fileManagerService = fileManagerService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> Index(int page = 1, int pageSize = 20)
    {
        var files = await _fileManagerService.GetMerchantFilesAsync(page, pageSize);
        var viewModel = new FileManagerViewModel
        {
            Files = files ?? new PagedResult<FileUploadResponse>
            {
                Items = new List<FileUploadResponse>(),
                TotalCount = 0,
                Page = page,
                PageSize = pageSize,
                TotalPages = 0
            }
        };

        return View(viewModel);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Upload(IFormFile? file)
    {
        if (file == null || file.Length == 0)
        {
            TempData["Error"] = "Lütfen yüklemek için bir dosya seçin.";
            return RedirectToAction(nameof(Index));
        }

        var result = await _fileManagerService.UploadMerchantFileAsync(file);
        if (result == null)
        {
            TempData["Error"] = "Dosya yüklenirken bir hata oluştu.";
        }
        else
        {
            TempData["Success"] = "Dosya başarıyla yüklendi.";
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(string containerName, string fileName)
    {
        if (string.IsNullOrWhiteSpace(containerName) || string.IsNullOrWhiteSpace(fileName))
        {
            TempData["Error"] = "Silinecek dosya bulunamadı.";
            return RedirectToAction(nameof(Index));
        }

        var success = await _fileManagerService.DeleteMerchantFileAsync(containerName, fileName);
        TempData[success ? "Success" : "Error"] = success
            ? "Dosya silindi."
            : "Dosya silinirken bir hata oluştu.";

        return RedirectToAction(nameof(Index));
    }
}

