using Microsoft.AspNetCore.Mvc;
using Talabi.Portal.Services;
using Talabi.Core.Enums;

namespace Talabi.Portal.ViewComponents;

public class HeaderStatusViewComponent : ViewComponent
{
    private readonly ISettingsService _settingsService;

    public HeaderStatusViewComponent(ISettingsService settingsService)
    {
        _settingsService = settingsService;
    }

    public async Task<IViewComponentResult> InvokeAsync()
    {
        var settings = await _settingsService.GetVendorSettingsAsync();
        // If settings is null, assume Normal status
        var status = settings?.BusyStatus ?? BusyStatus.Normal;
        return View(status);
    }
}
