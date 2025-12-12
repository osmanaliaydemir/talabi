using System.ComponentModel.DataAnnotations;

namespace Getir.MerchantPortal.Models;

// API Response Models
public class ApiResponse<T>
{
    public bool isSuccess { get; set; }
    public T? Data { get; set; }
    public string? Error { get; set; }
}

public class PagedResult<T>
{
    public List<T> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
}

// Auth Models
public class LoginRequest
{
    public string Email { get; set; } = default!;
    public string Password { get; set; } = default!;
}

public class LoginResponse
{
    // API'den gelen property isimleri (camelCase)
    public string AccessToken { get; set; } = default!;
    public string RefreshToken { get; set; } = default!;
    public DateTime ExpiresAt { get; set; }
    public int Role { get; set; }
    public Guid UserId { get; set; }
    public string Email { get; set; } = default!;
    public string FullName { get; set; } = default!;
    public Guid? MerchantId { get; set; } 
    
    // Backward compatibility
    public string Token => AccessToken;
    public UserInfo User => new UserInfo 
    { 
        Id = UserId, 
        Email = Email, 
        FullName = FullName, 
        Role = ((UserRole)Role).ToString() 
    };
}

public enum UserRole
{
    Customer = 1,
    Courier = 2,
    MerchantOwner = 3,
    Admin = 4
}

public class UserInfo
{
    public Guid Id { get; set; }
    public string Email { get; set; } = default!;
    public string FullName { get; set; } = default!;
    public string PhoneNumber { get; set; } = default!;
    public string Role { get; set; } = default!;
}

// Merchant Models
public class MerchantResponse
{
    public Guid Id { get; set; }
    public Guid OwnerId { get; set; }
    public string OwnerName { get; set; } = default!;
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public Guid ServiceCategoryId { get; set; }
    public string ServiceCategoryName { get; set; } = default!;
    public string? LogoUrl { get; set; }
    public string? CoverImageUrl { get; set; }
    public string Address { get; set; } = default!;
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public string PhoneNumber { get; set; } = default!;
    public string? Email { get; set; }
    public decimal MinimumOrderAmount { get; set; }
    public decimal DeliveryFee { get; set; }
    public int AverageDeliveryTime { get; set; }
    public decimal? Rating { get; set; }
    public int TotalReviews { get; set; }
    public bool IsActive { get; set; }
    public bool IsBusy { get; set; }
    public bool IsOpen { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class UpdateMerchantRequest
{
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public string Address { get; set; } = default!;
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public string PhoneNumber { get; set; } = default!;
    public string? Email { get; set; }
    public decimal MinimumOrderAmount { get; set; }
    public decimal DeliveryFee { get; set; }
    public int AverageDeliveryTime { get; set; }
    public bool IsActive { get; set; }
    public bool IsBusy { get; set; }
    public string? LogoUrl { get; set; }
    public string? CoverImageUrl { get; set; }
}

public class CreateMerchantRequest
{
    [Required]
    public string Name { get; set; } = default!;

    public string? Description { get; set; }

    [Required]
    public Guid ServiceCategoryId { get; set; }

    [Required]
    public string Address { get; set; } = default!;

    [Range(-90, 90)]
    public decimal Latitude { get; set; }

    [Range(-180, 180)]
    public decimal Longitude { get; set; }

    [Required]
    [Phone]
    public string PhoneNumber { get; set; } = default!;

    [EmailAddress]
    public string? Email { get; set; }

    [Range(0, double.MaxValue)]
    public decimal MinimumOrderAmount { get; set; }

    [Range(0, double.MaxValue)]
    public decimal DeliveryFee { get; set; }
}

public class ServiceCategoryResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public string Type { get; set; } = default!;
    public string? ImageUrl { get; set; }
    public string? IconUrl { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
    public int MerchantCount { get; set; }
}

// Working Hours Models
public class WorkingHoursResponse
{
    public Guid Id { get; set; }
    public Guid MerchantId { get; set; }
    public string DayOfWeek { get; set; } = default!;
    public TimeSpan OpenTime { get; set; }
    public TimeSpan CloseTime { get; set; }
    public bool IsClosed { get; set; }
    public bool IsOpen24Hours { get; set; }
}

public class UpdateWorkingHoursRequest
{
    public string DayOfWeek { get; set; } = default!;
    public string OpenTime { get; set; } = default!; // "09:00"
    public string CloseTime { get; set; } = default!; // "18:00"
    public bool IsClosed { get; set; }
    public bool IsOpen24Hours { get; set; }
}

public class MerchantSettingsViewModel
{
    public MerchantResponse Merchant { get; set; } = default!;
    public List<WorkingHoursResponse> WorkingHours { get; set; } = new();
}

// Dashboard Models
public class MerchantDashboardResponse
{
    public MerchantDashboardStats Stats { get; set; } = new();
    public List<RecentOrderResponse> RecentOrders { get; set; } = new();
    public List<TopProductResponse> TopProducts { get; set; } = new();
    public MerchantPerformanceMetrics Performance { get; set; } = new();
}

public class MerchantDashboardStats
{
    public int TotalOrders { get; set; }
    public int TodayOrders { get; set; }
    public decimal TodayRevenue { get; set; }
    public decimal TotalRevenue { get; set; }
    public int ActiveProducts { get; set; }
    public int TotalProducts { get; set; }
    public decimal AverageRating { get; set; }
    public int TotalReviews { get; set; }
    public bool IsOpen { get; set; }
    public int PendingOrders { get; set; }
}

public class MerchantPerformanceMetrics
{
    public decimal AverageOrderValue { get; set; }
    public int OrdersPerDay { get; set; }
    public decimal CompletionRate { get; set; }
    public int AveragePreparationTime { get; set; }
    public decimal CustomerSatisfactionScore { get; set; }
}

public class RecentOrderResponse
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = default!;
    public string CustomerName { get; set; } = default!;
    public decimal Total { get; set; }
    public string Status { get; set; } = default!;
    public DateTime CreatedAt { get; set; }

    public decimal TotalAmount
    {
        get => Total;
        set => Total = value;
    }
}

public class TopProductResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public int QuantitySold { get; set; }
    public decimal Revenue { get; set; }
    public string? ImageUrl { get; set; }

    public int OrderCount
    {
        get => QuantitySold;
        set => QuantitySold = value;
    }

    public decimal TotalRevenue
    {
        get => Revenue;
        set => Revenue = value;
    }
}

// Product Models
public class ProductResponse
{
    public Guid Id { get; set; }
    public Guid MerchantId { get; set; }
    public Guid? ProductCategoryId { get; set; }
    public string? CategoryName { get; set; }
    public string Name { get; set; } = default!;
    public string SKU { get; set; } = default!;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public decimal Price { get; set; }
    public decimal? DiscountedPrice { get; set; }
    public int StockQuantity { get; set; }
    public int? MinStock { get; set; }
    public int? MaxStock { get; set; }
    public string? Unit { get; set; }
    public bool IsAvailable { get; set; }
    public bool IsActive { get; set; }
    public int DisplayOrder { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class CreateProductRequest
{
    public Guid? ProductCategoryId { get; set; }
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public decimal Price { get; set; }
    public decimal? DiscountedPrice { get; set; }
    public int StockQuantity { get; set; }
    public string? Unit { get; set; }
    public bool IsAvailable { get; set; } = true;
    public bool IsActive { get; set; } = true;
    public int DisplayOrder { get; set; }
}

public class UpdateProductRequest
{
    public Guid? ProductCategoryId { get; set; }
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public decimal Price { get; set; }
    public decimal? DiscountedPrice { get; set; }
    public int StockQuantity { get; set; }
    public string? Unit { get; set; }
    public bool IsAvailable { get; set; }
    public bool IsActive { get; set; }
    public int DisplayOrder { get; set; }
}

// Category Models
public class ProductCategoryResponse
{
    public Guid Id { get; set; }
    public Guid? MerchantId { get; set; }
    public Guid? ParentCategoryId { get; set; }
    public string? ParentCategoryName { get; set; }
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
    public int ProductCount { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CategoryTreeNode
{
    public ProductCategoryResponse Category { get; set; } = default!;
    public List<CategoryTreeNode> Children { get; set; } = new();
    public int Level => GetLevel(this, 0);
    
    private int GetLevel(CategoryTreeNode node, int currentLevel)
    {
        if (node.Category.ParentCategoryId == null)
            return currentLevel;
        return currentLevel;
    }
}

public class CreateCategoryRequest
{
    public Guid? ParentCategoryId { get; set; }
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateCategoryRequest
{
    public Guid? ParentCategoryId { get; set; }
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public string? ImageUrl { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
}

// Order Models
public class OrderResponse
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = default!;
    public Guid UserId { get; set; }
    public string CustomerName { get; set; } = default!;
    public string CustomerPhone { get; set; } = default!;
    public Guid MerchantId { get; set; }
    public string Status { get; set; } = default!;
    public decimal SubTotal { get; set; }
    public decimal DeliveryFee { get; set; }
    public decimal TotalAmount { get; set; }
    public string DeliveryAddress { get; set; } = default!;
    public string? Notes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public class OrderDetailsResponse : OrderResponse
{
    public List<OrderLineResponse> OrderLines { get; set; } = new();
}

public class OrderLineResponse
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public string? ProductImageUrl { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
}

public class UpdateOrderStatusRequest
{
    public string Status { get; set; } = default!;
    public string? Notes { get; set; }
}

// Notification Preferences Models
public class MerchantNotificationPreferencesDto
{
    public bool SoundEnabled { get; set; }
    public bool DesktopNotifications { get; set; }
    public bool EmailNotifications { get; set; }
    public bool NewOrderNotifications { get; set; }
    public bool StatusChangeNotifications { get; set; }
    public bool CancellationNotifications { get; set; }
    public bool DoNotDisturbEnabled { get; set; }
    public string? DoNotDisturbStart { get; set; }
    public string? DoNotDisturbEnd { get; set; }
    public string NotificationSound { get; set; } = "default";
}

public class UpdateNotificationPreferencesDto
{
    public bool SoundEnabled { get; set; }
    public bool DesktopNotifications { get; set; }
    public bool EmailNotifications { get; set; }
    public bool NewOrderNotifications { get; set; }
    public bool StatusChangeNotifications { get; set; }
    public bool CancellationNotifications { get; set; }
    public bool DoNotDisturbEnabled { get; set; }
    public string? DoNotDisturbStart { get; set; }
    public string? DoNotDisturbEnd { get; set; }
    public string NotificationSound { get; set; } = "default";
}

// Payment Models
public class PaymentResponse
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public string OrderNumber { get; set; } = default!;
    public string PaymentMethod { get; set; } = default!;
    public string Status { get; set; } = default!;
    public decimal Amount { get; set; }
    public decimal? ChangeAmount { get; set; }
    public DateTime? ProcessedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? CollectedAt { get; set; }
    public DateTime? SettledAt { get; set; }
    public Guid? CollectedByCourierId { get; set; }
    public string? CollectedByCourierName { get; set; }
    public string? Notes { get; set; }
    public string? FailureReason { get; set; }
    public string? RefundReason { get; set; }
    public decimal? RefundAmount { get; set; }
    public DateTime? RefundedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreatePaymentRequest
{
    [Required]
    public Guid OrderId { get; set; }

    [Required]
    public string PaymentMethod { get; set; } = default!;

    [Range(0, double.MaxValue)]
    public decimal Amount { get; set; }

    public decimal? ChangeAmount { get; set; }
    public string? Notes { get; set; }
}

public class CollectCashPaymentRequest
{
    [Range(0, double.MaxValue)]
    public decimal CollectedAmount { get; set; }
    public string? Notes { get; set; }
}

public class ProcessSettlementRequest
{
    [Range(0, 1, ErrorMessage = "Komisyon oranı 0 ile 1 arasında olmalıdır.")]
    public decimal CommissionRate { get; set; }
    public string? Notes { get; set; }
    public string? BankTransferReference { get; set; }
}

public class CourierCashSummaryResponse
{
    public Guid CourierId { get; set; }
    public string CourierName { get; set; } = default!;
    public DateTime Date { get; set; }
    public decimal TotalCollected { get; set; }
    public int TotalOrders { get; set; }
    public int SuccessfulCollections { get; set; }
    public int FailedCollections { get; set; }
    public List<PaymentResponse> Collections { get; set; } = new();
}

public class FailPaymentRequest
{
    [Required]
    public string Reason { get; set; } = default!;
}

// Notification Models
public class NotificationResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = default!;
    public string Message { get; set; } = default!;
    public string Type { get; set; } = default!;
    public Guid? RelatedEntityId { get; set; }
    public string? RelatedEntityType { get; set; }
    public bool IsRead { get; set; }
    public string? ImageUrl { get; set; }
    public string? ActionUrl { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UpdateNotificationPreferencesRequest
{
    public bool EmailEnabled { get; set; }
    public bool SmsEnabled { get; set; }
    public bool PushEnabled { get; set; }
}

public class NotificationPreferencesResponse
{
    public bool EmailEnabled { get; set; }
    public bool SmsEnabled { get; set; }
    public bool PushEnabled { get; set; }
}

// Special Holiday Models
public class SpecialHolidayResponse
{
    public Guid Id { get; set; }
    public Guid MerchantId { get; set; }
    public string Title { get; set; } = default!;
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsClosed { get; set; }
    public TimeSpan? SpecialOpenTime { get; set; }
    public TimeSpan? SpecialCloseTime { get; set; }
    public bool IsRecurring { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class CreateSpecialHolidayRequest
{
    public Guid MerchantId { get; set; }
    public string Title { get; set; } = default!;
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsClosed { get; set; }
    public TimeSpan? SpecialOpenTime { get; set; }
    public TimeSpan? SpecialCloseTime { get; set; }
    public bool IsRecurring { get; set; }
}

public class UpdateSpecialHolidayRequest
{
    public string Title { get; set; } = default!;
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsClosed { get; set; }
    public TimeSpan? SpecialOpenTime { get; set; }
    public TimeSpan? SpecialCloseTime { get; set; }
    public bool IsRecurring { get; set; }
    public bool IsActive { get; set; }
}

public class MerchantAvailabilityResponse
{
    public bool IsOpen { get; set; }
    public string Status { get; set; } = default!;
    public SpecialHolidayResponse? SpecialHoliday { get; set; }
    public string? Message { get; set; }
}

public class MerchantCashSummaryResponse
{
    public Guid MerchantId { get; set; }
    public string MerchantName { get; set; } = default!;
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal TotalCommission { get; set; }
    public decimal NetAmount { get; set; }
    public int TotalOrders { get; set; }
    public List<PaymentResponse> Payments { get; set; } = new();
}

public class SettlementResponse
{
    public Guid Id { get; set; }
    public Guid MerchantId { get; set; }
    public string MerchantName { get; set; } = default!;
    public decimal TotalAmount { get; set; }
    public decimal Commission { get; set; }
    public decimal NetAmount { get; set; }
    public DateTime SettlementDate { get; set; }
    public string Status { get; set; } = default!;
    public string? Notes { get; set; }
    public string? ProcessedByAdminName { get; set; }
    public DateTime? CompletedAt { get; set; }
    public string? BankTransferReference { get; set; }
    public DateTime CreatedAt { get; set; }
}

// Report Models
public class SalesDashboardModel
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal TotalRevenue { get; set; }
    public int TotalOrders { get; set; }
    public int CompletedOrders { get; set; }
    public decimal AverageOrderValue { get; set; }
    public decimal RevenueGrowth { get; set; }
    public decimal OrderGrowth { get; set; }
    public List<ProductPerformanceItem> TopProducts { get; set; } = new();
    public List<DailyData> RevenueByDay { get; set; } = new();
    public List<DailyData> OrdersByDay { get; set; } = new();
    public List<BreakdownItem> PaymentMethodBreakdown { get; set; } = new();
    public List<BreakdownItem> CategoryBreakdown { get; set; } = new();
}

public class RevenueAnalyticsModel
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal TotalRevenue { get; set; }
    public List<DailyData> DailyRevenue { get; set; } = new();
    public List<WeeklyData> WeeklyRevenue { get; set; } = new();
    public List<MonthlyData> MonthlyRevenue { get; set; } = new();
    public decimal RevenueTrend { get; set; }
    public List<BreakdownItem> PaymentMethodDistribution { get; set; } = new();
    public List<HourlyData> RevenueByHour { get; set; } = new();
    public List<DailyData> TopRevenueDays { get; set; } = new();
}

public class CustomerAnalyticsModel
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int TotalCustomers { get; set; }
    public int NewCustomers { get; set; }
    public int ReturningCustomers { get; set; }
    public decimal CustomerRetentionRate { get; set; }
    public decimal AverageOrderFrequency { get; set; }
    public decimal CustomerLifetimeValue { get; set; }
    public List<CustomerItem> TopCustomers { get; set; } = new();
    public List<CustomerSegment> CustomerSegments { get; set; } = new();
    public List<CustomerGrowthData> CustomerGrowth { get; set; } = new();
    public List<CustomerLTVData> CustomerLTV { get; set; } = new();
}

public class ProductPerformanceModel
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int TotalProducts { get; set; }
    public decimal TotalSales { get; set; }
    public decimal AverageOrderValue { get; set; }
    public decimal SalesGrowth { get; set; }
    public List<ProductPerformanceItem> TopProducts { get; set; } = new();
    public List<ProductPerformanceItem> LowPerformanceProducts { get; set; } = new();
    public List<SalesByDayData> SalesByDay { get; set; } = new();
    public List<BreakdownItem> CategoryBreakdown { get; set; } = new();
    public List<ProductPerformanceItem> LowStockProducts { get; set; } = new();
    public List<ProductPerformanceItem> OutOfStockProducts { get; set; } = new();
    public List<ProductPerformanceItem> BestSellers { get; set; } = new();
    public List<ProductPerformanceItem> LowPerformers { get; set; } = new();
    public List<CategoryPerformance> CategoryPerformance { get; set; } = new();
    public List<ProductTrend> ProductTrends { get; set; } = new();
    public List<InventoryTurnover> InventoryTurnover { get; set; } = new();
    public List<ProfitMargin> ProfitMargins { get; set; } = new();
}

public class ChartDataModel
{
    public string ChartType { get; set; } = default!;
    public List<object> Data { get; set; } = new();
    public List<string> Labels { get; set; } = new();
    public List<string> Colors { get; set; } = new();
}

public class ReportExportRequest
{
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string ReportType { get; set; } = default!;
    public string Format { get; set; } = "excel";
}

// Supporting Models
public class DailyData
{
    public DateTime Date { get; set; }
    public decimal Value { get; set; }
    public int Count { get; set; }
}

public class WeeklyData
{
    public int Week { get; set; }
    public int Year { get; set; }
    public decimal Value { get; set; }
    public int Count { get; set; }
}

public class MonthlyData
{
    public int Month { get; set; }
    public int Year { get; set; }
    public decimal Value { get; set; }
    public int Count { get; set; }
}

public class HourlyData
{
    public int Hour { get; set; }
    public decimal Value { get; set; }
    public int Count { get; set; }
}

public class BreakdownItem
{
    public string Label { get; set; } = default!;
    public decimal Value { get; set; }
    public decimal Percentage { get; set; }
    public string Color { get; set; } = default!;
}

public class ProductPerformanceItem
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public string Name { get; set; } = default!;
    public string Category { get; set; } = default!;
    public string? ImageUrl { get; set; }
    public int QuantitySold { get; set; }
    public int SalesCount { get; set; }
    public decimal Revenue { get; set; }
    public decimal Profit { get; set; }
    public decimal ProfitMargin { get; set; }
}

public class CustomerItem
{
    public Guid CustomerId { get; set; }
    public string CustomerName { get; set; } = default!;
    public int OrderCount { get; set; }
    public decimal TotalSpent { get; set; }
    public DateTime LastOrderDate { get; set; }
}

public class CustomerSegment
{
    public string SegmentName { get; set; } = default!;
    public string Segment { get; set; } = default!;
    public int CustomerCount { get; set; }
    public int Count { get; set; }
    public decimal AverageValue { get; set; }
    public string Color { get; set; } = default!;
}

public class CategoryPerformance
{
    public Guid CategoryId { get; set; }
    public string CategoryName { get; set; } = default!;
    public int ProductCount { get; set; }
    public int OrderCount { get; set; }
    public decimal Revenue { get; set; }
    public decimal Percentage { get; set; }
}

public class ProductTrend
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public decimal TrendValue { get; set; }
    public string TrendDirection { get; set; } = default!;
}

public class InventoryTurnover
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public decimal TurnoverRate { get; set; }
    public int DaysInInventory { get; set; }
}

public class ProfitMargin
{
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public decimal Cost { get; set; }
    public decimal Price { get; set; }
    public decimal Margin { get; set; }
    public decimal MarginPercentage { get; set; }
}

public class ReportDataItem
{
    public string ReportType { get; set; } = default!;
    public DateTime Date { get; set; }
    public decimal Value { get; set; }
    public string Details { get; set; } = default!;
}

public class PaymentStatisticsResponse
{
    public decimal TodayRevenue { get; set; }
    public decimal WeekRevenue { get; set; }
    public decimal MonthRevenue { get; set; }
    public int TodayPayments { get; set; }
    public int WeekPayments { get; set; }
    public int MonthPayments { get; set; }
    public Dictionary<string, decimal> PaymentMethodBreakdown { get; set; } = new();
    public decimal PendingSettlement { get; set; }
    public decimal TotalCommission { get; set; }
}

// Stock Management Models
public class StockAlertResponse
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public Guid? ProductVariantId { get; set; }
    public string ProductName { get; set; } = default!;
    public string? VariantName { get; set; }
    public int CurrentStock { get; set; }
    public int MinimumStock { get; set; }
    public int MaximumStock { get; set; }
    public string AlertType { get; set; } = default!; // LowStock, OutOfStock, Overstock
    public string Message { get; set; } = default!;
    public DateTime CreatedAt { get; set; }
    public bool IsResolved { get; set; }
    public DateTime? ResolvedAt { get; set; }
}

public class StockHistoryResponse
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public int PreviousQuantity { get; set; }
    public int NewQuantity { get; set; }
    public int ChangeAmount { get; set; }
    public string ChangeType { get; set; } = default!; // OrderReduction, ManualAdjustment, etc.
    public string? Reason { get; set; }
    public string? Notes { get; set; }
    public string? ChangedByName { get; set; }
    public DateTime ChangedAt { get; set; }
    public string? OrderNumber { get; set; }
}

public class UpdateStockRequest
{
    public Guid ProductId { get; set; }
    public Guid? ProductVariantId { get; set; }
    public int NewStockQuantity { get; set; }
    public string? Reason { get; set; }
    public string? Notes { get; set; }
}

public class BulkUpdateStockRequest
{
    public List<UpdateStockRequest> StockUpdates { get; set; } = new();
    public string? Reason { get; set; }
}

public class StockSummaryResponse
{
    public int TotalProducts { get; set; }
    public int LowStockItems { get; set; }
    public int OutOfStockItems { get; set; }
    public int OverstockItems { get; set; }
    public int ActiveAlerts { get; set; }
    public decimal TotalValue { get; set; }
}

// Stock Report Models (client-side equivalents for WebApi responses)
public class StockReportResponse
{
    public DateTime GeneratedAt { get; set; }
    public string ReportType { get; set; } = "CurrentStock";
    public StockSummaryResponse Summary { get; set; } = new();
    public List<StockItemReportResponse> Items { get; set; } = new();
    public List<StockMovementResponse> Movements { get; set; } = new();
    public List<StockAlertResponse> Alerts { get; set; } = new();
}


public class StockItemReportResponse
{
    public Guid ProductId { get; set; }
    public Guid? ProductVariantId { get; set; }
    public string ProductName { get; set; } = default!;
    public string? VariantName { get; set; }
    public string CategoryName { get; set; } = string.Empty;
    public int CurrentStock { get; set; }
    public int MinimumStock { get; set; }
    public int MaximumStock { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalValue { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime LastMovement { get; set; }
    public int MovementCount { get; set; }
    public decimal MovementValue { get; set; }
}

public class StockMovementResponse
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public Guid? ProductVariantId { get; set; }
    public string ProductName { get; set; } = default!;
    public string? VariantName { get; set; }
    public int Quantity { get; set; }
    public string ChangeType { get; set; } = string.Empty;
    public string? Reason { get; set; }
    public DateTime MovementDate { get; set; }
    public Guid? OrderId { get; set; }
    public string? OrderNumber { get; set; }
    public Guid? ChangedBy { get; set; }
    public string? ChangedByName { get; set; }
}

public class StockReportRequest
{
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
    public string ReportType { get; set; } = "CurrentStock";
    public List<Guid>? ProductIds { get; set; }
}

// Analytics Models for Dashboard Charts
public class SalesTrendDataResponse
{
    public DateTime Date { get; set; }
    public decimal Revenue { get; set; }
    public int OrderCount { get; set; }
}

public class OrderStatusDistributionResponse
{
    public int PendingCount { get; set; }
    public int PreparingCount { get; set; }
    public int ReadyCount { get; set; }
    public int OnWayCount { get; set; }
    public int DeliveredCount { get; set; }
    public int CancelledCount { get; set; }
}

public class CategoryPerformanceResponse
{
    public Guid CategoryId { get; set; }
    public string CategoryName { get; set; } = default!;
    public decimal TotalRevenue { get; set; }
    public int OrderCount { get; set; }
    public int ProductCount { get; set; }
}

// Product Review Models
public class ProductReviewResponse
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = default!;
    public Guid UserId { get; set; }
    public string UserName { get; set; } = default!;
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public bool IsVerifiedPurchase { get; set; }
    public bool IsApproved { get; set; }
    public int HelpfulCount { get; set; }
    public int NotHelpfulCount { get; set; }
    public string? MerchantResponse { get; set; }
    public DateTime? MerchantRespondedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class CreateProductReviewRequest
{
    public Guid ProductId { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public Guid? OrderId { get; set; }
}

public class UpdateProductReviewRequest
{
    public int Rating { get; set; }
    public string? Comment { get; set; }
}

public class ProductReviewStatsResponse
{
    public decimal AverageRating { get; set; }
    public int TotalReviews { get; set; }
    public int FiveStarCount { get; set; }
    public int FourStarCount { get; set; }
    public int ThreeStarCount { get; set; }
    public int TwoStarCount { get; set; }
    public int OneStarCount { get; set; }
    public int VerifiedPurchaseCount { get; set; }
    public int PendingApprovalCount { get; set; }
}

// Additional supporting models for Reports
public class CustomerGrowthData
{
    public DateTime Date { get; set; }
    public int NewCustomers { get; set; }
    public int ReturningCustomers { get; set; }
}

public class CustomerLTVData
{
    public DateTime Date { get; set; }
    public decimal AverageLTV { get; set; }
}

public class SalesByDayData
{
    public DateTime Date { get; set; }
    public int Sales { get; set; }
    public decimal Revenue { get; set; }
}

public class RespondToReviewRequest
{
    public string Response { get; set; } = default!;
}

// Delivery Zones
public class DeliveryZoneResponse
{
    public Guid Id { get; set; }
    public Guid MerchantId { get; set; }
    public string Name { get; set; } = default!;
    public string PolygonGeoJson { get; set; } = default!;
    public decimal DeliveryFee { get; set; }
    public int EstimatedMinutes { get; set; }
    public bool IsActive { get; set; }
}

public class CreateDeliveryZoneRequest
{
    public Guid MerchantId { get; set; }
    public string Name { get; set; } = default!;
    public string PolygonGeoJson { get; set; } = default!;
    public decimal DeliveryFee { get; set; }
    public int EstimatedMinutes { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateDeliveryZoneRequest : CreateDeliveryZoneRequest { }

public class CheckDeliveryZoneRequest
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}

public class CheckDeliveryZoneResponse
{
    public bool IsInside { get; set; }
    public Guid? ZoneId { get; set; }
    public string? ZoneName { get; set; }
}

// Delivery Optimization
public class DeliveryCapacityRequest
{
    public Guid MerchantId { get; set; }
    public Guid? DeliveryZoneId { get; set; }
    public int MaxActiveDeliveries { get; set; }
    public int MaxDailyDeliveries { get; set; }
}

public class DeliveryCapacityResponse : DeliveryCapacityRequest
{
    public Guid Id { get; set; }
    public int CurrentActiveDeliveries { get; set; }
    public int CurrentDailyDeliveries { get; set; }
}

public class DeliveryCapacityCheckRequest
{
    public Guid MerchantId { get; set; }
    public Guid? DeliveryZoneId { get; set; }
    public int RequestedDeliveries { get; set; }
}

public class DeliveryCapacityCheckResponse
{
    public bool Allowed { get; set; }
    public string? Reason { get; set; }
}

public class RouteWaypoint
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}

public class RouteOptimizationRequest
{
    public Guid MerchantId { get; set; }
    public List<RouteWaypoint> Waypoints { get; set; } = new();
}

public class DeliveryRouteResponse
{
    public Guid RouteId { get; set; }
    public double DistanceKm { get; set; }
    public int DurationMinutes { get; set; }
    public List<RouteWaypoint> Path { get; set; } = new();
}

public class RouteOptimizationResponse
{
    public List<DeliveryRouteResponse> Routes { get; set; } = new();
}

// File Upload Models
public class FileUploadResponse
{
    public string FileName { get; set; } = string.Empty;
    public string BlobUrl { get; set; } = string.Empty;
    public string Url => BlobUrl;
    public string ContainerName { get; set; } = string.Empty;
    public long FileSizeBytes { get; set; }
    public string ContentType { get; set; } = string.Empty;
    public DateTime UploadedAt { get; set; }
    public string? ThumbnailUrl { get; set; }
}

// Internationalization
public class LanguageResponse
{
    public Guid Id { get; set; }
    public int Code { get; set; }
    public string Name { get; set; } = string.Empty;
    public string NativeName { get; set; } = string.Empty;
    public string CultureCode { get; set; } = string.Empty;
    public bool IsRtl { get; set; }
    public bool IsActive { get; set; }
    public bool IsDefault { get; set; }
    public int SortOrder { get; set; }
    public string? FlagIcon { get; set; }
}

public class LanguageStatisticsResponse
{
    public int LanguageCode { get; set; }
    public string LanguageName { get; set; } = string.Empty;
    public int TotalTranslations { get; set; }
    public int ActiveTranslations { get; set; }
    public int InactiveTranslations { get; set; }
    public int UserCount { get; set; }
    public double CompletionPercentage { get; set; }
}

public class TranslationSearchResponseModel
{
    public List<TranslationItemModel> Translations { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
}

public class TranslationItemModel
{
    public Guid Id { get; set; }
    public string Key { get; set; } = string.Empty;
    public string Value { get; set; } = string.Empty;
    public int LanguageCode { get; set; }
    public string? Category { get; set; }
    public string? Context { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; }
}

public class TranslationSearchRequestModel
{
    public string? Key { get; set; }
    public int? LanguageCode { get; set; }
    public string? Category { get; set; }
    public string? Context { get; set; }
    public bool? IsActive { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

// Rate limiting
public class RateLimitRuleResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public int Type { get; set; }
    public string? Endpoint { get; set; }
    public string? HttpMethod { get; set; }
    public int RequestLimit { get; set; }
    public int Period { get; set; }
    public int Action { get; set; }
    public int? ThrottleDelayMs { get; set; }
    public bool IsActive { get; set; }
    public int Priority { get; set; }
    public string? UserRole { get; set; }
    public string? UserTier { get; set; }
}

public class RateLimitSearchRequestModel
{
    public string? Endpoint { get; set; }
    public string? HttpMethod { get; set; }
    public string? UserId { get; set; }
    public string? UserRole { get; set; }
    public string? UserTier { get; set; }
    public string? IpAddress { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public bool? IsLimitExceeded { get; set; }
}

public class RateLimitLogResponse
{
    public Guid Id { get; set; }
    public Guid? RateLimitRuleId { get; set; }
    public string? Endpoint { get; set; }
    public string? HttpMethod { get; set; }
    public string? UserId { get; set; }
    public string? UserName { get; set; }
    public string? UserRole { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public int Type { get; set; }
    public int Action { get; set; }
    public int RequestCount { get; set; }
    public int RequestLimit { get; set; }
    public int Period { get; set; }
    public bool IsLimitExceeded { get; set; }
    public string? Reason { get; set; }
    public DateTime RequestTime { get; set; }
    public DateTime? BlockedUntil { get; set; }
    public string? RequestId { get; set; }
    public string? SessionId { get; set; }
    public string? Country { get; set; }
    public string? City { get; set; }
    public string? DeviceType { get; set; }
    public string? Browser { get; set; }
    public string? OperatingSystem { get; set; }
}

public class RateLimitSearchResponseModel
{
    public List<RateLimitLogResponse> Logs { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
}

public class RateLimitCheckResponseModel
{
    public bool IsLimitExceeded { get; set; }
    public string? Message { get; set; }
    public int RemainingRequests { get; set; }
    public DateTime? RetryAfter { get; set; }
    public string? RuleName { get; set; }
    public string? Action { get; set; }
}

// Realtime tracking
public class OrderTrackingResponse
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Guid? CourierId { get; set; }
    public string? CourierName { get; set; }
    public string? CourierPhone { get; set; }
    public int Status { get; set; }
    public string StatusDisplayName { get; set; } = string.Empty;
    public string? StatusMessage { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }
    public int LocationUpdateType { get; set; }
    public double? Accuracy { get; set; }
    public DateTime? EstimatedArrivalTime { get; set; }
    public DateTime? ActualArrivalTime { get; set; }
    public int? EstimatedMinutesRemaining { get; set; }
    public double? DistanceFromDestination { get; set; }
    public bool IsActive { get; set; }
    public DateTime LastUpdatedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class LocationUpdateRequestModel
{
    public Guid OrderTrackingId { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }
    public int UpdateType { get; set; }
    public double? Accuracy { get; set; }
    public double? Speed { get; set; }
    public double? Bearing { get; set; }
    public double? Altitude { get; set; }
    public string? DeviceInfo { get; set; }
    public string? AppVersion { get; set; }
}

public class LocationUpdateResponse
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public DateTime UpdatedAt { get; set; }
    public double? DistanceFromDestination { get; set; }
    public int? EstimatedMinutesRemaining { get; set; }
}

public class StatusUpdateRequestModel
{
    public Guid OrderTrackingId { get; set; }
    public int Status { get; set; }
    public string? StatusMessage { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? Address { get; set; }
}

public class StatusUpdateResponse
{
    public bool Success { get; set; }
    public string? Message { get; set; }
    public DateTime UpdatedAt { get; set; }
    public bool NotificationSent { get; set; }
}

public class TrackingNotificationResponse
{
    public Guid Id { get; set; }
    public Guid OrderTrackingId { get; set; }
    public Guid? UserId { get; set; }
    public int Type { get; set; }
    public string TypeDisplayName { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool IsSent { get; set; }
    public bool IsRead { get; set; }
    public DateTime? SentAt { get; set; }
    public DateTime? ReadAt { get; set; }
    public string? DeliveryMethod { get; set; }
    public string? DeliveryStatus { get; set; }
    public string? ErrorMessage { get; set; }
    public int RetryCount { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class TrackingActiveResponse
{
    public bool IsActive { get; set; }
}

public class TrackingEtaResponse
{
    public Guid Id { get; set; }
    public Guid OrderTrackingId { get; set; }
    public DateTime EstimatedArrivalTime { get; set; }
    public int EstimatedMinutesRemaining { get; set; }
    public double? DistanceRemaining { get; set; }
    public double? AverageSpeed { get; set; }
    public string? CalculationMethod { get; set; }
    public double? Confidence { get; set; }
    public string? Notes { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class LocationHistoryResponse
{
    public Guid Id { get; set; }
    public Guid OrderTrackingId { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? Address { get; set; }
    public string? City { get; set; }
    public string? District { get; set; }
    public int UpdateType { get; set; }
    public string UpdateTypeDisplayName { get; set; } = string.Empty;
    public double? Accuracy { get; set; }
    public double? Speed { get; set; }
    public double? Bearing { get; set; }
    public double? Altitude { get; set; }
    public string? DeviceInfo { get; set; }
    public string? AppVersion { get; set; }
    public DateTime RecordedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class TrackingSettingsResponse
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public Guid? MerchantId { get; set; }
    public bool EnableLocationTracking { get; set; }
    public bool EnablePushNotifications { get; set; }
    public bool EnableSMSNotifications { get; set; }
    public bool EnableEmailNotifications { get; set; }
    public int LocationUpdateInterval { get; set; }
    public int NotificationInterval { get; set; }
    public double LocationAccuracyThreshold { get; set; }
    public bool EnableETAUpdates { get; set; }
    public int ETAUpdateInterval { get; set; }
    public bool EnableDelayAlerts { get; set; }
    public int DelayThresholdMinutes { get; set; }
    public bool EnableNearbyAlerts { get; set; }
    public double NearbyDistanceMeters { get; set; }
    public string? PreferredLanguage { get; set; }
    public string? TimeZone { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class UpdateTrackingSettingsRequestModel
{
    public bool EnableLocationTracking { get; set; }
    public bool EnablePushNotifications { get; set; }
    public bool EnableSMSNotifications { get; set; }
    public bool EnableEmailNotifications { get; set; }
    public int LocationUpdateInterval { get; set; }
    public int NotificationInterval { get; set; }
    public double LocationAccuracyThreshold { get; set; }
    public bool EnableETAUpdates { get; set; }
    public int ETAUpdateInterval { get; set; }
    public bool EnableDelayAlerts { get; set; }
    public int DelayThresholdMinutes { get; set; }
    public bool EnableNearbyAlerts { get; set; }
    public double NearbyDistanceMeters { get; set; }
    public string? PreferredLanguage { get; set; }
    public string? TimeZone { get; set; }
}

// User self-service models
public class UserProfileResponse
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string Role { get; set; } = string.Empty;
    public bool IsEmailVerified { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UpdateUserProfileRequest
{
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? AvatarUrl { get; set; }
}

public class UserNotificationPreferencesResponse
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public bool EmailEnabled { get; set; }
    public bool EmailOrderUpdates { get; set; }
    public bool EmailPromotions { get; set; }
    public bool EmailNewsletter { get; set; }
    public bool EmailSecurityAlerts { get; set; }
    public bool SmsEnabled { get; set; }
    public bool SmsOrderUpdates { get; set; }
    public bool SmsPromotions { get; set; }
    public bool SmsSecurityAlerts { get; set; }
    public bool PushEnabled { get; set; }
    public bool PushOrderUpdates { get; set; }
    public bool PushPromotions { get; set; }
    public bool PushMerchantUpdates { get; set; }
    public bool PushSecurityAlerts { get; set; }
    public bool SoundEnabled { get; set; }
    public bool DesktopNotifications { get; set; }
    public string NotificationSound { get; set; } = "default";
    public bool NewOrderNotifications { get; set; }
    public bool StatusChangeNotifications { get; set; }
    public bool CancellationNotifications { get; set; }
    public TimeSpan? QuietStartTime { get; set; }
    public TimeSpan? QuietEndTime { get; set; }
    public bool RespectQuietHours { get; set; }
    public string Language { get; set; } = "tr-TR";
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class UpdateUserNotificationPreferencesRequestModel
{
    public bool? EmailEnabled { get; set; }
    public bool? EmailOrderUpdates { get; set; }
    public bool? EmailPromotions { get; set; }
    public bool? EmailNewsletter { get; set; }
    public bool? EmailSecurityAlerts { get; set; }
    public bool? SmsEnabled { get; set; }
    public bool? SmsOrderUpdates { get; set; }
    public bool? SmsPromotions { get; set; }
    public bool? SmsSecurityAlerts { get; set; }
    public bool? PushEnabled { get; set; }
    public bool? PushOrderUpdates { get; set; }
    public bool? PushPromotions { get; set; }
    public bool? PushMerchantUpdates { get; set; }
    public bool? PushSecurityAlerts { get; set; }
    public bool? SoundEnabled { get; set; }
    public bool? DesktopNotifications { get; set; }
    public string? NotificationSound { get; set; }
    public bool? NewOrderNotifications { get; set; }
    public bool? StatusChangeNotifications { get; set; }
    public bool? CancellationNotifications { get; set; }
    public TimeSpan? QuietStartTime { get; set; }
    public TimeSpan? QuietEndTime { get; set; }
    public bool? RespectQuietHours { get; set; }
    public string? Language { get; set; }
}

public class AddressResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string FullAddress { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string District { get; set; } = string.Empty;
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
    public bool IsDefault { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateAddressRequestModel
{
    public string Title { get; set; } = string.Empty;
    public string FullAddress { get; set; } = string.Empty;
    public string City { get; set; } = string.Empty;
    public string District { get; set; } = string.Empty;
    public decimal Latitude { get; set; }
    public decimal Longitude { get; set; }
}

public class UpdateAddressRequestModel : CreateAddressRequestModel { }

public class AddToFavoritesRequestModel
{
    public Guid ProductId { get; set; }
}

public class FavoriteProductResponse
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string? ProductDescription { get; set; }
    public decimal Price { get; set; }
    public string? ImageUrl { get; set; }
    public Guid MerchantId { get; set; }
    public string MerchantName { get; set; } = string.Empty;
    public bool IsAvailable { get; set; }
    public DateTime AddedAt { get; set; }
}

public class OrderResponseModel
{
    public Guid Id { get; set; }
    public string OrderNumber { get; set; } = string.Empty;
    public Guid UserId { get; set; }
    public Guid MerchantId { get; set; }
    public string MerchantName { get; set; } = string.Empty;
    public Guid? CourierId { get; set; }
    public string Status { get; set; } = string.Empty;
    public decimal SubTotal { get; set; }
    public decimal DeliveryFee { get; set; }
    public decimal Discount { get; set; }
    public decimal Total { get; set; }
    public string PaymentMethod { get; set; } = string.Empty;
    public string PaymentStatus { get; set; } = string.Empty;
    public string DeliveryAddress { get; set; } = string.Empty;
    public decimal? DeliveryLatitude { get; set; }
    public decimal? DeliveryLongitude { get; set; }
    public DateTime? EstimatedDeliveryTime { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<OrderLineResponseModel> Items { get; set; } = new();
}

public class OrderLineResponseModel
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public Guid? ProductVariantId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string? VariantName { get; set; }
    public int Quantity { get; set; }
    public decimal UnitPrice { get; set; }
    public decimal TotalPrice { get; set; }
    public List<OrderLineOptionResponseModel> Options { get; set; } = new();
}

public class OrderLineOptionResponseModel
{
    public Guid Id { get; set; }
    public Guid ProductOptionId { get; set; }
    public string OptionName { get; set; } = string.Empty;
    public decimal ExtraPrice { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class OrderTimelineResponseModel
{
    public DateTime Timestamp { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string? ActorName { get; set; }
}

public class OrderDetailsResponseModel : OrderResponseModel
{
    public DateTime? CompletedAt { get; set; }
    public List<OrderTimelineResponseModel> Timeline { get; set; } = new();
}

public class CancelOrderRequestModel
{
    public Guid OrderId { get; set; }
    public string Reason { get; set; } = string.Empty;
}

// Geo analytics models
public class NearbyMerchantResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Address { get; set; } = string.Empty;
    public double DistanceKm { get; set; }
    public decimal DeliveryFee { get; set; }
    public int EstimatedDeliveryTimeMinutes { get; set; }
    public decimal? Rating { get; set; }
    public int TotalReviews { get; set; }
    public bool IsOpen { get; set; }
    public string? LogoUrl { get; set; }
    public int? CategoryType { get; set; }
}

public class DeliveryEstimateResponse
{
    public int EstimatedDeliveryTimeMinutes { get; set; }
    public decimal DeliveryFee { get; set; }
    public bool IsInDeliveryZone { get; set; }
    public string? ZoneName { get; set; }
    public double DistanceKm { get; set; }
}

public class LocationSuggestionResponse
{
    public string Address { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? District { get; set; }
    public string? City { get; set; }
    public double? DistanceKm { get; set; }
}

public class SaveUserLocationRequestModel
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? Address { get; set; }
}

public class MerchantInAreaResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? Description { get; set; }
}

public class UserLocationResponseModel
{
    public Guid Id { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public string? Address { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class LocationAnalyticsResponseModel
{
    public int TotalLocations { get; set; }
    public int UniqueUsers { get; set; }
    public List<LocationHeatmapDataModel> HeatmapData { get; set; } = new();
}

public class LocationHeatmapDataModel
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public int Count { get; set; }
}

public class DeliveryZoneCoverageResponseModel
{
    public int TotalZones { get; set; }
    public List<DeliveryZoneSummaryModel> Zones { get; set; } = new();
}

public class DeliveryZoneSummaryModel
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int MerchantCount { get; set; }
}

// Audit logging models
public class UserActivityLogResponse
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string ActivityType { get; set; } = string.Empty;
    public string ActivityDescription { get; set; } = string.Empty;
    public string? EntityType { get; set; }
    public string? EntityId { get; set; }
    public string? ActivityData { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? SessionId { get; set; }
    public string? RequestId { get; set; }
    public string? DeviceType { get; set; }
    public string? Browser { get; set; }
    public string? OperatingSystem { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? Location { get; set; }
    public DateTime Timestamp { get; set; }
    public int Duration { get; set; }
    public bool IsSuccess { get; set; }
    public string? ErrorMessage { get; set; }
}

public class UserActivityQueryRequestModel
{
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public Guid? UserId { get; set; }
    public string? UserName { get; set; }
    public string? ActivityType { get; set; }
    public string? EntityType { get; set; }
    public string? EntityId { get; set; }
    public string? DeviceType { get; set; }
    public string? Browser { get; set; }
    public string? OperatingSystem { get; set; }
    public bool? IsSuccess { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string? SortBy { get; set; } = "Timestamp";
    public string? SortDirection { get; set; } = "DESC";
}

public class SystemChangeLogResponse
{
    public Guid Id { get; set; }
    public string ChangeType { get; set; } = string.Empty;
    public string EntityType { get; set; } = string.Empty;
    public string EntityId { get; set; } = string.Empty;
    public string? EntityName { get; set; }
    public string? OldValues { get; set; }
    public string? NewValues { get; set; }
    public string? ChangedFields { get; set; }
    public string? ChangeReason { get; set; }
    public string? ChangeSource { get; set; }
    public Guid? ChangedByUserId { get; set; }
    public string? ChangedByUserName { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? SessionId { get; set; }
    public string? RequestId { get; set; }
    public string? CorrelationId { get; set; }
    public DateTime Timestamp { get; set; }
    public bool IsSuccess { get; set; }
    public string? ErrorMessage { get; set; }
    public string? Severity { get; set; }
}

public class SystemChangeQueryRequestModel
{
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? ChangeType { get; set; }
    public string? EntityType { get; set; }
    public string? EntityId { get; set; }
    public Guid? ChangedByUserId { get; set; }
    public string? ChangedByUserName { get; set; }
    public string? ChangeSource { get; set; }
    public string? Severity { get; set; }
    public bool? IsSuccess { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string? SortBy { get; set; } = "Timestamp";
    public string? SortDirection { get; set; } = "DESC";
}

public class SecurityEventLogResponse
{
    public Guid Id { get; set; }
    public string EventType { get; set; } = string.Empty;
    public string EventTitle { get; set; } = string.Empty;
    public string EventDescription { get; set; } = string.Empty;
    public string? Severity { get; set; }
    public string? RiskLevel { get; set; }
    public Guid? UserId { get; set; }
    public string? UserName { get; set; }
    public string? UserRole { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? DeviceFingerprint { get; set; }
    public string? SessionId { get; set; }
    public string? RequestId { get; set; }
    public string? CorrelationId { get; set; }
    public string? EventData { get; set; }
    public string? ThreatIndicators { get; set; }
    public string? MitigationActions { get; set; }
    public string? Source { get; set; }
    public string? Category { get; set; }
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string? Location { get; set; }
    public DateTime Timestamp { get; set; }
    public bool IsResolved { get; set; }
    public DateTime? ResolvedAt { get; set; }
    public string? ResolvedBy { get; set; }
    public string? ResolutionNotes { get; set; }
    public bool RequiresInvestigation { get; set; }
    public bool IsFalsePositive { get; set; }
}

public class SecurityEventQueryRequestModel
{
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public string? EventType { get; set; }
    public string? Severity { get; set; }
    public string? RiskLevel { get; set; }
    public Guid? UserId { get; set; }
    public string? UserName { get; set; }
    public string? UserRole { get; set; }
    public string? IpAddress { get; set; }
    public string? Source { get; set; }
    public string? Category { get; set; }
    public bool? IsResolved { get; set; }
    public bool? RequiresInvestigation { get; set; }
    public bool? IsFalsePositive { get; set; }
    public int PageNumber { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string? SortBy { get; set; } = "Timestamp";
    public string? SortDirection { get; set; } = "DESC";
}

public class AuditLogAnalyticsRequestModel
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string? GroupBy { get; set; } = "DAY";
    public string? EntityType { get; set; }
    public string? Action { get; set; }
    public string? UserId { get; set; }
}

public class AuditLogAnalyticsResponse
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string GroupBy { get; set; } = string.Empty;
    public List<AuditLogAnalyticsData> Data { get; set; } = new();
    public AuditLogAnalyticsSummary Summary { get; set; } = new();
    public DateTime GeneratedAt { get; set; }
}

public class AuditLogAnalyticsData
{
    public string Period { get; set; } = string.Empty;
    public int TotalEvents { get; set; }
    public int SuccessfulEvents { get; set; }
    public int FailedEvents { get; set; }
    public int UniqueUsers { get; set; }
    public Dictionary<string, int> ActionCounts { get; set; } = new();
    public Dictionary<string, int> EntityTypeCounts { get; set; } = new();
}

public class AuditLogAnalyticsSummary
{
    public int TotalEvents { get; set; }
    public int SuccessfulEvents { get; set; }
    public int FailedEvents { get; set; }
    public int UniqueUsers { get; set; }
    public double SuccessRate { get; set; }
    public Dictionary<string, int> TopActions { get; set; } = new();
    public Dictionary<string, int> TopEntityTypes { get; set; } = new();
    public Dictionary<string, int> TopUsers { get; set; } = new();
    public List<string> Alerts { get; set; } = new();
}

public class LogAnalysisReportResponse
{
    public Guid Id { get; set; }
    public string ReportType { get; set; } = string.Empty;
    public string ReportTitle { get; set; } = string.Empty;
    public string? ReportDescription { get; set; }
    public DateTime ReportStartDate { get; set; }
    public DateTime ReportEndDate { get; set; }
    public string? TimeZone { get; set; }
    public string? ReportData { get; set; }
    public string? Summary { get; set; }
    public string? Insights { get; set; }
    public string? Alerts { get; set; }
    public string? Charts { get; set; }
    public string? Status { get; set; }
    public string? Format { get; set; }
    public string? FilePath { get; set; }
    public string? FileName { get; set; }
    public long? FileSizeBytes { get; set; }
    public Guid? GeneratedByUserId { get; set; }
    public string? GeneratedByUserName { get; set; }
    public string? GeneratedByRole { get; set; }
    public DateTime GeneratedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public bool IsPublic { get; set; }
    public string? Recipients { get; set; }
    public bool IsScheduled { get; set; }
    public string? SchedulePattern { get; set; }
    public DateTime? NextScheduledRun { get; set; }
    public int GenerationTimeMs { get; set; }
    public string? ErrorMessage { get; set; }
}

// Admin / platform models
public class AdminDashboardResponse
{
    public AdminDashboardStats Stats { get; set; } = new();
    public List<RecentMerchantApplicationResponse> RecentApplications { get; set; } = new();
    public List<SystemMetricsResponse> SystemMetrics { get; set; } = new();
    public List<AdminNotificationResponse> Notifications { get; set; } = new();
}

public class AdminDashboardStats
{
    public int TotalUsers { get; set; }
    public int TotalMerchants { get; set; }
    public int TotalCouriers { get; set; }
    public int TotalOrders { get; set; }
    public int PendingMerchantApplications { get; set; }
    public int ActiveOrders { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal TodayRevenue { get; set; }
    public int SystemUptime { get; set; }
}

public class RecentMerchantApplicationResponse
{
    public Guid Id { get; set; }
    public string BusinessName { get; set; } = string.Empty;
    public string OwnerName { get; set; } = string.Empty;
    public string OwnerEmail { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime SubmittedAt { get; set; }
    public string? RejectionReason { get; set; }
}

public class SystemMetricsResponse
{
    public string MetricName { get; set; } = string.Empty;
    public decimal Value { get; set; }
    public string Unit { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
    public string Trend { get; set; } = "stable";
}

public class AdminNotificationResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public bool IsRead { get; set; }
}

public class SystemStatisticsResponse
{
    public UserStatisticsResponse UserStats { get; set; } = new();
    public MerchantStatisticsResponse MerchantStats { get; set; } = new();
    public AdminOrderStatisticsResponse OrderStats { get; set; } = new();
    public RevenueStatisticsResponse RevenueStats { get; set; } = new();
    public PerformanceMetricsResponse PerformanceMetrics { get; set; } = new();
}

public class UserStatisticsResponse
{
    public int TotalUsers { get; set; }
    public int ActiveUsers { get; set; }
    public int NewUsersThisMonth { get; set; }
    public int NewUsersToday { get; set; }
    public List<UserGrowthDataResponse> UserGrowthData { get; set; } = new();
}

public class MerchantStatisticsResponse
{
    public int TotalMerchants { get; set; }
    public int ActiveMerchants { get; set; }
    public int PendingApplications { get; set; }
    public int ApprovedThisMonth { get; set; }
    public List<MerchantGrowthDataResponse> MerchantGrowthData { get; set; } = new();
}

public class AdminOrderStatisticsResponse
{
    public int TotalOrders { get; set; }
    public int CompletedOrders { get; set; }
    public int CancelledOrders { get; set; }
    public int PendingOrders { get; set; }
    public decimal AverageOrderValue { get; set; }
    public List<AdminOrderTrendDataResponse> OrderTrendData { get; set; } = new();
}

public class RevenueStatisticsResponse
{
    public decimal TotalRevenue { get; set; }
    public decimal MonthlyRevenue { get; set; }
    public decimal DailyRevenue { get; set; }
    public decimal AverageOrderValue { get; set; }
    public List<RevenueTrendDataResponse> RevenueTrendData { get; set; } = new();
}

public class PerformanceMetricsResponse
{
    public decimal SystemUptime { get; set; }
    public decimal AverageResponseTime { get; set; }
    public int ActiveConnections { get; set; }
    public decimal CpuUsage { get; set; }
    public decimal MemoryUsage { get; set; }
    public int DatabaseConnections { get; set; }
}

public class UserGrowthDataResponse
{
    public DateTime Date { get; set; }
    public int NewUsers { get; set; }
    public int TotalUsers { get; set; }
}

public class MerchantGrowthDataResponse
{
    public DateTime Date { get; set; }
    public int NewMerchants { get; set; }
    public int TotalMerchants { get; set; }
}

public class AdminOrderTrendDataResponse
{
    public DateTime Date { get; set; }
    public int OrderCount { get; set; }
    public decimal TotalValue { get; set; }
}

public class RevenueTrendDataResponse
{
    public DateTime Date { get; set; }
    public decimal Revenue { get; set; }
    public int OrderCount { get; set; }
}

public class AuditLogResponse
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty;
    public string EntityType { get; set; } = string.Empty;
    public string EntityId { get; set; } = string.Empty;
    public string Details { get; set; } = string.Empty;
    public string IpAddress { get; set; } = string.Empty;
    public string UserAgent { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
}

public class AuditLogStatsResponse
{
    public int TotalLogs { get; set; }
    public int LogsToday { get; set; }
    public int LogsThisWeek { get; set; }
    public int LogsThisMonth { get; set; }
    public List<AuditLogSummaryResponse> ActionSummary { get; set; } = new();
    public List<AuditLogSummaryResponse> UserSummary { get; set; } = new();
}

public class AuditLogSummaryResponse
{
    public string Key { get; set; } = string.Empty;
    public int Count { get; set; }
    public decimal Percentage { get; set; }
}

public class PaginationQueryRequest
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

// Merchant Documents
public class MerchantDocumentResponse
{
    public Guid Id { get; set; }
    public Guid MerchantId { get; set; }
    public Guid UploadedBy { get; set; }
    public string DocumentType { get; set; } = default!;
    public string DocumentName { get; set; } = default!;
    public string FileName { get; set; } = default!;
    public string FileUrl { get; set; } = default!;
    public string MimeType { get; set; } = default!;
    public long FileSize { get; set; }
    public string? Description { get; set; }
    public DateTime? ExpiryDate { get; set; }
    public bool IsRequired { get; set; }
    public bool IsVerified { get; set; }
    public bool IsApproved { get; set; }
    public string? VerificationNotes { get; set; }
    public Guid? VerifiedBy { get; set; }
    public DateTime? VerifiedAt { get; set; }
    public string Status { get; set; } = default!;
    public string? RejectionReason { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public string UploadedByUserName { get; set; } = default!;
    public string? VerifiedByUserName { get; set; }
    public bool IsExpired { get; set; }
    public int DaysUntilExpiry { get; set; }
}

public class UploadMerchantDocumentRequest
{
    public Guid MerchantId { get; set; }
    public string DocumentType { get; set; } = default!;
    public string? Notes { get; set; }
}

public class MerchantDocumentProgressResponse
{
    public Guid MerchantId { get; set; }
    public int TotalRequiredDocuments { get; set; }
    public int UploadedDocuments { get; set; }
    public int VerifiedDocuments { get; set; }
    public decimal CompletionPercentage { get; set; }
}

public class DocumentTypeResponse
{
    public string Type { get; set; } = default!;
    public string Name { get; set; } = default!;
    public bool IsRequired { get; set; }
}

public class MerchantDocumentStatisticsResponse
{
    public int TotalDocuments { get; set; }
    public int PendingDocuments { get; set; }
    public int ApprovedDocuments { get; set; }
    public int RejectedDocuments { get; set; }
    public int ExpiredDocuments { get; set; }
}

public class VerifyMerchantDocumentRequest
{
    public Guid DocumentId { get; set; }
    public bool IsApproved { get; set; }
    public string? VerificationNotes { get; set; }
    public string? RejectionReason { get; set; }
}

public class BulkVerifyDocumentsRequest
{
    public List<Guid> DocumentIds { get; set; } = new();
    public bool IsApproved { get; set; }
    public string? VerificationNotes { get; set; }
}

public class BulkVerifyDocumentsResponse
{
    public int TotalDocuments { get; set; }
    public int SuccessfulVerifications { get; set; }
    public int FailedVerifications { get; set; }
    public List<string> Errors { get; set; } = new();
}

public class DocumentDownloadResult
{
    public byte[] Content { get; set; } = Array.Empty<byte>();
    public string ContentType { get; set; } = "application/octet-stream";
    public string FileName { get; set; } = "document";
}


// Campaign Models
public class CampaignResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = default!;
    public string? Description { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IsActive { get; set; }
}

// Coupon Models
public class ValidateCouponRequest
{
    public string Code { get; set; } = default!;
    public decimal? OrderAmount { get; set; }
}

public class CouponValidationResponse
{
    public bool IsValid { get; set; }
    public string? Reason { get; set; }
    public decimal? DiscountAmount { get; set; }
    public string? DiscountType { get; set; }
}

public class CreateCouponRequest
{
    public string Code { get; set; } = default!;
    public string? Description { get; set; }
    public string DiscountType { get; set; } = "Amount"; // Amount | Percentage
    public decimal DiscountValue { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int UsageLimit { get; set; }
    public bool IsActive { get; set; } = true;
}

public class CouponResponse
{
    public Guid Id { get; set; }
    public string Code { get; set; } = default!;
    public string? Description { get; set; }
    public string DiscountType { get; set; } = default!;
    public decimal DiscountValue { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int UsageLimit { get; set; }
    public int UsedCount { get; set; }
    public bool IsActive { get; set; }
}

// Product Option Models
public class ProductOptionGroupResponse
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsRequired { get; set; }
}

public class CreateProductOptionGroupRequest
{
    public Guid ProductId { get; set; }
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsRequired { get; set; }
}

public class UpdateProductOptionGroupRequest : CreateProductOptionGroupRequest { }

public class ProductOptionResponse
{
    public Guid Id { get; set; }
    public Guid ProductOptionGroupId { get; set; }
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public decimal? ExtraPrice { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
}

public class CreateProductOptionRequest
{
    public Guid ProductOptionGroupId { get; set; }
    public string Name { get; set; } = default!;
    public string? Description { get; set; }
    public decimal? ExtraPrice { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateProductOptionRequest : CreateProductOptionRequest { }

public class BulkCreateProductOptionsRequest
{
    public Guid ProductId { get; set; }
    public List<CreateProductOptionGroupRequest> Groups { get; set; } = new();
    public List<CreateProductOptionRequest> Options { get; set; } = new();
}

public class BulkUpdateProductOptionsRequest
{
    public List<UpdateProductOptionGroupRequest> Groups { get; set; } = new();
    public List<UpdateProductOptionRequest> Options { get; set; } = new();
}

// Market Product Variant Models
public class MarketProductVariantResponse
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public string Name { get; set; } = default!;
    public string? Sku { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public bool IsActive { get; set; }
}

public class CreateMarketProductVariantRequest
{
    public Guid ProductId { get; set; }
    public string Name { get; set; } = default!;
    public string? Sku { get; set; }
    public decimal Price { get; set; }
    public int StockQuantity { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateMarketProductVariantRequest : CreateMarketProductVariantRequest { }

public class UpdateVariantStockRequest
{
    public Guid Id { get; set; }
    public int NewStockQuantity { get; set; }
}

// Onboarding Models
public class MerchantOnboardingResponse
{
    public Guid MerchantId { get; set; }
    public string Status { get; set; } = default!;
    public DateTime? SubmittedAt { get; set; }
}

public class OnboardingProgressResponse
{
    public int CompletedSteps { get; set; }
    public int TotalSteps { get; set; }
    public decimal Progress => TotalSteps == 0 ? 0 : Math.Round((decimal)CompletedSteps / TotalSteps * 100, 2);
}

public class OnboardingStepResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = default!;
    public string Description { get; set; } = default!;
    public bool IsCompleted { get; set; }
}

public class CompleteOnboardingStepRequest
{
    public string Notes { get; set; } = string.Empty;
}
