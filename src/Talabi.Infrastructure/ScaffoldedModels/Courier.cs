using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Infrastructure.ScaffoldedModels;

public partial class Courier
{
    [Key]
    public int Id { get; set; }

    [StringLength(450)]
    public string UserId { get; set; } = null!;

    public string Name { get; set; } = null!;

    public string? PhoneNumber { get; set; }

    public string? VehicleType { get; set; }

    public bool IsActive { get; set; }

    public double? CurrentLatitude { get; set; }

    public double? CurrentLongitude { get; set; }

    public DateTime? LastLocationUpdate { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    [InverseProperty("Courier")]
    public virtual ICollection<Order> Orders { get; set; } = new List<Order>();

    [ForeignKey("UserId")]
    [InverseProperty("Couriers")]
    public virtual AspNetUser User { get; set; } = null!;
}
