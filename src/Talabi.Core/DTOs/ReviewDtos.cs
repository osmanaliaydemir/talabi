using System;

namespace Talabi.Core.DTOs;

public class CreateReviewDto
{
    public Guid TargetId { get; set; }
    public string TargetType { get; set; } = "Product"; // "Product" or "Vendor"
    public int Rating { get; set; }

    [System.ComponentModel.DataAnnotations.StringLength(500, MinimumLength = 10)]
    public string Comment { get; set; } = string.Empty;
}

public class ReviewDto
{
    public Guid Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string UserFullName { get; set; } = string.Empty;
    public int Rating { get; set; }

    [System.ComponentModel.DataAnnotations.StringLength(500, MinimumLength = 10)]
    public string Comment { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }
    public bool IsApproved { get; set; }
    public Guid? ProductId { get; set; }
    public Guid? VendorId { get; set; }
    public Guid? CourierId { get; set; }
    public string? VendorName { get; set; }
    public string? Reply { get; set; }
    public DateTime? RepliedAt { get; set; }
}

public class ProductReviewsSummaryDto
{
    public double AverageRating { get; set; }
    public int TotalRatings { get; set; }
    public int TotalComments { get; set; }
    public List<ReviewDto> Reviews { get; set; } = new List<ReviewDto>();
}

public class SubmitOrderFeedbackDto
{
    public Guid OrderId { get; set; }
    public int CourierRating { get; set; } // 1-5

    [System.ComponentModel.DataAnnotations.StringLength(500, MinimumLength = 10)]
    public string? CourierComment { get; set; }

    public VendorFeedbackDto VendorFeedback { get; set; } = new();
    public List<ProductFeedbackDto> ProductFeedbacks { get; set; } = new();
}

public class VendorFeedbackDto
{
    public int Rating { get; set; }

    [System.ComponentModel.DataAnnotations.StringLength(500, MinimumLength = 10)]
    public string? Comment { get; set; }
}

public class ProductFeedbackDto
{
    public Guid ProductId { get; set; }
    public int Rating { get; set; }

    [System.ComponentModel.DataAnnotations.StringLength(500, MinimumLength = 10)]
    public string? Comment { get; set; }
}

public class OrderReviewStatusDto
{
    public bool IsCourierRated { get; set; }
    public bool HasCourier { get; set; }
    public bool IsVendorReviewed { get; set; }
    public List<Guid> ReviewedProductIds { get; set; } = new();
    public List<ReviewDto> Reviews { get; set; } = new();
}
