# Merchant Portal – API Entegrasyon Yol Haritası (Güncel)

Kaynak: `analysis/endpoint-analysis.json` (2025-11-09) çıktısındaki kalan `missingInPortal` uçları. Sprintler ~1 hafta.

## Sprint 4 – Operasyonel İzleme

- [x] **Realtime Tracking Tamamlanması**
  - `GET api/RealtimeTracking/{trackingId}` / `IsTrackingActive`
  - ETA & metrik uçları: `GetCurrentETA`, `GetTrackingMetrics`, `GetETAHistory`
  - Konum geçmişi: `GetLocationHistory`, `GetTrackingEvents`
  - Bildirim yönetimi: `GetNotificationsByTrackingId`, `DeleteNotification`
  - Ayarlar: `GetMerchantSettings`, `DeleteMerchantSettings`, `GetUserSettings`
- [x] **Realtime Bildirim & UI**
  - Portal modülü için canlı takip panelleri, websocket/polling kararını al.
  - Manuel durum/konum güncelleme yetkileri (`UpdateStatus`, `UpdateLocation`).

## Sprint 5 – Rate Limit ve Uluslararasılaştırma

- [ ] **Rate Limit Yönetim Stüdyosu**
  - Kural CRUD: `GetAllRules`, `CreateRule`, `UpdateRule`, `DeleteRule`
  - Konfigürasyon uçları: `GetAllConfigurations`, `CreateConfiguration`, `DeleteConfiguration`
  - Gözlemleme: `GetDashboardData`, `GetStatistics`, `GetEndpointStatistics`, `GetRealTimeLogs`, `GetRecentLogs`, `SearchLogs`
- [ ] **Internationalization Admin Derinleştirme**
  - Dil CRUD: `GetAllLanguages`, `CreateLanguage`, `UpdateLanguage`, `DeleteLanguage`
  - Çeviri yönetimi: `GetTranslation`, `GetTranslationsByCategory`, `ExportTranslations`, `ImportTranslations`
  - Kullanıcı dil tercihleri: `GetUserLanguagePreferences`, `SetUserLanguagePreference`, `RemoveUserLanguagePreference`

## Sprint 6 – Güvenlik & Platform Yönetimi

- [x] **Audit Logging Merkezi**
  - Raporlama: `GetLogAnalysisReports`, `GenerateAuditLogAnalytics`, `ExportReport`
  - Güvenlik olayları: `GetSecurityEventLogs`, `GetHighRiskSecurityEvents`
  - Temizlik: `DeleteExpiredReports`, `DeleteOldSecurityEventLogs`, `DeleteOldUserActivityLogs`
- [x] **Platform Admin Paneli**
  - Dashboard & metrikler: `GetDashboard`, `GetPerformanceMetrics`, `GetRevenueTrendData`
  - Merchant başvuruları: `GetMerchantApplications`, `GetMerchantApplicationDetails`, `ApproveMerchantApplication`
  - Sistem bildirimleri: `GetSystemNotifications`, `CreateNotification`, `DeleteNotification`

## Sprint 7 – Dağıtım Optimizasyonu & Finansal Güvenlik

- [ ] **Delivery Optimization**
  - Kapasite yönetimi: `GetCapacity`, `AdjustCapacity`, `ResetDailyCounters`, `ResetWeeklyCounters`
  - Rota optimizasyonu: `OptimizeMultiPointRoute`, `SelectBestRoute`, `AnalyzeRoutePerformance`, `GetRouteHistory`
- [ ] **Cash Payment Güvenlik & Denetim**
  - Güvenlik uçları: `GetAnomalyAlerts`, `EscalateIncident`, `ResolveIncident`
  - Denetim raporları: `GetCashAuditSummaries`, `CreateAuditReport`, `CloseAuditReport`

## Sprint 8 – Kullanıcı Self-Service & Geo Analytics

- [x] **User Self-Service**
  - Profil & tercih yönetimi: `GetProfile`, `UpdateProfile`, `GetNotificationPreferences`, `UpdateNotificationPreferences`, `GetLanguage`, `SetLanguage`
  - Sipariş geçmişi: `GetUserOrders`, `GetOrderDetails`, `GetOrderTimeline`
  - Favoriler & adresler: `GetFavorites`, `AddToFavorites`, `RemoveFromFavorites`, `GetUserAddresses`, `CreateAddress`, `DeleteAddress`
- [x] **Geo / Lokal Analitik**
  - `GeoLocation` metrikleri: `GetHeatmapData`, `GetCoverageGaps`, `GetDeliveryTimeMatrix`
  - Merchant bölge konfigürasyonu: `GetServiceAreas`, `UpdateServiceArea`, `DeleteServiceArea`

## Teknik İlkeler

- Her sprint sonunda EndpointAnalyzer yeniden çalıştırılarak kalan açık uçlar doğrulanmalı.
- Servis katmanı → Controller → View zincirinde istisna yönetimi ve yetkilendirme testleri eklenmeli.
- Yeni modüller için lokalizasyon (TR/EN/AR) ve rol bazlı görünürlük kontrolleri tamamlanmalı.
- Portal kapsamı dışında kalması netleşen uçlar `docs/UNUSED_API_ENDPOINTS_ANALYSIS.md` altına taşınmalı.
