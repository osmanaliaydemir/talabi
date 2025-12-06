-- Migration history düzeltme ve VendorType migration'ını uygulama script'i (V2 - Basitleştirilmiş)
-- Bu script'i SQL Server Management Studio veya Azure Data Studio'da çalıştırın

BEGIN TRANSACTION;

BEGIN TRY
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
        
        -- ============================================
        -- VENDORS TABLOSU - Type kolonu
        -- ============================================
        
        -- Vendors tablosuna Type kolonu ekle (nullable)
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Vendors') AND name = 'Type')
        BEGIN
            ALTER TABLE [Vendors] ADD [Type] int NULL;
            PRINT 'Type column added to Vendors table (nullable)';
        END
        ELSE
        BEGIN
            PRINT 'Type column already exists in Vendors table';
        END
        
        -- Mevcut vendor'ları Restaurant (1) olarak güncelle
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Vendors') AND name = 'Type')
        BEGIN
            UPDATE [Vendors] SET [Type] = 1 WHERE [Type] IS NULL;
            PRINT 'Existing vendors updated to Restaurant (1)';
        END
        
        -- Type kolonunu NOT NULL yap
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Vendors') AND name = 'Type' AND is_nullable = 1)
        BEGIN
            ALTER TABLE [Vendors] ALTER COLUMN [Type] int NOT NULL;
            PRINT 'Type column set to NOT NULL';
        END
        
        -- Default constraint ekle (eğer yoksa)
        IF NOT EXISTS (
            SELECT 1 
            FROM sys.default_constraints dc
            INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
            WHERE c.object_id = OBJECT_ID('Vendors') 
                AND c.name = 'Type'
        )
        BEGIN
            ALTER TABLE [Vendors] ADD CONSTRAINT [DF_Vendors_Type] DEFAULT 1 FOR [Type];
            PRINT 'Default constraint added to Type column';
        END
        
        -- ============================================
        -- CATEGORIES TABLOSU - VendorType kolonu
        -- ============================================
        
        -- Categories tablosuna VendorType kolonu ekle (nullable)
        IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Categories') AND name = 'VendorType')
        BEGIN
            ALTER TABLE [Categories] ADD [VendorType] int NULL;
            PRINT 'VendorType column added to Categories table (nullable)';
        END
        ELSE
        BEGIN
            PRINT 'VendorType column already exists in Categories table';
        END
        
        -- Mevcut category'leri Restaurant (1) olarak güncelle
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Categories') AND name = 'VendorType')
        BEGIN
            UPDATE [Categories] SET [VendorType] = 1 WHERE [VendorType] IS NULL;
            PRINT 'Existing categories updated to Restaurant (1)';
        END
        
        -- VendorType kolonunu NOT NULL yap
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Categories') AND name = 'VendorType' AND is_nullable = 1)
        BEGIN
            ALTER TABLE [Categories] ALTER COLUMN [VendorType] int NOT NULL;
            PRINT 'VendorType column set to NOT NULL';
        END
        
        -- Default constraint ekle (eğer yoksa)
        IF NOT EXISTS (
            SELECT 1 
            FROM sys.default_constraints dc
            INNER JOIN sys.columns c ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
            WHERE c.object_id = OBJECT_ID('Categories') 
                AND c.name = 'VendorType'
        )
        BEGIN
            ALTER TABLE [Categories] ADD CONSTRAINT [DF_Categories_VendorType] DEFAULT 1 FOR [VendorType];
            PRINT 'Default constraint added to VendorType column';
        END
        
        -- ============================================
        -- INDEX'LER
        -- ============================================
        
        -- IX_Vendors_Type index'ini oluştur
        IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Vendors_Type' AND object_id = OBJECT_ID('Vendors'))
        BEGIN
            CREATE INDEX [IX_Vendors_Type] ON [Vendors] ([Type]);
            PRINT 'Index IX_Vendors_Type created';
        END
        ELSE
        BEGIN
            PRINT 'Index IX_Vendors_Type already exists';
        END
        
        -- IX_Categories_VendorType index'ini oluştur
        IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Categories_VendorType' AND object_id = OBJECT_ID('Categories'))
        BEGIN
            CREATE INDEX [IX_Categories_VendorType] ON [Categories] ([VendorType]);
            PRINT 'Index IX_Categories_VendorType created';
        END
        ELSE
        BEGIN
            PRINT 'Index IX_Categories_VendorType already exists';
        END
        
        -- ============================================
        -- MIGRATION HISTORY
        -- ============================================
        
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

    COMMIT TRANSACTION;
    PRINT 'Transaction committed successfully!';
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    PRINT 'Transaction rolled back due to error:';
    PRINT ERROR_MESSAGE();
    PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
    PRINT 'Error Line: ' + CAST(ERROR_LINE() AS VARCHAR(10));
    THROW;
END CATCH;

