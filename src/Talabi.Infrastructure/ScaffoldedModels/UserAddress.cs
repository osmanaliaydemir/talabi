using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Infrastructure.ScaffoldedModels;

public partial class UserAddress
{
    [Key]
    public int Id { get; set; }

    [StringLength(450)]
    public string UserId { get; set; } = null!;

    public string Title { get; set; } = null!;

    public string FullAddress { get; set; } = null!;

    public string City { get; set; } = null!;

    public string District { get; set; } = null!;

    public string? PostalCode { get; set; }

    public bool IsDefault { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }

    [InverseProperty("DeliveryAddress")]
    public virtual ICollection<Order> Orders { get; set; } = new List<Order>();

    [ForeignKey("UserId")]
    [InverseProperty("UserAddresses")]
    public virtual AspNetUser User { get; set; } = null!;
}
