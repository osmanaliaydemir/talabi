using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Enums;

namespace Talabi.Portal.Controllers;

[Authorize]
public class RealtimeTrackingController(Core.Interfaces.IUnitOfWork unitOfWork) : Controller
{
    public IActionResult Index()
    {
        return View();
    }

    [HttpGet]
    public async Task<IActionResult> GetActiveDeliveries()
    {
        var vendorIdStr = HttpContext.Session.GetString("VendorId");
        if (string.IsNullOrEmpty(vendorIdStr) || !Guid.TryParse(vendorIdStr, out var vendorId))
        {
            return Unauthorized();
        }

        // Get couriers who have active assignments for this vendor's orders
        var courierLocations = await unitOfWork.OrderCouriers.Query()
            .Include(oc => oc.Courier)
            .Include(oc => oc.Order)
            .ThenInclude(o => o!.DeliveryAddress) // To show destination
            .Where(oc => oc.Order != null // Ensure Order is not null
                         && oc.Order.VendorId == vendorId
                         && oc.IsActive
                         && oc.Courier != null
                         && oc.Courier.CurrentLatitude.HasValue
                         && oc.Courier.CurrentLongitude.HasValue
                         && (oc.Order.Status == OrderStatus.Accepted ||
                             oc.Order.Status == OrderStatus.Ready ||
                             oc.Order.Status == OrderStatus.OutForDelivery))
            .Select(oc => new
            {
                CourierId = oc.Courier!.Id,
                CourierName = oc.Courier!.Name,
                Lat = oc.Courier!.CurrentLatitude,
                Lng = oc.Courier!.CurrentLongitude,
                OrderId = oc.OrderId,
                OrderNo = oc.Order!.CustomerOrderId,
                Status = oc.Order!.Status.ToString(),
                Destination = oc.Order!.DeliveryAddress != null ? oc.Order.DeliveryAddress.FullAddress : "N/A",
                Color = "blue"
            })
            .ToListAsync();

        return Json(courierLocations);
    }
}
