-- Talabi Database: Sipariş ve Bağlı Tablolardaki Verileri Silme Scripti
-- Not: Foreign Key kısıtlamaları nedeniyle silme işlemi belirli bir sırada yapılmalıdır.
BEGIN TRANSACTION;
BEGIN TRY
    -- 1. Sipariş Kalemlerini Sil (Leaf Table)
    PRINT 'OrderItems siliniyor...';
    DELETE FROM [OrderItems];
    -- 2. Sipariş Durum Geçmişini Sil
    PRINT 'OrderStatusHistories siliniyor...';
    DELETE FROM [OrderStatusHistories];
    -- 3. Sipariş-Kurye Atama Kayıtlarını Sil
    PRINT 'OrderCouriers siliniyor...';
    DELETE FROM [OrderCouriers];
    -- 4. Teslimat Kanıtlarını Sil
    PRINT 'DeliveryProofs siliniyor...';
    DELETE FROM [DeliveryProofs];
    -- 5. Kurye Kazanç Kayıtlarını Sil
    PRINT 'CourierEarnings siliniyor...';
    DELETE FROM [CourierEarnings];
    -- 6. Siparişle İlişkili Bildirimleri Sil
    PRINT 'Bildirimler siliniyor...';
    -- Müşteri bildirimleri
    DELETE FROM [CustomerNotifications] WHERE [OrderId] IS NOT NULL;
    -- Kurye bildirimleri
    DELETE FROM [CourierNotifications] WHERE [OrderId] IS NOT NULL;
    -- Satıcı bildirimleri (OrderId RelatedEntityId içinde saklanıyor olabilir)
    DELETE FROM [VendorNotifications] WHERE [Type] IN ('NewOrder', 'OrderCancelled', 'OrderAccepted');
    -- 6.5 Sipariş Değerlendirmelerini Sil
    PRINT 'Reviews siliniyor...';
    DELETE FROM [Reviews];
    -- 7. Ana Sipariş Tablosunu Sil
    PRINT 'Orders siliniyor...';
    DELETE FROM [Orders];
    -- 8. İstatistikleri Sıfırla (Satıcı ve Kurye)
    PRINT 'Kurye istatistikleri sıfırlanıyor...';
    UPDATE [Couriers] SET
        [TotalEarnings] = 0,
        [CurrentDayEarnings] = 0,
        [TotalDeliveries] = 0,
        [AverageRating] = 0,
        [TotalRatings] = 0,
        [CurrentActiveOrders] = 0;
    PRINT 'Satıcı istatistikleri sıfırlanıyor...';
    UPDATE [Vendors] SET
        [Rating] = NULL,
        [RatingCount] = 0;
    -- 9. Opsiyonel: Identity (Auto-increment) değerlerini sıfırla (Gerekirse)
    -- DBCC CHECKIDENT ('Orders', RESEED, 0);
    -- DBCC CHECKIDENT ('OrderItems', RESEED, 0);
    COMMIT TRANSACTION;
    PRINT 'İşlem başarıyla tamamlandı.';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Hata oluştu! İşlemler geri alındı.';
    PRINT ERROR_MESSAGE();
END CATCH;
