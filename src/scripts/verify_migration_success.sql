-- Migration başarısını doğrulama script'i
-- Bu script'i çalıştırarak migration'ın başarıyla uygulandığını doğrulayabilirsiniz

-- 1. Vendors tablosu Type kolonu kontrolü
SELECT 
    'Vendors.Type' AS ColumnInfo,
    c.name AS ColumnName,
    t.name AS DataType,
    c.is_nullable AS IsNullable,
    CASE WHEN dc.name IS NOT NULL THEN 'Yes' ELSE 'No' END AS HasDefault
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
WHERE c.object_id = OBJECT_ID('Vendors')
    AND c.name = 'Type';

-- 2. Categories tablosu VendorType kolonu kontrolü
SELECT 
    'Categories.VendorType' AS ColumnInfo,
    c.name AS ColumnName,
    t.name AS DataType,
    c.is_nullable AS IsNullable,
    CASE WHEN dc.name IS NOT NULL THEN 'Yes' ELSE 'No' END AS HasDefault
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
LEFT JOIN sys.default_constraints dc ON c.default_object_id = dc.object_id
WHERE c.object_id = OBJECT_ID('Categories')
    AND c.name = 'VendorType';

-- 3. Index'ler kontrolü
SELECT 
    i.name AS IndexName,
    OBJECT_NAME(i.object_id) AS TableName,
    STRING_AGG(c.name, ', ') AS ColumnNames
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.name IN ('IX_Vendors_Type', 'IX_Categories_VendorType')
GROUP BY i.name, OBJECT_NAME(i.object_id);

-- 4. Migration history kontrolü
SELECT 
    [MigrationId], 
    [ProductVersion],
    'Migration Applied' AS Status
FROM [__EFMigrationsHistory]
WHERE [MigrationId] IN ('20251202120000_AddPromotionalBanners', '20251205141422_AddVendorType')
ORDER BY [MigrationId];

-- 5. Mevcut veri kontrolü (örnek)
SELECT 
    'Vendors' AS TableName,
    COUNT(*) AS TotalRecords,
    COUNT(CASE WHEN [Type] = 1 THEN 1 END) AS RestaurantCount,
    COUNT(CASE WHEN [Type] = 2 THEN 1 END) AS MarketCount
FROM [Vendors];

SELECT 
    'Categories' AS TableName,
    COUNT(*) AS TotalRecords,
    COUNT(CASE WHEN [VendorType] = 1 THEN 1 END) AS RestaurantCount,
    COUNT(CASE WHEN [VendorType] = 2 THEN 1 END) AS MarketCount
FROM [Categories];

