using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize]
public class ProductOptionsController : Controller
{
	private readonly IProductOptionService _optionService;
	private readonly ILogger<ProductOptionsController> _logger;

	public ProductOptionsController(IProductOptionService optionService, ILogger<ProductOptionsController> logger)
	{
		_optionService = optionService;
		_logger = logger;
	}

	public async Task<IActionResult> Groups(Guid productId, int page = 1)
	{
		var groups = await _optionService.GetGroupsAsync(productId, page, 20);
		ViewBag.ProductId = productId;
		return View(groups);
	}

	[HttpGet]
	public IActionResult CreateGroup(Guid productId)
	{
		return View(new CreateProductOptionGroupRequest { ProductId = productId });
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> CreateGroup(CreateProductOptionGroupRequest model)
	{
		if (!ModelState.IsValid)
			return View(model);

		var created = await _optionService.CreateGroupAsync(model);
		if (created == null)
		{
			ModelState.AddModelError(string.Empty, "Grup oluşturulamadı");
			return View(model);
		}

		TempData["SuccessMessage"] = "Grup oluşturuldu";
		return RedirectToAction(nameof(Groups), new { productId = model.ProductId });
	}

	[HttpGet]
	public async Task<IActionResult> EditGroup(Guid id)
	{
		var group = await _optionService.GetGroupAsync(id);
		if (group == null) return NotFound();

		var model = new UpdateProductOptionGroupRequest
		{
			ProductId = group.ProductId,
			Name = group.Name,
			Description = group.Description,
			DisplayOrder = group.DisplayOrder,
			IsRequired = group.IsRequired
		};

		ViewBag.GroupId = id;
		return View(model);
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> EditGroup(Guid id, UpdateProductOptionGroupRequest model)
	{
		if (!ModelState.IsValid)
			return View(model);

		var updated = await _optionService.UpdateGroupAsync(id, model);
		if (updated == null)
		{
			ModelState.AddModelError(string.Empty, "Grup güncellenemedi");
			return View(model);
		}

		TempData["SuccessMessage"] = "Grup güncellendi";
		return RedirectToAction(nameof(Groups), new { productId = updated.ProductId });
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> DeleteGroup(Guid id, Guid productId)
	{
		var ok = await _optionService.DeleteGroupAsync(id);
		TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok ? "Grup silindi" : "Grup silinemedi";
		return RedirectToAction(nameof(Groups), new { productId });
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> ReorderGroups(Guid productId, List<Guid> orderedGroupIds)
	{
		var ok = await _optionService.ReorderGroupsAsync(productId, orderedGroupIds);
		TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok ? "Sıralama güncellendi" : "Sıralama güncellenemedi";
		return RedirectToAction(nameof(Groups), new { productId });
	}

	public async Task<IActionResult> Options(Guid groupId, int page = 1)
	{
		var options = await _optionService.GetOptionsAsync(groupId, page, 20);
		ViewBag.GroupId = groupId;
		return View(options);
	}

	[HttpGet]
	public IActionResult CreateOption(Guid groupId)
	{
		return View(new CreateProductOptionRequest { ProductOptionGroupId = groupId });
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> CreateOption(CreateProductOptionRequest model)
	{
		if (!ModelState.IsValid)
			return View(model);

		var created = await _optionService.CreateOptionAsync(model);
		if (created == null)
		{
			ModelState.AddModelError(string.Empty, "Seçenek oluşturulamadı");
			return View(model);
		}

		TempData["SuccessMessage"] = "Seçenek oluşturuldu";
		return RedirectToAction(nameof(Options), new { groupId = model.ProductOptionGroupId });
	}

	[HttpGet]
	public async Task<IActionResult> EditOption(Guid id)
	{
		var option = await _optionService.GetOptionAsync(id);
		if (option == null) return NotFound();

		var model = new UpdateProductOptionRequest
		{
			ProductOptionGroupId = option.ProductOptionGroupId,
			Name = option.Name,
			Description = option.Description,
			ExtraPrice = option.ExtraPrice,
			DisplayOrder = option.DisplayOrder,
			IsActive = option.IsActive
		};

		ViewBag.OptionId = id;
		return View(model);
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> EditOption(Guid id, UpdateProductOptionRequest model)
	{
		if (!ModelState.IsValid)
			return View(model);

		var updated = await _optionService.UpdateOptionAsync(id, model);
		if (updated == null)
		{
			ModelState.AddModelError(string.Empty, "Seçenek güncellenemedi");
			return View(model);
		}

		TempData["SuccessMessage"] = "Seçenek güncellendi";
		return RedirectToAction(nameof(Options), new { groupId = updated.ProductOptionGroupId });
	}

	[HttpPost]
	[ValidateAntiForgeryToken]
	public async Task<IActionResult> DeleteOption(Guid id, Guid groupId)
	{
		var ok = await _optionService.DeleteOptionAsync(id);
		TempData[ok ? "SuccessMessage" : "ErrorMessage"] = ok ? "Seçenek silindi" : "Seçenek silinemedi";
		return RedirectToAction(nameof(Options), new { groupId });
	}
}


