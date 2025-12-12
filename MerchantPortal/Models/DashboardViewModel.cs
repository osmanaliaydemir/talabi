using System.Collections.Generic;

namespace Getir.MerchantPortal.Models;

public class DashboardViewModel
{
    public MerchantDashboardStats? Stats { get; set; }
    public MerchantPerformanceMetrics? Performance { get; set; }
    public List<RecentOrderResponse> RecentOrders { get; set; } = new();
    public List<TopProductResponse> TopProducts { get; set; } = new();
    public StockSummaryResponse? StockSummary { get; set; }
}

