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

        // Get endpoint to check for ExcludeFromProfileCheck metadata or if it's the Complete action
        var actionDescriptor = context.ActionDescriptor as Microsoft.AspNetCore.Mvc.Controllers.ControllerActionDescriptor;
        if (actionDescriptor != null)
        {
            var controllerName = actionDescriptor.ControllerName;
            var actionName = actionDescriptor.ActionName;

            // Allow Profile/Complete, Auth/Logout, and static assets if any
            if ((controllerName == "Profile" && actionName == "Complete") ||
                (controllerName == "Auth" && actionName == "Logout") ||
                (controllerName == "Auth" && actionName == "Login")) // Just in case
            {
                await next();
                return;
            }
        }

        // Check if user has VendorId in session
        var vendorIdStr = context.HttpContext.Session.GetString("VendorId");
        if (!string.IsNullOrEmpty(vendorIdStr) && Guid.TryParse(vendorIdStr, out var vendorId))
        {
            // Check vendor completeness
            // We use AsNoTracking for performance since we read-only
            var vendor = await _unitOfWork.Vendors.GetByIdAsync(vendorId);

            if (vendor != null)
            {
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
            }
        }

        await next();
    }
}
