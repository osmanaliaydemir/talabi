using System;

namespace Talabi.Core.DTOs.Courier;

public class CourierEarningDto
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public decimal BaseDeliveryFee { get; set; }
    public decimal DistanceBonus { get; set; }
    public decimal TipAmount { get; set; }
    public decimal TotalEarning { get; set; }
    public DateTime EarnedAt { get; set; }
    public bool IsPaid { get; set; }
}

public class EarningsSummaryDto
{
    public decimal TotalEarnings { get; set; }
    public int TotalDeliveries { get; set; }
    public decimal AverageEarningPerDelivery { get; set; }
    public List<CourierEarningDto> Earnings { get; set; } = new();
}
