-- Migration history'ye AddPromotionalBanners migration'ını ekle
-- Eğer tablo zaten varsa ama migration history'de yoksa bu script'i çalıştır

-- Önce kontrol et, eğer yoksa ekle
IF NOT EXISTS (SELECT 1 FROM [__EFMigrationsHistory] WHERE [MigrationId] = '20251202120000_AddPromotionalBanners')
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES ('20251202120000_AddPromotionalBanners', '9.0.0');
    PRINT 'AddPromotionalBanners migration added to history';
END
ELSE
BEGIN
    PRINT 'AddPromotionalBanners migration already exists in history';
END

