using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Infrastructure.ScaffoldedModels;

public partial class UserPreference
{
    [Key]
    public int Id { get; set; }

    [StringLength(450)]
    public string UserId { get; set; } = null!;

    public string Language { get; set; } = null!;

    public string Currency { get; set; } = null!;

    public string? TimeZone { get; set; }

    public string? DateFormat { get; set; }

    public string? TimeFormat { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    [ForeignKey("UserId")]
    [InverseProperty("UserPreferences")]
    public virtual AspNetUser User { get; set; } = null!;
}
