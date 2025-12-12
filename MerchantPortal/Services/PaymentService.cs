using System.Net.Http.Json;
using Getir.MerchantPortal.Models;
using System.Text;

namespace Getir.MerchantPortal.Services;

public class PaymentService : IPaymentService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<PaymentService> _logger;

    /// <summary>
    /// PaymentService constructor
    /// </summary>
    /// <param name="httpClient">HTTP client</param>
    /// <param name="logger">Logger instance</param>
    public PaymentService(HttpClient httpClient, ILogger<PaymentService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    /// <summary>
    /// Ödeme geçmişini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="filter">Filtre parametreleri</param>
    /// <returns>Ödeme geçmişi listesi</returns>
    public async Task<List<PaymentListItemModel>> GetPaymentHistoryAsync(Guid merchantId, PaymentFilterModel filter)
    {
        try
        {
            // Build query string
            var queryParams = new List<string> 
            { 
                "Page=1",
                "PageSize=100" // Adjust as needed
            };
            
            if (filter.StartDate.HasValue)
                queryParams.Add($"startDate={filter.StartDate:yyyy-MM-dd}");
            if (filter.EndDate.HasValue)
                queryParams.Add($"endDate={filter.EndDate:yyyy-MM-dd}");
            if (!string.IsNullOrEmpty(filter.PaymentMethod))
                queryParams.Add($"paymentMethod={filter.PaymentMethod}");
            if (!string.IsNullOrEmpty(filter.PaymentStatus))
                queryParams.Add($"status={filter.PaymentStatus}");

            var query = string.Join("&", queryParams);
            
            // ✅ FIXED: Correct endpoint path
            var response = await _httpClient.GetAsync($"api/v1/payment/merchant/{merchantId}/transactions?{query}");

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Failed to get payment history: {StatusCode}", response.StatusCode);
                return new List<PaymentListItemModel>();
            }

            // Response is PagedResult<PaymentResponse>
            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<PagedResult<PaymentResponse>>>();
            var payments = apiResponse?.Data?.Items ?? new List<PaymentResponse>();
            
            // Map to list item model
            return payments.Select(p => new PaymentListItemModel
            {
                Id = p.Id,
                OrderId = p.OrderId,
                OrderNumber = $"ORD-{p.OrderId.ToString().Substring(0, 8)}",
                PaymentMethod = p.PaymentMethod.ToString(),
                Status = p.Status.ToString(),
                Amount = p.Amount,
                CreatedAt = p.CreatedAt,
                CompletedAt = p.CompletedAt,
                CustomerName = "Customer" // Would come from order details
            }).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting payment history for merchant {MerchantId}", merchantId);
            return new List<PaymentListItemModel>();
        }
    }

    /// <summary>
    /// Ödeme detaylarını getir
    /// </summary>
    /// <param name="paymentId">Ödeme ID</param>
    /// <returns>Ödeme detayları</returns>
    public async Task<PaymentResponse?> GetPaymentByIdAsync(Guid paymentId)
    {
        try
        {
            var response = await _httpClient.GetAsync($"api/v1/payment/{paymentId}");
            if (!response.IsSuccessStatusCode)
                return null;

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<PaymentResponse>>();
            return apiResponse?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting payment {PaymentId}", paymentId);
            return null;
        }
    }

    /// <summary>
    /// Mutabakat raporunu getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Mutabakat raporu</returns>
    public async Task<SettlementReportModel> GetSettlementReportAsync(Guid merchantId, DateTime startDate, DateTime endDate)
    {
        try
        {
            var response = await _httpClient.GetAsync(
                $"api/v1/payment/merchant/{merchantId}/summary?startDate={startDate:yyyy-MM-dd}&endDate={endDate:yyyy-MM-dd}");

            if (!response.IsSuccessStatusCode)
            {
                return CreateEmptySettlementReport(startDate, endDate);
            }

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<MerchantCashSummaryResponse>>();
            var settlement = apiResponse?.Data;
            if (settlement == null)
            {
                return CreateEmptySettlementReport(startDate, endDate);
            }

            var dailyBreakdown = new List<DailySettlementModel>();
            for (var date = startDate.Date; date <= endDate.Date; date = date.AddDays(1))
            {
                var dayPayments = settlement.Payments.Where(p => p.CreatedAt.Date == date).ToList();
                if (dayPayments.Any())
                {
                    var dayRevenue = dayPayments.Sum(p => p.Amount);
                    var dayCommission = settlement.TotalCommission > 0 
                        ? (dayRevenue / settlement.TotalAmount) * settlement.TotalCommission 
                        : 0;

                    dailyBreakdown.Add(new DailySettlementModel
                    {
                        Date = date,
                        Revenue = dayRevenue,
                        Commission = dayCommission,
                        NetAmount = dayRevenue - dayCommission,
                        OrderCount = dayPayments.Count
                    });
                }
            }

            return new SettlementReportModel
            {
                StartDate = startDate,
                EndDate = endDate,
                TotalRevenue = settlement.TotalAmount,
                TotalCommission = settlement.TotalCommission,
                NetAmount = settlement.NetAmount,
                TotalOrders = settlement.TotalOrders,
                CompletedOrders = settlement.Payments.Count(p => p.Status == "Completed"),
                RevenueByMethod = settlement.Payments
                    .GroupBy(p => p.PaymentMethod)
                    .ToDictionary(g => g.Key, g => g.Sum(p => p.Amount)),
                DailyBreakdown = dailyBreakdown
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting settlement report");
            return CreateEmptySettlementReport(startDate, endDate);
        }
    }

    /// <summary>
    /// Gelir analizlerini getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Gelir analizleri</returns>
    public async Task<RevenueAnalyticsModel> GetRevenueAnalyticsAsync(Guid merchantId, DateTime? startDate = null, DateTime? endDate = null)
    {
        try
        {
            // Get payments for different periods
            var now = DateTime.Now;
            var todayStart = now.Date;
            var weekStart = now.Date.AddDays(-(int)now.DayOfWeek);
            var monthStart = new DateTime(now.Year, now.Month, 1);
            var yearStart = new DateTime(now.Year, 1, 1);

            var response = await _httpClient.GetAsync(
                $"api/v1/payment/merchant/{merchantId}/transactions?Page=1&PageSize=1000&startDate={yearStart:yyyy-MM-dd}");

            if (!response.IsSuccessStatusCode)
            {
                return CreateEmptyAnalytics();
            }

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<PagedResult<PaymentResponse>>>();
            var payments = apiResponse?.Data?.Items ?? new List<PaymentResponse>();

            var completedPayments = payments.Where(p => p.Status == "Completed").ToList();

            var start = startDate ?? DateTime.Now.AddDays(-30);
            var end = endDate ?? DateTime.Now;
            
            return new RevenueAnalyticsModel
            {
                StartDate = start,
                EndDate = end,
                TotalRevenue = completedPayments.Sum(p => p.Amount),
                DailyRevenue = GetDailyRevenue(completedPayments, start, end),
                WeeklyRevenue = GetWeeklyRevenue(completedPayments, start, end),
                MonthlyRevenue = GetMonthlyRevenue(completedPayments, start, end),
                RevenueTrend = CalculateRevenueTrend(completedPayments, start, end),
                PaymentMethodDistribution = GetPaymentMethodDistribution(completedPayments),
                RevenueByHour = GetRevenueByHour(completedPayments),
                TopRevenueDays = GetTopRevenueDays(completedPayments, start, end)
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting revenue analytics");
            return CreateEmptyAnalytics();
        }
    }


    /// <summary>
    /// Ödemeleri Excel'e aktar
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="request">Aktarım isteği</param>
    /// <returns>Excel dosyası</returns>
    public async Task<byte[]> ExportToExcelAsync(Guid merchantId, PaymentExportRequest request)
    {
        try
        {
            var filter = new PaymentFilterModel
            {
                StartDate = request.StartDate,
                EndDate = request.EndDate,
                PaymentMethod = request.PaymentMethod,
                PaymentStatus = request.Status
            };

            var payments = await GetPaymentHistoryAsync(merchantId, filter);

            var csv = new StringBuilder();
            csv.AppendLine("Order Number,Payment Method,Status,Amount,Created At,Completed At");

            foreach (var payment in payments)
            {
                csv.AppendLine($"{payment.OrderNumber},{payment.PaymentMethod},{payment.Status},{payment.Amount:F2},{payment.CreatedAt:yyyy-MM-dd HH:mm},{payment.CompletedAt:yyyy-MM-dd HH:mm}");
            }

            return Encoding.UTF8.GetBytes(csv.ToString());
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting payments to Excel");
            return Encoding.UTF8.GetBytes("Error generating export");
        }
    }

    /// <summary>
    /// Ödemeleri PDF'e aktar
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="request">Aktarım isteği</param>
    /// <returns>PDF dosyası</returns>
    public async Task<byte[]> ExportToPdfAsync(Guid merchantId, PaymentExportRequest request)
    {
        // TODO: Implement PDF export with iTextSharp or similar library
        // For now, return CSV as fallback
        return await ExportToExcelAsync(merchantId, request);
    }

    public async Task<List<SettlementResponse>> GetMerchantSettlementsAsync(Guid merchantId, int page = 1, int pageSize = 50)
    {
        try
        {
            var response = await _httpClient.GetAsync(
                $"api/v1/payment/merchant/{merchantId}/settlements?Page={page}&PageSize={pageSize}");

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Failed to get settlements: {StatusCode}", response.StatusCode);
                return new List<SettlementResponse>();
            }

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<PagedResult<SettlementResponse>>>();
            return apiResponse?.Data?.Items ?? new List<SettlementResponse>();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting settlements for merchant {MerchantId}", merchantId);
            return new List<SettlementResponse>();
        }
    }

    public async Task<PagedResult<PaymentResponse>?> GetAdminCashCollectionsAsync(int page = 1, int pageSize = 20, string? status = null, CancellationToken ct = default)
    {
        try
        {
            var query = new List<string> { $"Page={page}", $"PageSize={pageSize}" };
            if (!string.IsNullOrWhiteSpace(status))
                query.Add($"status={Uri.EscapeDataString(status)}");

            var response = await _httpClient.GetAsync($"api/v1/payment/admin/cash-collections?{string.Join("&", query)}", ct);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Failed to fetch admin cash collections: {Status}", response.StatusCode);
                return null;
            }

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<PagedResult<PaymentResponse>>>(cancellationToken: ct);
            return apiResponse?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving admin cash collections");
            return null;
        }
    }

    public async Task<bool> ProcessSettlementAsync(Guid merchantId, ProcessSettlementRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync(
                $"api/v1/payment/admin/settlements/{merchantId}/process", request, ct);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing settlement for merchant {MerchantId}", merchantId);
            return false;
        }
    }

    public async Task<PagedResult<PaymentResponse>?> GetOrderPaymentsAsync(Guid orderId, int page = 1, int pageSize = 20, CancellationToken ct = default)
    {
        try
        {
            var response = await _httpClient.GetAsync(
                $"api/v1/payment/order/{orderId}?Page={page}&PageSize={pageSize}", ct);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Failed to fetch order payments: {Status}", response.StatusCode);
                return null;
            }

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<PagedResult<PaymentResponse>>>(cancellationToken: ct);
            return apiResponse?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving payments for order {OrderId}", orderId);
            return null;
        }
    }

    public async Task<PaymentResponse?> CreatePaymentAsync(CreatePaymentRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync("api/v1/payment", request, ct);
            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync(ct);
                _logger.LogWarning("Failed to create payment. Status {Status}, Error {Error}", response.StatusCode, error);
                return null;
            }

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<PaymentResponse>>(cancellationToken: ct);
            return apiResponse?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating payment for order {OrderId}", request.OrderId);
            return null;
        }
    }

    public async Task<PagedResult<PaymentResponse>?> GetPendingCourierPaymentsAsync(int page = 1, int pageSize = 20, CancellationToken ct = default)
    {
        try
        {
            var response = await _httpClient.GetAsync(
                $"api/v1/payment/courier/pending?Page={page}&PageSize={pageSize}", ct);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Failed to fetch pending courier payments: {Status}", response.StatusCode);
                return null;
            }

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<PagedResult<PaymentResponse>>>(cancellationToken: ct);
            return apiResponse?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving pending courier payments");
            return null;
        }
    }

    public async Task<CourierCashSummaryResponse?> GetCourierCashSummaryAsync(DateTime? date = null, CancellationToken ct = default)
    {
        try
        {
            var url = "api/v1/payment/courier/summary";
            if (date.HasValue)
            {
                url += $"?date={date.Value:yyyy-MM-dd}";
            }

            var response = await _httpClient.GetAsync(url, ct);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning("Failed to fetch courier cash summary: {Status}", response.StatusCode);
                return null;
            }

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<CourierCashSummaryResponse>>(cancellationToken: ct);
            return apiResponse?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving courier cash summary");
            return null;
        }
    }

    public async Task<bool> CollectCashPaymentAsync(Guid paymentId, CollectCashPaymentRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _httpClient.PostAsJsonAsync(
                $"api/v1/payment/courier/{paymentId}/collect", request, ct);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error collecting cash payment {PaymentId}", paymentId);
            return false;
        }
    }

    public async Task<bool> FailCashPaymentAsync(Guid paymentId, string reason, CancellationToken ct = default)
    {
        try
        {
            var request = new FailPaymentRequest { Reason = reason };
            var response = await _httpClient.PostAsJsonAsync(
                $"api/v1/payment/courier/{paymentId}/fail", request, ct);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error marking cash payment {PaymentId} as failed", paymentId);
            return false;
        }
    }

    /// <summary>
    /// Ödeme yöntemi dağılımını getir
    /// </summary>
    /// <param name="merchantId">Merchant ID</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Ödeme yöntemi dağılımı</returns>
    public async Task<List<PaymentMethodBreakdownModel>> GetPaymentMethodBreakdownAsync(Guid merchantId, DateTime? startDate = null, DateTime? endDate = null)
    {
        try
        {
            var queryParams = new List<string> { "Page=1", "PageSize=1000" };
            if (startDate.HasValue)
                queryParams.Add($"startDate={startDate:yyyy-MM-dd}");
            if (endDate.HasValue)
                queryParams.Add($"endDate={endDate:yyyy-MM-dd}");

            var query = string.Join("&", queryParams);
            var response = await _httpClient.GetAsync($"api/v1/payment/merchant/{merchantId}/transactions?{query}");

            if (!response.IsSuccessStatusCode)
            {
                return new List<PaymentMethodBreakdownModel>();
            }

            var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<PagedResult<PaymentResponse>>>();
            var payments = apiResponse?.Data?.Items ?? new List<PaymentResponse>();
            var completedPayments = payments.Where(p => p.Status == "Completed").ToList();

            var totalAmount = completedPayments.Sum(p => p.Amount);
            if (totalAmount == 0) return new List<PaymentMethodBreakdownModel>();

            return completedPayments
                .GroupBy(p => p.PaymentMethod)
                .Select(g => new PaymentMethodBreakdownModel
                {
                    Method = g.Key,
                    DisplayName = GetPaymentMethodDisplayName(g.Key),
                    OrderCount = g.Count(),
                    TotalAmount = g.Sum(p => p.Amount),
                    Percentage = (g.Sum(p => p.Amount) / totalAmount) * 100,
                    Color = GetPaymentMethodColor(g.Key)
                })
                .OrderByDescending(x => x.TotalAmount)
                .ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting payment method breakdown");
            return new List<PaymentMethodBreakdownModel>();
        }
    }

    #region Helper Methods

    /// <summary>
    /// Boş mutabakat raporu oluştur
    /// </summary>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Boş mutabakat raporu</returns>
    private SettlementReportModel CreateEmptySettlementReport(DateTime startDate, DateTime endDate)
    {
        return new SettlementReportModel
        {
            StartDate = startDate,
            EndDate = endDate,
            TotalRevenue = 0,
            TotalCommission = 0,
            NetAmount = 0,
            TotalOrders = 0,
            CompletedOrders = 0,
            RevenueByMethod = new Dictionary<string, decimal>(),
            DailyBreakdown = new List<DailySettlementModel>()
        };
    }

    /// <summary>
    /// Boş analiz verileri oluştur
    /// </summary>
    /// <returns>Boş analiz verileri</returns>
    private RevenueAnalyticsModel CreateEmptyAnalytics()
    {
        return new RevenueAnalyticsModel
        {
            StartDate = DateTime.Now.AddDays(-30),
            EndDate = DateTime.Now,
            TotalRevenue = 0,
            DailyRevenue = new List<DailyData>(),
            WeeklyRevenue = new List<WeeklyData>(),
            MonthlyRevenue = new List<MonthlyData>(),
            RevenueTrend = 0,
            PaymentMethodDistribution = new List<BreakdownItem>(),
            RevenueByHour = new List<HourlyData>(),
            TopRevenueDays = new List<DailyData>()
        };
    }

    /// <summary>
    /// Günlük gelir verilerini getir
    /// </summary>
    /// <param name="payments">Ödeme listesi</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Günlük gelir verileri</returns>
    private List<DailyData> GetDailyRevenue(List<PaymentResponse> payments, DateTime startDate, DateTime endDate)
    {
        var dailyData = new List<DailyData>();
        for (var date = startDate.Date; date <= endDate.Date; date = date.AddDays(1))
        {
            var dayRevenue = payments.Where(p => p.CreatedAt.Date == date).Sum(p => p.Amount);
            dailyData.Add(new DailyData { Date = date, Value = dayRevenue });
        }
        return dailyData;
    }

    /// <summary>
    /// Haftalık gelir verilerini getir
    /// </summary>
    /// <param name="payments">Ödeme listesi</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Haftalık gelir verileri</returns>
    private List<WeeklyData> GetWeeklyRevenue(List<PaymentResponse> payments, DateTime startDate, DateTime endDate)
    {
        var weeklyData = new List<WeeklyData>();
        var currentWeek = startDate.Date.AddDays(-(int)startDate.DayOfWeek);
        
        while (currentWeek <= endDate.Date)
        {
            var weekEnd = currentWeek.AddDays(6);
            var weekRevenue = payments.Where(p => p.CreatedAt.Date >= currentWeek && p.CreatedAt.Date <= weekEnd).Sum(p => p.Amount);
            var weekNumber = GetWeekOfYear(currentWeek);
            weeklyData.Add(new WeeklyData { Week = weekNumber, Year = currentWeek.Year, Value = weekRevenue });
            currentWeek = currentWeek.AddDays(7);
        }
        return weeklyData;
    }

    /// <summary>
    /// Aylık gelir verilerini getir
    /// </summary>
    /// <param name="payments">Ödeme listesi</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Aylık gelir verileri</returns>
    private List<MonthlyData> GetMonthlyRevenue(List<PaymentResponse> payments, DateTime startDate, DateTime endDate)
    {
        var monthlyData = new List<MonthlyData>();
        var currentMonth = new DateTime(startDate.Year, startDate.Month, 1);
        
        while (currentMonth <= endDate.Date)
        {
            var monthEnd = currentMonth.AddMonths(1).AddDays(-1);
            var monthRevenue = payments.Where(p => p.CreatedAt.Date >= currentMonth && p.CreatedAt.Date <= monthEnd).Sum(p => p.Amount);
            monthlyData.Add(new MonthlyData { Month = currentMonth.Month, Year = currentMonth.Year, Value = monthRevenue });
            currentMonth = currentMonth.AddMonths(1);
        }
        return monthlyData;
    }

    /// <summary>
    /// Yılın hafta numarasını getir
    /// </summary>
    /// <param name="date">Tarih</param>
    /// <returns>Hafta numarası</returns>
    private int GetWeekOfYear(DateTime date)
    {
        var culture = System.Globalization.CultureInfo.CurrentCulture;
        return culture.Calendar.GetWeekOfYear(date, System.Globalization.CalendarWeekRule.FirstDay, DayOfWeek.Monday);
    }

    /// <summary>
    /// Gelir trendini hesapla
    /// </summary>
    /// <param name="payments">Ödeme listesi</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>Gelir trendi yüzdesi</returns>
    private decimal CalculateRevenueTrend(List<PaymentResponse> payments, DateTime startDate, DateTime endDate)
    {
        var dailyRevenue = GetDailyRevenue(payments, startDate, endDate);
        if (dailyRevenue.Count < 2) return 0;
        
        var firstHalf = dailyRevenue.Take(dailyRevenue.Count / 2).Sum(x => x.Value);
        var secondHalf = dailyRevenue.Skip(dailyRevenue.Count / 2).Sum(x => x.Value);
        
        if (firstHalf == 0) return 0;
        return ((secondHalf - firstHalf) / firstHalf) * 100;
    }

    /// <summary>
    /// Ödeme yöntemi dağılımını getir
    /// </summary>
    /// <param name="payments">Ödeme listesi</param>
    /// <returns>Ödeme yöntemi dağılımı</returns>
    private List<BreakdownItem> GetPaymentMethodDistribution(List<PaymentResponse> payments)
    {
        return payments.GroupBy(p => p.PaymentMethod.ToString())
            .Select(g => new BreakdownItem
            {
                Label = GetPaymentMethodDisplayName(g.Key),
                Value = g.Sum(p => p.Amount),
                Percentage = payments.Any() ? (g.Sum(p => p.Amount) / payments.Sum(p => p.Amount)) * 100 : 0,
                Color = GetPaymentMethodColor(g.Key)
            })
            .OrderByDescending(x => x.Value)
            .ToList();
    }

    /// <summary>
    /// Saatlik gelir verilerini getir
    /// </summary>
    /// <param name="payments">Ödeme listesi</param>
    /// <returns>Saatlik gelir verileri</returns>
    private List<HourlyData> GetRevenueByHour(List<PaymentResponse> payments)
    {
        var hourlyData = new List<HourlyData>();
        for (int hour = 0; hour < 24; hour++)
        {
            var hourRevenue = payments.Where(p => p.CreatedAt.Hour == hour).Sum(p => p.Amount);
            hourlyData.Add(new HourlyData { Hour = hour, Value = hourRevenue });
        }
        return hourlyData;
    }

    /// <summary>
    /// En yüksek gelirli günleri getir
    /// </summary>
    /// <param name="payments">Ödeme listesi</param>
    /// <param name="startDate">Başlangıç tarihi</param>
    /// <param name="endDate">Bitiş tarihi</param>
    /// <returns>En yüksek gelirli günler</returns>
    private List<DailyData> GetTopRevenueDays(List<PaymentResponse> payments, DateTime startDate, DateTime endDate)
    {
        return GetDailyRevenue(payments, startDate, endDate)
            .OrderByDescending(x => x.Value)
            .Take(10)
            .ToList();
    }

    /// <summary>
    /// Ödeme yöntemi görünen adını getir
    /// </summary>
    /// <param name="method">Ödeme yöntemi</param>
    /// <returns>Görünen ad</returns>
    private string GetPaymentMethodDisplayName(string method)
    {
        return method switch
        {
            "Cash" => "Kapıda Nakit",
            "CreditCard" => "Kredi Kartı",
            "VodafonePay" => "Vodafone Pay",
            "BankTransfer" => "Havale/EFT",
            "BkmExpress" => "BKM Express",
            "Papara" => "Papara",
            "QrCode" => "QR Code",
            _ => method
        };
    }

    /// <summary>
    /// Ödeme yöntemi rengini getir
    /// </summary>
    /// <param name="method">Ödeme yöntemi</param>
    /// <returns>Renk kodu</returns>
    private string GetPaymentMethodColor(string method)
    {
        return method switch
        {
            "Cash" => "#28a745",
            "CreditCard" => "#007bff",
            "VodafonePay" => "#e60000",
            "BankTransfer" => "#6c757d",
            "BkmExpress" => "#ffc107",
            "Papara" => "#9c27b0",
            "QrCode" => "#17a2b8",
            _ => "#6c757d"
        };
    }

    #endregion
}
