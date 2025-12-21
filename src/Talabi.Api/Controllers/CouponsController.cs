using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Models;
using System.Security.Claims;
using Talabi.Core.DTOs;

namespace Talabi.Api.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CouponsController(IUnitOfWork unitOfWork, IRuleValidatorService ruleValidator) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Coupon>>> GetCoupons()
    {
        return await unitOfWork.Coupons.Query()
            .Where(c => c.IsActive && c.ExpirationDate > DateTime.UtcNow)
            .OrderBy(c => c.ExpirationDate)
            .ToListAsync();
    }

    [HttpPost("validate")]
    public async Task<ActionResult<Coupon>> ValidateCoupon([FromBody] ValidateCouponRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Code))
        {
            return BadRequest(new { message = "Kupon kodu boş olamaz." });
        }

        var coupon = await unitOfWork.Coupons.Query()
            .Include(c => c.CouponCities)
            .Include(c => c.CouponDistricts)
            .Include(c => c.CouponCategories)
            .Include(c => c.CouponProducts)
            .FirstOrDefaultAsync(c => c.Code == request.Code);

        if (coupon == null)
        {
            return NotFound(new { message = "Geçersiz kupon kodu." });
        }

        // Build Context
        var context = new RuleValidationContext
        {
            RequestTime = DateTime.UtcNow,
            CityId = request.CityId,
            DistrictId = request.DistrictId
        };
        
        // Get User ID from Claims if available
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userIdString != null)
        {
            if(Guid.TryParse(userIdString, out var userId))
            {
                context.UserId = userId;
                context.IsFirstOrder = !await unitOfWork.Orders.Query().AnyAsync(o => o.CustomerId == userIdString);
            }

            // Fetch Cart using string ID
            var cart = await unitOfWork.Carts.Query()
                .Include(c => c.CartItems)
                .ThenInclude(ci => ci.Product)
                .FirstOrDefaultAsync(c => c.UserId == userIdString);
                
            if (cart != null)
            {
                context.Items = cart.CartItems.Select(ci => new RuleValidationContext.RuleCartItem
                {
                    ProductId = ci.ProductId,
                    VendorId = ci.Product?.VendorId ?? Guid.Empty, 
                    VendorType = (int)(ci.Product?.VendorType ?? Core.Enums.VendorType.Restaurant),
                    Price = ci.Product?.Price ?? 0,
                    Quantity = ci.Quantity,
                    CategoryId = ci.Product?.CategoryId 
                }).ToList();
                
                context.CartTotal = context.Items.Sum(i => i.Price * i.Quantity);
            }
        }

        if (!ruleValidator.ValidateCoupon(coupon, context, out var failureReason))
        {
             return BadRequest(new { message = failureReason });
        }

        return coupon;
    }
}
