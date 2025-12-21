using Talabi.Core.Entities;

namespace Talabi.Core.Models;

public class RuleValidationContext
{
    public Guid? UserId { get; set; }
    public bool IsFirstOrder { get; set; } = false;
    
    // Location
    public Guid? CityId { get; set; }
    public Guid? DistrictId { get; set; }
    
    // Time override (defaults to UtcNow if null)
    public DateTime RequestTime { get; set; } = DateTime.UtcNow;

    // Cart Context
    public decimal CartTotal { get; set; }
    public List<RuleCartItem> Items { get; set; } = new();

    public class RuleCartItem
    {
        public Guid ProductId { get; set; }
        public Guid? CategoryId { get; set; }
        public Guid VendorId { get; set; }
        public decimal Price { get; set; }
        public int Quantity { get; set; }
        public int VendorType { get; set; } // 1: Restaurant, 2: Market
    }
}
