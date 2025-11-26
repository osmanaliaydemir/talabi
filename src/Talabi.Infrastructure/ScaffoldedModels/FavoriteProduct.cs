using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Infrastructure.ScaffoldedModels;

public partial class FavoriteProduct
{
    [Key]
    public int Id { get; set; }

    [StringLength(450)]
    public string UserId { get; set; } = null!;

    public int ProductId { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    [ForeignKey("ProductId")]
    [InverseProperty("FavoriteProducts")]
    public virtual Product Product { get; set; } = null!;

    [ForeignKey("UserId")]
    [InverseProperty("FavoriteProducts")]
    public virtual AspNetUser User { get; set; } = null!;
}
