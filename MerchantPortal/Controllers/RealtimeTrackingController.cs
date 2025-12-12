using System;
using System.Collections.Generic;
using Getir.MerchantPortal.Models;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Getir.MerchantPortal.Controllers;

[Authorize(Roles = "Admin,MerchantOwner")]
public class RealtimeTrackingController : Controller
{
    private readonly IRealtimeTrackingPortalService _realtimeTrackingService;
    private readonly ILocalizationService _localizationService;

    public RealtimeTrackingController(
        IRealtimeTrackingPortalService realtimeTrackingService,
        ILocalizationService localizationService)
    {
        _realtimeTrackingService = realtimeTrackingService;
        _localizationService = localizationService;
    }

    [HttpGet]
    public async Task<IActionResult> Index(Guid? trackingId = null, Guid? orderId = null)
    {
        var active = await _realtimeTrackingService.GetActiveTrackingsAsync();

        OrderTrackingResponse? selected = null;
        if (trackingId.HasValue)
        {
            selected = await _realtimeTrackingService.GetTrackingByIdAsync(trackingId.Value);
        }
        else if (orderId.HasValue)
        {
            selected = await _realtimeTrackingService.GetTrackingByOrderIdAsync(orderId.Value);
        }
        else
        {
            selected = active.FirstOrDefault();
        }

        List<TrackingNotificationResponse> notifications = new();
        TrackingEtaResponse? currentEta = null;
        List<TrackingEtaResponse> etaHistory = new();
        Dictionary<string, object> metrics = new(StringComparer.OrdinalIgnoreCase);
        List<LocationHistoryResponse> locationHistory = new();
        bool isTrackingActive = false;

        if (selected != null)
        {
            notifications = await _realtimeTrackingService.GetNotificationsAsync(selected.Id);
            currentEta = await _realtimeTrackingService.GetCurrentEtaAsync(selected.Id);
            etaHistory = await _realtimeTrackingService.GetEtaHistoryAsync(selected.Id);
            metrics = await _realtimeTrackingService.GetTrackingMetricsAsync(selected.Id);
            locationHistory = await _realtimeTrackingService.GetLocationHistoryAsync(selected.Id);
            isTrackingActive = await _realtimeTrackingService.IsTrackingActiveAsync(selected.Id);
        }

        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        Guid? merchantId = Guid.TryParse(merchantIdStr, out var parsedMerchantId) ? parsedMerchantId : null;

        var userIdStr = HttpContext.Session.GetString("UserId");
        Guid? userId = Guid.TryParse(userIdStr, out var parsedUserId) ? parsedUserId : null;

        TrackingSettingsResponse? merchantSettings = null;
        TrackingSettingsResponse? userSettings = null;

        if (merchantId.HasValue)
        {
            merchantSettings = await _realtimeTrackingService.GetMerchantSettingsAsync(merchantId.Value);
        }

        if (userId.HasValue)
        {
            userSettings = await _realtimeTrackingService.GetUserSettingsAsync(userId.Value);
        }

        var viewModel = new RealtimeTrackingViewModel
        {
            ActiveTrackings = active,
            SelectedTracking = selected,
            Notifications = notifications,
            CurrentEta = currentEta,
            EtaHistory = etaHistory,
            Metrics = metrics,
            LocationHistory = locationHistory,
            IsTrackingActive = isTrackingActive,
            MerchantSettings = merchantSettings,
            UserSettings = userSettings,
            MerchantSettingsForm = merchantSettings != null ? MapToSettingsRequest(merchantSettings) : BuildDefaultSettingsRequest(),
            UserSettingsForm = userSettings != null ? MapToSettingsRequest(userSettings) : BuildDefaultSettingsRequest(),
            MerchantId = merchantId,
            UserId = userId
        };

        ViewBag.Title = _localizationService.GetString("RealtimeTracking");

        return View(viewModel);
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateStatus(StatusUpdateRequestModel request)
    {
        if (request.OrderTrackingId == Guid.Empty)
        {
            TempData["Error"] = _localizationService.GetString("TrackingInvalidTracking");
            return RedirectToAction(nameof(Index));
        }

        var success = await _realtimeTrackingService.UpdateStatusAsync(request);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("TrackingStatusUpdated")
            : _localizationService.GetString("TrackingStatusUpdateFailed");

        return RedirectToAction(nameof(Index), new { trackingId = request.OrderTrackingId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> UpdateLocation(LocationUpdateRequestModel request)
    {
        if (request.OrderTrackingId == Guid.Empty)
        {
            TempData["Error"] = _localizationService.GetString("TrackingInvalidTracking");
            return RedirectToAction(nameof(Index));
        }

        var success = await _realtimeTrackingService.UpdateLocationAsync(request);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("TrackingLocationUpdated")
            : _localizationService.GetString("TrackingLocationUpdateFailed");

        return RedirectToAction(nameof(Index), new { trackingId = request.OrderTrackingId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> MarkNotificationRead(Guid notificationId, Guid trackingId)
    {
        if (notificationId == Guid.Empty)
        {
            TempData["Error"] = _localizationService.GetString("TrackingNotificationNotFound");
            return RedirectToAction(nameof(Index), new { trackingId });
        }

        var success = await _realtimeTrackingService.MarkNotificationAsReadAsync(notificationId);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("TrackingNotificationMarkedRead")
            : _localizationService.GetString("TrackingNotificationMarkReadFailed");

        return RedirectToAction(nameof(Index), new { trackingId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteNotification(Guid notificationId, Guid trackingId)
    {
        if (notificationId == Guid.Empty)
        {
            TempData["Error"] = _localizationService.GetString("TrackingNotificationNotFound");
            return RedirectToAction(nameof(Index), new { trackingId });
        }

        var success = await _realtimeTrackingService.DeleteNotificationAsync(notificationId);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("TrackingNotificationDeleted")
            : _localizationService.GetString("TrackingNotificationDeleteFailed");

        return RedirectToAction(nameof(Index), new { trackingId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SaveMerchantSettings(UpdateTrackingSettingsRequestModel request, Guid trackingId, bool isUpdate = false)
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (!Guid.TryParse(merchantIdStr, out var merchantId))
        {
            TempData["Error"] = _localizationService.GetString("MerchantContextNotFound");
            return RedirectToAction(nameof(Index), new { trackingId });
        }

        var settings = await _realtimeTrackingService.SaveMerchantSettingsAsync(merchantId, request, isUpdate);
        TempData[settings != null ? "Success" : "Error"] = settings != null
            ? _localizationService.GetString("MerchantSettingsUpdated")
            : _localizationService.GetString("MerchantSettingsUpdateFailed");

        return RedirectToAction(nameof(Index), new { trackingId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteMerchantSettings(Guid trackingId)
    {
        var merchantIdStr = HttpContext.Session.GetString("MerchantId");
        if (!Guid.TryParse(merchantIdStr, out var merchantId))
        {
            TempData["Error"] = _localizationService.GetString("MerchantContextNotFound");
            return RedirectToAction(nameof(Index), new { trackingId });
        }

        var success = await _realtimeTrackingService.DeleteMerchantSettingsAsync(merchantId);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("MerchantSettingsDeleted")
            : _localizationService.GetString("MerchantSettingsDeleteFailed");

        return RedirectToAction(nameof(Index), new { trackingId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> SaveUserSettings(UpdateTrackingSettingsRequestModel request, Guid trackingId, bool isUpdate = false)
    {
        var userIdStr = HttpContext.Session.GetString("UserId");
        if (!Guid.TryParse(userIdStr, out var userId))
        {
            TempData["Error"] = _localizationService.GetString("UserContextNotFound");
            return RedirectToAction(nameof(Index), new { trackingId });
        }

        var settings = await _realtimeTrackingService.SaveUserSettingsAsync(userId, request, isUpdate);
        TempData[settings != null ? "Success" : "Error"] = settings != null
            ? _localizationService.GetString("UserSettingsUpdated")
            : _localizationService.GetString("UserSettingsUpdateFailed");

        return RedirectToAction(nameof(Index), new { trackingId });
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteUserSettings(Guid trackingId)
    {
        var userIdStr = HttpContext.Session.GetString("UserId");
        if (!Guid.TryParse(userIdStr, out var userId))
        {
            TempData["Error"] = _localizationService.GetString("UserContextNotFound");
            return RedirectToAction(nameof(Index), new { trackingId });
        }

        var success = await _realtimeTrackingService.DeleteUserSettingsAsync(userId);
        TempData[success ? "Success" : "Error"] = success
            ? _localizationService.GetString("UserSettingsDeleted")
            : _localizationService.GetString("UserSettingsDeleteFailed");

        return RedirectToAction(nameof(Index), new { trackingId });
    }

    private static UpdateTrackingSettingsRequestModel MapToSettingsRequest(TrackingSettingsResponse settings)
    {
        return new UpdateTrackingSettingsRequestModel
        {
            EnableLocationTracking = settings.EnableLocationTracking,
            EnablePushNotifications = settings.EnablePushNotifications,
            EnableSMSNotifications = settings.EnableSMSNotifications,
            EnableEmailNotifications = settings.EnableEmailNotifications,
            LocationUpdateInterval = settings.LocationUpdateInterval,
            NotificationInterval = settings.NotificationInterval,
            LocationAccuracyThreshold = settings.LocationAccuracyThreshold,
            EnableETAUpdates = settings.EnableETAUpdates,
            ETAUpdateInterval = settings.ETAUpdateInterval,
            EnableDelayAlerts = settings.EnableDelayAlerts,
            DelayThresholdMinutes = settings.DelayThresholdMinutes,
            EnableNearbyAlerts = settings.EnableNearbyAlerts,
            NearbyDistanceMeters = settings.NearbyDistanceMeters,
            PreferredLanguage = settings.PreferredLanguage,
            TimeZone = settings.TimeZone
        };
    }

    private static UpdateTrackingSettingsRequestModel BuildDefaultSettingsRequest()
    {
        return new UpdateTrackingSettingsRequestModel
        {
            EnableLocationTracking = true,
            EnablePushNotifications = true,
            EnableSMSNotifications = false,
            EnableEmailNotifications = false,
            LocationUpdateInterval = 2,
            NotificationInterval = 5,
            LocationAccuracyThreshold = 50,
            EnableETAUpdates = true,
            ETAUpdateInterval = 5,
            EnableDelayAlerts = true,
            DelayThresholdMinutes = 10,
            EnableNearbyAlerts = true,
            NearbyDistanceMeters = 250,
            PreferredLanguage = null,
            TimeZone = null
        };
    }
}

