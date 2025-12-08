-- ================================================================
-- Orders Tablosu ve Bağlı Tüm Tabloların Verilerini Silme Scripti
-- ================================================================
-- Bu script, Orders tablosu ve ona bağlı tüm tabloların verilerini
-- foreign key constraint'lere göre doğru sırayla siler.
-- 
-- DİKKAT: Bu script tüm sipariş verilerini kalıcı olarak siler!
-- Çalıştırmadan önce yedek alın.
-- ================================================================

BEGIN TRANSACTION;

PRINT '===============================================================';
PRINT 'Orders ve Bağlı Tabloların Verilerini Silme İşlemi Başlatılıyor...';
PRINT '===============================================================';
PRINT '';

-- Önce mevcut veri sayılarını göster
PRINT 'Mevcut Veri Sayıları:';
PRINT '  - Orders: ' + CAST((SELECT COUNT(*) FROM Orders) AS VARCHAR);
PRINT '  - OrderItems: ' + CAST((SELECT COUNT(*) FROM OrderItems) AS VARCHAR);
PRINT '  - OrderCouriers: ' + CAST((SELECT COUNT(*) FROM OrderCouriers) AS VARCHAR);
PRINT '  - OrderStatusHistories: ' + CAST((SELECT COUNT(*) FROM OrderStatusHistories) AS VARCHAR);
PRINT '  - DeliveryProofs: ' + CAST((SELECT COUNT(*) FROM DeliveryProofs) AS VARCHAR);
PRINT '  - CourierEarnings: ' + CAST((SELECT COUNT(*) FROM CourierEarnings) AS VARCHAR);
PRINT '  - CustomerNotifications (OrderId ile): ' + CAST((SELECT COUNT(*) FROM CustomerNotifications WHERE OrderId IS NOT NULL) AS VARCHAR);
PRINT '  - CourierNotifications (OrderId ile): ' + CAST((SELECT COUNT(*) FROM CourierNotifications WHERE OrderId IS NOT NULL) AS VARCHAR);
PRINT '  - VendorNotifications (OrderId ile): ' + CAST((SELECT COUNT(*) FROM VendorNotifications WHERE RelatedEntityId IS NOT NULL AND Type IN ('NewOrder', 'OrderStatusChanged', 'OrderCancelled', 'OrderDelivered')) AS VARCHAR);
PRINT '';
PRINT 'Silme işlemi başlatılıyor...';
PRINT '';

-- 1. CourierEarnings (Restrict delete - önce silinmeli)
PRINT 'CourierEarnings siliniyor...';
DELETE FROM CourierEarnings
WHERE OrderId IN (SELECT Id FROM Orders);
PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' CourierEarning kaydı silindi.';

-- 2. CustomerNotifications (Restrict delete, OrderId nullable)
PRINT 'CustomerNotifications (OrderId ile) siliniyor...';
DELETE FROM CustomerNotifications
WHERE OrderId IS NOT NULL AND OrderId IN (SELECT Id FROM Orders);
PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' CustomerNotification kaydı silindi.';

-- 3. CourierNotifications (OrderId nullable)
PRINT 'CourierNotifications (OrderId ile) siliniyor...';
DELETE FROM CourierNotifications
WHERE OrderId IS NOT NULL AND OrderId IN (SELECT Id FROM Orders);
PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' CourierNotification kaydı silindi.';

-- 4. VendorNotifications (RelatedEntityId nullable, Type kontrolü ile)
-- Not: VendorNotification'da RelatedEntityId OrderId olabilir (Type = 'NewOrder' vb.)
PRINT 'VendorNotifications (OrderId ile) siliniyor...';
DELETE FROM VendorNotifications
WHERE RelatedEntityId IS NOT NULL 
  AND RelatedEntityId IN (SELECT Id FROM Orders)
  AND Type IN ('NewOrder', 'OrderStatusChanged', 'OrderCancelled', 'OrderDelivered');
PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' VendorNotification kaydı silindi.';

-- 5. OrderCouriers (Restrict delete)
PRINT 'OrderCouriers siliniyor...';
DELETE FROM OrderCouriers
WHERE OrderId IN (SELECT Id FROM Orders);
PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' OrderCourier kaydı silindi.';

-- 6. DeliveryProofs (Cascade delete ama önce silelim)
PRINT 'DeliveryProofs siliniyor...';
DELETE FROM DeliveryProofs
WHERE OrderId IN (SELECT Id FROM Orders);
PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' DeliveryProof kaydı silindi.';

-- 7. OrderStatusHistories (Cascade delete ama önce silelim)
PRINT 'OrderStatusHistories siliniyor...';
DELETE FROM OrderStatusHistories
WHERE OrderId IN (SELECT Id FROM Orders);
PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' OrderStatusHistory kaydı silindi.';

-- 8. OrderItems (Cascade delete ama önce silelim)
PRINT 'OrderItems siliniyor...';
DELETE FROM OrderItems
WHERE OrderId IN (SELECT Id FROM Orders);
PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' OrderItem kaydı silindi.';

-- 9. Orders (Son olarak ana tablo)
PRINT 'Orders siliniyor...';
DELETE FROM Orders;
PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' Order kaydı silindi.';

PRINT '';
PRINT '===============================================================';
PRINT 'Tüm Orders ve bağlı veriler başarıyla silindi.';
PRINT '===============================================================';

-- Transaction'ı commit etmek için aşağıdaki satırın yorumunu kaldırın:
-- COMMIT TRANSACTION;

-- Hata durumunda geri almak için:
-- ROLLBACK TRANSACTION;

-- ================================================================
-- Notlar:
-- - Script transaction içinde çalışır, güvenli test için COMMIT'ten önce kontrol edin
-- - VendorNotification silme işleminde Type kontrolü yapıldı
-- - Tüm foreign key constraint'ler göz önünde bulunduruldu
-- ================================================================

