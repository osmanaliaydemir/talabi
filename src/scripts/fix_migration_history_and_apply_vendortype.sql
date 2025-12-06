-- Migration history düzeltme ve VendorType migration'ını uygulama script'i
-- Bu script'i SQL Server Management Studio veya Azure Data Studio'da çalıştırın

-- 1. AddPromotionalBanners migration'ını history'ye ekle (eğer yoksa)
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

-- 2. AddVendorType migration'ını manuel olarak uygula (eğer henüz uygulanmadıysa)
IF NOT EXISTS (SELECT 1 FROM [__EFMigrationsHistory] WHERE [MigrationId] = '20251205141422_AddVendorType')
BEGIN
    PRINT 'Applying AddVendorType migration...';
    
    -- Vendors tablosuna Type kolonu ekle (nullable)
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Vendors') AND name = 'Type')
    BEGIN
        ALTER TABLE [Vendors] ADD [Type] int NULL;
        PRINT 'Type column added to Vendors table';
    END
    
    -- Mevcut vendor'ları Restaurant (1) olarak güncelle (sadece kolon varsa)
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Vendors') AND name = 'Type')
    BEGIN
        UPDATE [Vendors] SET [Type] = 1 WHERE [Type] IS NULL;
        PRINT 'Existing vendors updated to Restaurant (1)';
        
        -- Type kolonunu NOT NULL yap
        ALTER TABLE [Vendors] ALTER COLUMN [Type] int NOT NULL;
        -- Default constraint ekle
        IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('Vendors') AND name LIKE 'DF__Vendors__Type%')
        BEGIN
            ALTER TABLE [Vendors] ADD DEFAULT 1 FOR [Type];
        END
        PRINT 'Type column set to NOT NULL with default value 1';
    END
    
    -- Categories tablosuna VendorType kolonu ekle (nullable)
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Categories') AND name = 'VendorType')
    BEGIN
        ALTER TABLE [Categories] ADD [VendorType] int NULL;
        PRINT 'VendorType column added to Categories table';
    END
    
    -- Mevcut category'leri Restaurant (1) olarak güncelle (sadece kolon varsa)
    IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Categories') AND name = 'VendorType')
    BEGIN
        UPDATE [Categories] SET [VendorType] = 1 WHERE [VendorType] IS NULL;
        PRINT 'Existing categories updated to Restaurant (1)';
        
        -- VendorType kolonunu NOT NULL yap
        ALTER TABLE [Categories] ALTER COLUMN [VendorType] int NOT NULL;
        -- Default constraint ekle
        IF NOT EXISTS (SELECT 1 FROM sys.default_constraints WHERE parent_object_id = OBJECT_ID('Categories') AND name LIKE 'DF__Categories__VendorType%')
        BEGIN
            ALTER TABLE [Categories] ADD DEFAULT 1 FOR [VendorType];
        END
        PRINT 'VendorType column set to NOT NULL with default value 1';
    END
    
    -- Index'leri oluştur
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Vendors_Type' AND object_id = OBJECT_ID('Vendors'))
    BEGIN
        CREATE INDEX [IX_Vendors_Type] ON [Vendors] ([Type]);
        PRINT 'Index IX_Vendors_Type created';
    END
    
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Categories_VendorType' AND object_id = OBJECT_ID('Categories'))
    BEGIN
        CREATE INDEX [IX_Categories_VendorType] ON [Categories] ([VendorType]);
        PRINT 'Index IX_Categories_VendorType created';
    END
    
    -- Migration history'ye ekle
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES ('20251205141422_AddVendorType', '9.0.0');
    PRINT 'AddVendorType migration added to history';
    PRINT 'Migration completed successfully!';
END
ELSE
BEGIN
    PRINT 'AddVendorType migration already exists in history';
END

