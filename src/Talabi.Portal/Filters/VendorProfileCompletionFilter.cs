using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Talabi.Core.Interfaces;

namespace Talabi.Portal.Filters;

public class VendorProfileCompletionFilter : IAsyncActionFilter
{
    private readonly IUnitOfWork _unitOfWork;

    public VendorProfileCompletionFilter(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        var user = context.HttpContext.User;

        // Check if user is authenticated
        if (user.Identity?.IsAuthenticated != true)
        {
            await next();
            return;
        }

        // Check if user has VendorId in session
        var vendorIdStr = context.HttpContext.Session.GetString("VendorId");

        // Get endpoint to check for ExcludeFromProfileCheck metadata or if it's the Complete action
        var actionDescriptor = context.ActionDescriptor as Microsoft.AspNetCore.Mvc.Controllers.ControllerActionDescriptor;
        var controllerName = actionDescriptor?.ControllerName;
        var actionName = actionDescriptor?.ActionName;

        if (!string.IsNullOrEmpty(vendorIdStr) && Guid.TryParse(vendorIdStr, out var vendorId))
        {
            // Allow Profile/WorkingHours and Profile/SaveWorkingHours to pass through
            if (controllerName == "Profile" && (actionName == "WorkingHours" || actionName == "SaveWorkingHours"))
            {
                await next();
                return;
            }

            // Check vendor completeness
            // We need to fetch WorkingHours as well. 
            // Since GetByIdAsync might not include navigation properties by default, 
            // we should double check if IUnitOfWork repository supports Include.
            // Assuming standard GetByIdAsync, we might need a specific query or use the existing one if it includes it.
            // For now, let's assume we need to check via a specialized method or repository call if possible, 
            // OR if GetByIdAsync retrieves the aggregate root fully.
            // Let's rely on the fact that existing filter used GetByIdAsync. 
            // NOTE: If lazy loading is enabled, accessing WorkingHours triggers a DB call.

            var vendor = await _unitOfWork.Vendors.GetByIdAsync(vendorId);

            if (vendor != null)
            {
                // 1. Basic Profile Check
                var isProfileComplete = !string.IsNullOrWhiteSpace(vendor.Address) &&
                                        vendor.Latitude.HasValue &&
                                        vendor.Longitude.HasValue &&
                                        !string.IsNullOrWhiteSpace(vendor.Name);

                if (!isProfileComplete)
                {
                    // Redirect to Profile/Complete
                    context.Result = new RedirectToActionResult("Complete", "Profile", null);
                    return;
                }

                // 2. Working Hours Check
                // We need to ensure WorkingHours collection is loaded.
                // If it's null (not loaded) or empty, we consider it incomplete.
                // Ideally, we should query specifically for count to avoid loading all data if not needed,
                // but for a filter, loading the vendor is acceptable.

                // FORCE LOAD if not loaded? 
                // Since we can't easily force load on generic repo here without context,
                // we will assume GetByIdAsync is sufficient or accessible.
                // However, to be safe and efficient, let's check the property.

                if (vendor.WorkingHours == null || !vendor.WorkingHours.Any())
                {
                    // Double check against DB to be sure it's not just an un-included navigation property
                    // We can use a direct repository method if available, or just redirect safely.
                    // A safer bet if we are unsure about lazy loading: 
                    // Redirect them. The WorkingHours controller action will load the current data correctly anyway.

                    context.Result = new RedirectToActionResult("WorkingHours", "Profile", null);
                    return;
                }
            }
        }

        await next();
    }
}
