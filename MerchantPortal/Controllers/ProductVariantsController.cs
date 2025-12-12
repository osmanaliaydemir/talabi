using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class ProductVariantsController : Controller
{
	private readonly IMarketProductVariantService _variantService;
	private readonly ILogger<ProductVariantsController> _logger;

	public ProductVariantsController(IMarketProductVariantService variantService, ILogger<ProductVariantsController> logger)
	{
		_variantService = variantService;
		_logger = logger;
	}

	public async Task<IActionResult> Index(Guid productId, int page = 1)
	{
		var variants = await _variantService.GetVariantsAsync(productId, page, 20);
		ViewBag.ProductId = productId;
		return View(variants);
	}

	[HttpGet]
	public IActionResult Create(Guid productId)
	{
		ViewBag.ProductId = productId;
		return View(new CreateMarketProductVariantRequest { ProductId = productId });
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Create(CreateMarketProductVariantRequest model)
	{
		if (!ModelState.IsValid)
			return View(model);

		var created = await _variantService.CreateVariantAsync(model);
		if (created == null)
		{
			ModelState.AddModelError(string.Empty, "Varyant oluşturulamadı");
			return View(model);
		}

		TempData["SuccessMessage"] = "Varyant oluşturuldu";
		return RedirectToAction(nameof(Index), new { productId = model.ProductId });
	}

	[HttpGet]
	public async Task<IActionResult> Edit(Guid id)
	{
		var variant = await _variantService.GetVariantAsync(id);
		if (variant == null) return NotFound();

		var model = new UpdateMarketProductVariantRequest
		{
			ProductId = variant.ProductId,
			Name = variant.Name,
			Sku = variant.Sku,
			Price = variant.Price,
			StockQuantity = variant.StockQuantity,
			IsActive = variant.IsActive
		};

		ViewBag.VariantId = id;
		return View(model);
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Edit(Guid id, UpdateMarketProductVariantRequest model)
	{
		if (!ModelState.IsValid)
			return View(model);

		var updated = await _variantService.UpdateVariantAsync(id, model);
		if (updated == null)
		{
			ModelState.AddModelError(string.Empty, "Varyant güncellenemedi");
			return View(model);
		}

		TempData["SuccessMessage"] = "Varyant güncellendi";
		return RedirectToAction(nameof(Index), new { productId = updated.ProductId });
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> Delete(Guid id, Guid productId)
	{
		var ok = await _variantService.DeleteVariantAsync(id);
		TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok ? "Varyant silindi" : "Varyant silinemedi";
		return RedirectToAction(nameof(Index), new { productId });
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> UpdateStock(Guid id, Guid productId, int quantity)
	{
		var ok = await _variantService.UpdateVariantStockAsync(id, quantity);
		TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok ? "Stok güncellendi" : "Stok güncellenemedi";
		return RedirectToAction(nameof(Index), new { productId });
	}
}


