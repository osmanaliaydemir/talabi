using System.ComponentModel.DataAnnotations;

namespace Getir.MerchantPortal.Models;

/// <summary>
/// Review Response Model
/// </summary>
public class ReviewResponse
{
    public Guid Id { get; set; }
    public Guid ReviewerId { get; set; }
    public string ReviewerName { get; set; } = string.Empty;
    public Guid RevieweeId { get; set; }
    public string RevieweeName { get; set; } = string.Empty;
    public string RevieweeType { get; set; } = string.Empty; // "Merchant" or "Courier"
    public Guid OrderId { get; set; }
    public int Rating { get; set; }
    public string Comment { get; set; } = string.Empty;
    public List<string> Tags { get; set; } = new();
    public int LikeCount { get; set; }
    public int ReportCount { get; set; }
    public bool IsLiked { get; set; }
    public bool IsReported { get; set; }
    public string? Response { get; set; }
    public DateTime? RespondedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

/// <summary>
/// Review Statistics Response Model
/// </summary>
public class ReviewStatsResponse
{
    public Guid EntityId { get; set; }
    public string EntityType { get; set; } = string.Empty;
    public int TotalReviews { get; set; }
    public double AverageRating { get; set; }
    public Dictionary<int, int> RatingDistribution { get; set; } = new();
    public List<TagFrequencyResponse> TopTags { get; set; } = new();
    public DateTime GeneratedAt { get; set; }
}

/// <summary>
/// Tag Frequency Response Model
/// </summary>
public class TagFrequencyResponse
{
    public string Tag { get; set; } = string.Empty;
    public int Count { get; set; }
    public double Percentage { get; set; }
}

/// <summary>
/// Review Filter Model
/// </summary>
public class ReviewFilterModel
{
    public int? Rating { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? SearchTerm { get; set; }
    public string? RevieweeType { get; set; } // "Merchant" or "Courier"
}

/// <summary>
/// Review Dashboard Model
/// </summary>
public class ReviewDashboardModel
{
    public ReviewStatsResponse? MerchantStats { get; set; }
    public ReviewStatsResponse? CourierStats { get; set; }
    public DateTime GeneratedAt { get; set; }
}

/// <summary>
/// Courier Response Model (for getting couriers)
/// </summary>
public class CourierResponse
{
    public Guid Id { get; set; }
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string FullName => $"{FirstName} {LastName}";
    public string PhoneNumber { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}

/// <summary>
/// Review List Item Model (for display)
/// </summary>
public class ReviewListItemModel
{
    public Guid Id { get; set; }
    public string ReviewerName { get; set; } = string.Empty;
    public string RevieweeName { get; set; } = string.Empty;
    public string RevieweeType { get; set; } = string.Empty;
    public int Rating { get; set; }
    public string Comment { get; set; } = string.Empty;
    public List<string> Tags { get; set; } = new();
    public int LikeCount { get; set; }
    public bool IsLiked { get; set; }
    public string? Response { get; set; }
    public DateTime CreatedAt { get; set; }
    public string TimeAgo => GetTimeAgo(CreatedAt);

    private string GetTimeAgo(DateTime dateTime)
    {
        var timeSpan = DateTime.Now - dateTime;
        
        if (timeSpan.TotalDays >= 1)
            return $"{(int)timeSpan.TotalDays} gün önce";
        if (timeSpan.TotalHours >= 1)
            return $"{(int)timeSpan.TotalHours} saat önce";
        if (timeSpan.TotalMinutes >= 1)
            return $"{(int)timeSpan.TotalMinutes} dakika önce";
        
        return "Az önce";
    }
}

/// <summary>
/// Review Response Request Model
/// </summary>
public class ReviewResponseRequest
{
    [Required(ErrorMessage = "Yanıt metni gereklidir")]
    [StringLength(1000, ErrorMessage = "Yanıt metni en fazla 1000 karakter olabilir")]
    public string Response { get; set; } = string.Empty;
}

/// <summary>
/// Review Report Request Model
/// </summary>
public class ReviewReportRequest
{
    [Required(ErrorMessage = "Rapor nedeni gereklidir")]
    [StringLength(500, ErrorMessage = "Rapor nedeni en fazla 500 karakter olabilir")]
    public string Reason { get; set; } = string.Empty;
}
