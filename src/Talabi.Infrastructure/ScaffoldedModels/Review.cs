using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Infrastructure.ScaffoldedModels;

[Index("ProductId", Name = "IX_Reviews_ProductId")]
[Index("UserId", Name = "IX_Reviews_UserId")]
[Index("VendorId", Name = "IX_Reviews_VendorId")]
public partial class Review
{
    [Key]
    public int Id { get; set; }

    public string UserId { get; set; } = null!;

    public int? ProductId { get; set; }

    public int? VendorId { get; set; }

    public int Rating { get; set; }

    public string Comment { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public bool IsApproved { get; set; }

    [ForeignKey("ProductId")]
    [InverseProperty("Reviews")]
    public virtual Product? Product { get; set; }

    [ForeignKey("UserId")]
    [InverseProperty("Reviews")]
    public virtual AspNetUser User { get; set; } = null!;

    [ForeignKey("VendorId")]
    [InverseProperty("Reviews")]
    public virtual Vendor? Vendor { get; set; }
}
