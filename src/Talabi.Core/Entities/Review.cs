using System;

namespace Talabi.Core.Entities;

public class Review : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public AppUser? User { get; set; }

    public Guid? ProductId { get; set; }
    public Product? Product { get; set; }

    public Guid? VendorId { get; set; }
    public Vendor? Vendor { get; set; }

    public int Rating { get; set; }
    public string Comment { get; set; } = string.Empty;
    public bool IsApproved { get; set; } = false;

    public Guid? CourierId { get; set; }
    public Courier? Courier { get; set; }

    public Guid? OrderId { get; set; }
    public Order? Order { get; set; }

    public string? Reply { get; set; }
    public DateTime? RepliedAt { get; set; }
}
