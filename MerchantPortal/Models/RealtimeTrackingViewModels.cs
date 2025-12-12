using System;
using System.Collections.Generic;

namespace Getir.MerchantPortal.Models;

public class RealtimeTrackingViewModel
{
    public List<OrderTrackingResponse> ActiveTrackings { get; set; } = new();
    public OrderTrackingResponse? SelectedTracking { get; set; }
    public List<TrackingNotificationResponse> Notifications { get; set; } = new();
    public TrackingEtaResponse? CurrentEta { get; set; }
    public List<TrackingEtaResponse> EtaHistory { get; set; } = new();
    public Dictionary<string, object> Metrics { get; set; } = new(StringComparer.OrdinalIgnoreCase);
    public List<LocationHistoryResponse> LocationHistory { get; set; } = new();
    public TrackingSettingsResponse? MerchantSettings { get; set; }
    public TrackingSettingsResponse? UserSettings { get; set; }
    public UpdateTrackingSettingsRequestModel MerchantSettingsForm { get; set; } = new();
    public UpdateTrackingSettingsRequestModel UserSettingsForm { get; set; } = new();
    public bool IsTrackingActive { get; set; }
    public Guid? MerchantId { get; set; }
    public Guid? UserId { get; set; }
}

