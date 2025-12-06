-- Adım 1: AddPromotionalBanners migration'ını history'ye ekle
-- Bu script'i önce çalıştırın

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

