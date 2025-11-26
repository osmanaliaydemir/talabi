using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Infrastructure.ScaffoldedModels;

public partial class Vendor
{
    [Key]
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string? ImageUrl { get; set; }

    public string Address { get; set; } = null!;

    [StringLength(450)]
    public string OwnerId { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public string? City { get; set; }

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    [Column(TypeName = "decimal(18, 2)")]
    public decimal? Rating { get; set; }

    public int RatingCount { get; set; }

    [InverseProperty("Vendor")]
    public virtual ICollection<Order> Orders { get; set; } = new List<Order>();

    [ForeignKey("OwnerId")]
    [InverseProperty("Vendors")]
    public virtual AspNetUser Owner { get; set; } = null!;

    [InverseProperty("Vendor")]
    public virtual ICollection<Product> Products { get; set; } = new List<Product>();

    [InverseProperty("Vendor")]
    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();
}
