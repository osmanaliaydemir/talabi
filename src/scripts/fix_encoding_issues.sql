-- Fix Encoding Issues for MARKET data (VendorType = 2)
-- Using N prefix for Unicode string literals to support Turkish characters correctly

-- 1. Fix Categories
UPDATE [Categories]
SET [Name] = N'Meyve & Sebze'
WHERE [VendorType] = 2 AND ([Name] LIKE '%Meyve%' OR [Name] LIKE '%Sebze%');

UPDATE [Categories]
SET [Name] = N'Atıştırmalık'
WHERE [VendorType] = 2 AND ([Name] LIKE '%Atistirmalik%' OR [Name] LIKE '%Atıştırmalık%' OR [Name] LIKE '%Atl?t?rmal?k%');

UPDATE [Categories]
SET [Name] = N'İçecekler'
WHERE [VendorType] = 2 AND ([Name] LIKE '%Icecekler%' OR [Name] LIKE '%ecekle%');

UPDATE [Categories]
SET [Name] = N'Temel Gıda'
WHERE [VendorType] = 2 AND ([Name] LIKE '%Temel Gida%' OR [Name] LIKE '%Temel G?da%');

-- 2. Fix CategoryTranslations
-- Note: Joining with Categories to target only Market categories
UPDATE ct
SET ct.[Name] = N'Meyve & Sebze'
FROM [CategoryTranslations] ct
INNER JOIN [Categories] c ON ct.[CategoryId] = c.[Id]
WHERE c.[VendorType] = 2 AND (ct.[Name] LIKE '%Meyve%' OR ct.[Name] LIKE '%Sebze%');

UPDATE ct
SET ct.[Name] = N'Atıştırmalık'
FROM [CategoryTranslations] ct
INNER JOIN [Categories] c ON ct.[CategoryId] = c.[Id]
WHERE c.[VendorType] = 2 AND (ct.[Name] LIKE '%Atistirmalik%' OR ct.[Name] LIKE '%At%t%rmal%');

UPDATE ct
SET ct.[Name] = N'İçecekler'
FROM [CategoryTranslations] ct
INNER JOIN [Categories] c ON ct.[CategoryId] = c.[Id]
WHERE c.[VendorType] = 2 AND (ct.[Name] LIKE '%Icecekler%' OR ct.[Name] LIKE '%ecekle%');

UPDATE ct
SET ct.[Name] = N'Temel Gıda'
FROM [CategoryTranslations] ct
INNER JOIN [Categories] c ON ct.[CategoryId] = c.[Id]
WHERE c.[VendorType] = 2 AND (ct.[Name] LIKE '%Temel Gida%' OR ct.[Name] LIKE '%Temel G?da%');


-- 3. Fix Vendors
UPDATE [Vendors]
SET 
    [Name] = N'Hızlı Market',
    [Address] = N'Bağdat Caddesi No:123',
    [Description] = N'Taze ve hızlı market alışverişi'
WHERE [Type] = 2 AND ([Name] LIKE '%Hlzll Market%' OR [Name] LIKE '%Hizli Market%' OR [Name] LIKE '%H?zl? Market%');

UPDATE [Vendors]
SET 
    [Name] = N'Mahalle Bakkalı',
    [Address] = N'Moda Caddesi No:45',
    [Description] = N'Mahallenizin dostu'
WHERE [Type] = 2 AND ([Name] LIKE '%Mahalle Bakkali%' OR [Name] LIKE '%Mahalle Bakkal?%');


-- 4. Fix Products
-- Find vendors first to use in subquery or join
DECLARE @VendorId1 UNIQUEIDENTIFIER = (SELECT TOP 1 [Id] FROM [Vendors] WHERE [Type] = 2 AND ([Name] LIKE N'%Hızlı Market%' OR [Name] LIKE '%Hizli Market%' OR [Name] LIKE '%H?zl?%'));
DECLARE @VendorId2 UNIQUEIDENTIFIER = (SELECT TOP 1 [Id] FROM [Vendors] WHERE [Type] = 2 AND ([Name] LIKE N'%Mahalle Bakkalı%' OR [Name] LIKE '%Mahalle Bakkali%' OR [Name] LIKE '%Mahalle Bakkal?%'));

IF @VendorId1 IS NOT NULL
BEGIN
    UPDATE [Products] SET [Name] = N'Salkım Domates', [Description] = N'Salkım Domates Kg' WHERE [VendorId] = @VendorId1 AND [Name] LIKE '%Domates%';
    UPDATE [Products] SET [Name] = N'Süt', [Description] = N'Tam Yağlı Süt 1L' WHERE [VendorId] = @VendorId1 AND ([Name] LIKE 'Sut' OR [Name] LIKE 'S?t');
    UPDATE [Products] SET [Name] = N'Yumurta', [Description] = N'15li L Boy Yumurta' WHERE [VendorId] = @VendorId1 AND [Name] LIKE 'Yumurta';
END

IF @VendorId2 IS NOT NULL
BEGIN
    UPDATE [Products] SET [Description] = N'Baharatlı Cips Büyük Boy' WHERE [VendorId] = @VendorId2 AND [Name] LIKE 'Cips';
    UPDATE [Products] SET [Name] = N'Kola', [Description] = N'Şekersiz Kola 1L' WHERE [VendorId] = @VendorId2 AND [Name] LIKE 'Kola';
    UPDATE [Products] SET [Description] = N'Odun Ekmeği' WHERE [VendorId] = @VendorId2 AND [Name] LIKE 'Ekmek';
END


-- 5. Fix Promotional Banners
UPDATE [PromotionalBanners]
SET 
    [Title] = N'Taze Meyve Şenliği', 
    [Subtitle] = N'Haftanın taze meyvelerinde %20 indirim!'
WHERE [VendorType] = 2 AND ([Title] LIKE '%Meyve%' OR [Title] LIKE '%?enli?i%');

UPDATE [PromotionalBanners]
SET 
    [Title] = N'Hızlı Teslimat', 
    [Subtitle] = N'Market siparişleriniz 30 dakikada kapınızda',
    [ButtonText] = N'Göz At'
WHERE [VendorType] = 2 AND ([Title] LIKE '%Hlzll Teslimat%' OR [Title] LIKE '%Hizli Teslimat%');

-- 6. Fix Promotional Banner Translations
UPDATE pbt
SET 
    pbt.[Title] = N'Taze Meyve Şenliği', 
    pbt.[Subtitle] = N'Haftanın taze meyvelerinde %20 indirim!'
FROM [PromotionalBannerTranslations] pbt
INNER JOIN [PromotionalBanners] pb ON pbt.[PromotionalBannerId] = pb.[Id]
WHERE pb.[VendorType] = 2 AND (pbt.[Title] LIKE '%Meyve%' OR pbt.[Title] LIKE '%?enli?i%');

UPDATE pbt
SET 
    pbt.[Title] = N'Hızlı Teslimat', 
    pbt.[Subtitle] = N'Market siparişleriniz 30 dakikada kapınızda',
    pbt.[ButtonText] = N'Göz At'
FROM [PromotionalBannerTranslations] pbt
INNER JOIN [PromotionalBanners] pb ON pbt.[PromotionalBannerId] = pb.[Id]
WHERE pb.[VendorType] = 2 AND (pbt.[Title] LIKE '%Hlzll Teslimat%' OR pbt.[Title] LIKE '%Hizli Teslimat%');

PRINT 'Turkish characters updated successfully.';
