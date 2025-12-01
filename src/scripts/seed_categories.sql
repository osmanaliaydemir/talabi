-- Insert Categories
-- Colors are stored as Hex Strings (ARGB format used in Flutter)
-- We insert into Categories first, then get IDs to insert translations

-- Temporary table to hold category data to ensure we can map IDs correctly
DECLARE @CategoryData TABLE (
    SystemName NVARCHAR(100),
    Icon NVARCHAR(50),
    Color NVARCHAR(20),
    NameTr NVARCHAR(100),
    NameEn NVARCHAR(100),
    NameAr NVARCHAR(100)
);

INSERT INTO @CategoryData (SystemName, Icon, Color, NameTr, NameEn, NameAr) VALUES 
('Yemek', 'restaurant', '0xFFFF5722', 'Yemek', 'Food', 'طعام'),
('Mağazalar', 'store', '0xFF2196F3', 'Mağazalar', 'Stores', 'متاجر'),
('Market', 'shopping_basket', '0xFF4CAF50', 'Market', 'Grocery', 'بقالة'),
('İçecek', 'local_drink', '0xFF9C27B0', 'İçecek', 'Drinks', 'مشروبات'),
('Tatlı', 'cake', '0xFFE91E63', 'Tatlı', 'Desserts', 'حلويات'),
('Elektronik', 'devices', '0xFF3F51B5', 'Elektronik', 'Electronics', 'إلكترونيات'),
('Giyim', 'checkroom', '0xFF009688', 'Giyim', 'Clothing', 'ملابس');

-- Insert Categories if they don't exist
INSERT INTO Categories (Name, Icon, Color, CreatedAt)
SELECT SystemName, Icon, Color, GETUTCDATE()
FROM @CategoryData
WHERE NOT EXISTS (SELECT 1 FROM Categories WHERE Name = SystemName);

-- Insert Translations
-- Turkish
INSERT INTO CategoryTranslations (CategoryId, LanguageCode, Name, CreatedAt)
SELECT c.Id, 'tr', cd.NameTr, GETUTCDATE()
FROM Categories c
JOIN @CategoryData cd ON c.Name = cd.SystemName
WHERE NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = c.Id AND LanguageCode = 'tr');

-- English
INSERT INTO CategoryTranslations (CategoryId, LanguageCode, Name, CreatedAt)
SELECT c.Id, 'en', cd.NameEn, GETUTCDATE()
FROM Categories c
JOIN @CategoryData cd ON c.Name = cd.SystemName
WHERE NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = c.Id AND LanguageCode = 'en');

-- Arabic
INSERT INTO CategoryTranslations (CategoryId, LanguageCode, Name, CreatedAt)
SELECT c.Id, 'ar', cd.NameAr, GETUTCDATE()
FROM Categories c
JOIN @CategoryData cd ON c.Name = cd.SystemName
WHERE NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = c.Id AND LanguageCode = 'ar');

-- Update Products to link to Categories based on string match or keywords
-- This assumes SQL Server syntax (T-SQL)

-- Update 'Yemek' (Food)
UPDATE Products
SET CategoryId = (SELECT Id FROM Categories WHERE Name = 'Yemek')
WHERE CategoryId IS NULL AND (Category LIKE '%Yemek%' OR Category LIKE '%Food%' OR Name LIKE '%Burger%' OR Name LIKE '%Pizza%' OR Name LIKE '%Kebap%' OR Name LIKE '%Döner%');

-- Update 'İçecek' (Drink)
UPDATE Products
SET CategoryId = (SELECT Id FROM Categories WHERE Name = 'İçecek')
WHERE CategoryId IS NULL AND (Category LIKE '%İçecek%' OR Category LIKE '%Drink%' OR Name LIKE '%Cola%' OR Name LIKE '%Su%' OR Name LIKE '%Kahve%' OR Name LIKE '%Ayran%' OR Name LIKE '%Çay%');

-- Update 'Tatlı' (Dessert)
UPDATE Products
SET CategoryId = (SELECT Id FROM Categories WHERE Name = 'Tatlı')
WHERE CategoryId IS NULL AND (Category LIKE '%Tatlı%' OR Category LIKE '%Dessert%' OR Name LIKE '%Baklava%' OR Name LIKE '%Pasta%' OR Name LIKE '%Künefe%' OR Name LIKE '%Sütlaç%');

-- Update 'Market'
UPDATE Products
SET CategoryId = (SELECT Id FROM Categories WHERE Name = 'Market')
WHERE CategoryId IS NULL AND (Category LIKE '%Market%' OR Category LIKE '%Grocery%' OR Name LIKE '%Süt%' OR Name LIKE '%Yumurta%' OR Name LIKE '%Ekmek%');

-- Update 'Mağazalar' (Stores - generic fallback or specific items)
UPDATE Products
SET CategoryId = (SELECT Id FROM Categories WHERE Name = 'Mağazalar')
WHERE CategoryId IS NULL AND (Category LIKE '%Mağaza%' OR Category LIKE '%Store%');

-- Update 'Elektronik'
UPDATE Products
SET CategoryId = (SELECT Id FROM Categories WHERE Name = 'Elektronik')
WHERE CategoryId IS NULL AND (Category LIKE '%Elektronik%' OR Category LIKE '%Electronic%' OR Name LIKE '%Telefon%' OR Name LIKE '%Kulaklık%');

-- Update 'Giyim'
UPDATE Products
SET CategoryId = (SELECT Id FROM Categories WHERE Name = 'Giyim')
WHERE CategoryId IS NULL AND (Category LIKE '%Giyim%' OR Category LIKE '%Clothing%' OR Name LIKE '%Gömlek%' OR Name LIKE '%Pantolon%');
