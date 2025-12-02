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
}
