using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class DocumentsController : Controller
{
	private const int DefaultPageSize = 20;
	private static readonly string[] StatusOptions = { "Pending", "Approved", "Rejected", "Expired" };

	private readonly IMerchantDocumentService _documentService;
	private readonly IMerchantService _merchantService;
	private readonly ILogger<DocumentsController> _logger;

	public DocumentsController(IMerchantDocumentService documentService, IMerchantService merchantService, ILogger<DocumentsController> logger)
	{
		_documentService = documentService;
		_merchantService = merchantService;
		_logger = logger;
	}

	public async Task<IActionResult> Index(string? status = null, string? documentType = null, int page = 1)
	{
		var me = await _merchantService.GetMyMerchantAsync();
		if (me == null) return NotFound();

		var documentsTask = _documentService.GetDocumentsAsync(me.Id, documentType, status, page, DefaultPageSize);
		var progressTask = _documentService.GetProgressAsync(me.Id);
		var requiredTypesTask = _documentService.GetRequiredTypesAsync();
		MerchantDocumentStatisticsResponse? statistics = null;

		if (User.IsInRole("Admin"))
		{
			statistics = await _documentService.GetStatisticsAsync(me.Id);
		}

		var documents = await documentsTask ?? new PagedResult<MerchantDocumentResponse>();
		var progress = await progressTask;
		var requiredTypes = await requiredTypesTask ?? Array.Empty<DocumentTypeResponse>();

		var model = new MerchantDocumentsViewModel
		{
			MerchantId = me.Id,
			Documents = documents,
			Progress = progress,
			RequiredTypes = requiredTypes,
			SelectedStatus = status,
			SelectedDocumentType = documentType,
			IsAdmin = User.IsInRole("Admin"),
			Statistics = statistics
		};

		ViewBag.StatusOptions = StatusOptions;
		return View(model);
	}

	[HttpGet]
	public async Task<IActionResult> Upload(Guid merchantId)
	{
		var types = await _documentService.GetRequiredTypesAsync() ?? Array.Empty<DocumentTypeResponse>();
		var model = new UploadMerchantDocumentViewModel
		{
			Request = new UploadMerchantDocumentRequest { MerchantId = merchantId },
			AvailableTypes = types
		};
		return View(model);
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Upload(UploadMerchantDocumentViewModel model, IFormFile file)
	{
		model.AvailableTypes = await _documentService.GetRequiredTypesAsync() ?? Array.Empty<DocumentTypeResponse>();

		if (model.Request.MerchantId == Guid.Empty)
		{
			ModelState.AddModelError(string.Empty, "Geçersiz mağaza bilgisi.");
		}

		if (file == null || file.Length == 0)
		{
			ModelState.AddModelError(string.Empty, "Lütfen bir dosya seçin.");
		}

		if (!ModelState.IsValid)
		{
			return View(model);
		}

		var created = await _documentService.UploadAsync(model.Request, file);
		if (created == null)
		{
			ModelState.AddModelError(string.Empty, "Belge yüklenemedi.");
			return View(model);
		}

		TempData["SuccessMessage"] = "Belge yüklendi.";
		return RedirectToAction(nameof(Index));
	}

	[HttpGet]
	public async Task<IActionResult> Details(Guid id)
	{
		var document = await _documentService.GetDocumentAsync(id);
		if (document == null) return NotFound();

		var viewModel = new MerchantDocumentDetailViewModel
		{
			Document = document,
			IsAdmin = User.IsInRole("Admin")
		};

		return View(viewModel);
	}

	[HttpGet]
	public async Task<IActionResult> Download(Guid id)
	{
		var result = await _documentService.DownloadAsync(id);
		if (result == null)
		{
			TempData["ErrorMessage"] = "Belge indirilemedi.";
			return RedirectToAction(nameof(Details), new { id });
		}

		return File(result.Content, result.ContentType, result.FileName);
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Delete(Guid id)
	{
		var ok = await _documentService.DeleteAsync(id);
		TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok ? "Belge silindi" : "Belge silinemedi";
		return RedirectToAction(nameof(Index));
	}

	[HttpPost]
	[Authorize(Roles = "Admin")]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Verify(Guid id, DocumentVerificationInput input, string? returnUrl = null)
	{
		if (!ModelState.IsValid)
		{
			return await Details(id);
		}

		if (!input.IsApproved && string.IsNullOrWhiteSpace(input.RejectionReason))
		{
			ModelState.AddModelError(nameof(input.RejectionReason), "Red gerekçesi zorunludur.");
			return await Details(id);
		}

		var request = new VerifyMerchantDocumentRequest
		{
			DocumentId = id,
			IsApproved = input.IsApproved,
			VerificationNotes = input.VerificationNotes,
			RejectionReason = input.IsApproved ? null : input.RejectionReason
		};

		var updated = await _documentService.VerifyDocumentAsync(id, request);
		if (updated == null)
		{
			TempData["ErrorMessage"] = "Belge onaylama işlemi başarısız.";
		}
		else
		{
			TempData["SuccessMessage"] = request.IsApproved ? "Belge onaylandı." : "Belge reddedildi.";
		}

		if (!string.IsNullOrWhiteSpace(returnUrl))
		{
			return LocalRedirect(returnUrl);
		}

		return RedirectToAction(nameof(Details), new { id });
	}

	[HttpGet]
	[Authorize(Roles = "Admin")]
	public async Task<IActionResult> Pending(int page = 1)
	{
		var pending = await _documentService.GetPendingDocumentsAsync(page, DefaultPageSize) ?? new PagedResult<MerchantDocumentResponse>();
		var viewModel = new PendingDocumentsViewModel
		{
			Documents = pending,
			IsAdmin = true
		};

		return View(viewModel);
	}

	[HttpPost]
	[Authorize(Roles = "Admin")]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> BulkVerify(BulkVerifyDocumentsInput input)
	{
		if (!ModelState.IsValid)
		{
			return await Pending();
		}

		var request = new BulkVerifyDocumentsRequest
		{
			DocumentIds = input.DocumentIds,
			IsApproved = input.IsApproved,
			VerificationNotes = input.VerificationNotes
		};

		var result = await _documentService.BulkVerifyDocumentsAsync(request);
		if (result == null)
		{
			TempData["ErrorMessage"] = "Toplu onay işlemi başarısız.";
		}
		else
		{
			TempData["SuccessMessage"] = $"Toplam {result.TotalDocuments} belgeden {result.SuccessfulVerifications} tanesi güncellendi.";
			if (result.Errors.Count > 0)
			{
				TempData["InfoMessage"] = string.Join(Environment.NewLine, result.Errors);
			}
		}

		return RedirectToAction(nameof(Pending));
	}
}

