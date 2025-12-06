-- Tablo semalarını kontrol et
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType
FROM sys.tables t
INNER JOIN sys.columns c ON t.object_id = c.object_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE t.name IN ('Products', 'Categories', 'Vendors', 'PromotionalBanners')
ORDER BY t.name, c.name;
