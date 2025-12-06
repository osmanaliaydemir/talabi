-- Mevcut durumu kontrol et
-- Bu script'i çalıştırarak hangi kolonların ve index'lerin mevcut olduğunu görebilirsiniz

-- Vendors tablosu kolonlarını kontrol et
SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.is_nullable AS IsNullable,
    c.default_object_id AS HasDefault
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Vendors')
    AND c.name IN ('Type')
ORDER BY c.name;

-- Categories tablosu kolonlarını kontrol et
SELECT 
    c.name AS ColumnName,
    t.name AS DataType,
    c.is_nullable AS IsNullable,
    c.default_object_id AS HasDefault
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('Categories')
    AND c.name IN ('VendorType')
ORDER BY c.name;

-- Index'leri kontrol et
SELECT 
    i.name AS IndexName,
    OBJECT_NAME(i.object_id) AS TableName,
    STRING_AGG(c.name, ', ') AS ColumnNames
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.name IN ('IX_Vendors_Type', 'IX_Categories_VendorType')
GROUP BY i.name, OBJECT_NAME(i.object_id);

-- Migration history'yi kontrol et
SELECT [MigrationId], [ProductVersion]
FROM [__EFMigrationsHistory]
WHERE [MigrationId] IN ('20251202120000_AddPromotionalBanners', '20251205141422_AddVendorType')
ORDER BY [MigrationId];

