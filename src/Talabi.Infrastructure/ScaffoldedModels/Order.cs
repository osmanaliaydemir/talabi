using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Infrastructure.ScaffoldedModels;

public partial class Order
{
    [Key]
    public int Id { get; set; }

    [StringLength(450)]
    public string CustomerId { get; set; } = null!;

    public int VendorId { get; set; }

    [Column(TypeName = "decimal(18, 2)")]
    public decimal TotalAmount { get; set; }

    public int Status { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public string? CancelReason { get; set; }

    public DateTime? CancelledAt { get; set; }

    public int? CourierId { get; set; }

    public DateTime? DeliveredAt { get; set; }

    public int? DeliveryAddressId { get; set; }

    public DateTime? EstimatedDeliveryTime { get; set; }

    [ForeignKey("CourierId")]
    [InverseProperty("Orders")]
    public virtual Courier? Courier { get; set; }

    [ForeignKey("CustomerId")]
    [InverseProperty("Orders")]
    public virtual AspNetUser Customer { get; set; } = null!;

    [ForeignKey("DeliveryAddressId")]
    [InverseProperty("Orders")]
    public virtual UserAddress? DeliveryAddress { get; set; }

    [InverseProperty("Order")]
    public virtual ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();

    [InverseProperty("Order")]
    public virtual ICollection<OrderStatusHistory> OrderStatusHistories { get; set; } = new List<OrderStatusHistory>();

    [ForeignKey("VendorId")]
    [InverseProperty("Orders")]
    public virtual Vendor Vendor { get; set; } = null!;
}
