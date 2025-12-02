using System;

namespace Talabi.Core.DTOs;

public class CreateReviewDto
{
    public Guid TargetId { get; set; }
    public string TargetType { get; set; } = "Product"; // "Product" or "Vendor"
    public int Rating { get; set; }
    public string Comment { get; set; } = string.Empty;
}

public class ReviewDto
{
    public Guid Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string UserFullName { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string Comment { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public bool IsApproved { get; set; }
}
