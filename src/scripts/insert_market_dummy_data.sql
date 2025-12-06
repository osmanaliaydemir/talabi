-- Market Dummy Data Script
-- VendorType: 2 (Market)
-- Target Database: Remote (db29009)
-- Updated to check for existing records (Idempotent)

DECLARE @MarketVendorId1 UNIQUEIDENTIFIER;
DECLARE @MarketVendorId2 UNIQUEIDENTIFIER;

-- Categories Variables
DECLARE @CatId_MeyveSebze UNIQUEIDENTIFIER;
DECLARE @CatId_Atistirmalik UNIQUEIDENTIFIER;
DECLARE @CatId_Icecekler UNIQUEIDENTIFIER;
DECLARE @CatId_TemelGida UNIQUEIDENTIFIER;
DECLARE @CatId_Sarkuteri UNIQUEIDENTIFIER;
DECLARE @CatId_EtTavukBalik UNIQUEIDENTIFIER;
DECLARE @CatId_FirinPastane UNIQUEIDENTIFIER;
DECLARE @CatId_KisiselBakim UNIQUEIDENTIFIER;
DECLARE @CatId_EvTemizlik UNIQUEIDENTIFIER;
DECLARE @CatId_Dondurma UNIQUEIDENTIFIER;
DECLARE @CatId_BebekCocuk UNIQUEIDENTIFIER;
DECLARE @CatId_EvcilDostlar UNIQUEIDENTIFIER;

DECLARE @Now DATETIME2 = GETUTCDATE();
DECLARE @SystemUserId NVARCHAR(450) = 'system-user-id';

---------------------------------------------------
-- 1. Categories
---------------------------------------------------

-- Meyve & Sebze
SELECT TOP 1 @CatId_MeyveSebze = Id FROM Categories WHERE Name = N'Meyve & Sebze' AND VendorType = 2;
IF @CatId_MeyveSebze IS NULL
BEGIN
    SET @CatId_MeyveSebze = NEWID();
    INSERT INTO [Categories] ([Id], [VendorType], [Name], [Icon], [Color], [ImageUrl], [DisplayOrder], [CreatedAt])
    VALUES (@CatId_MeyveSebze, 2, N'Meyve & Sebze', 'apple', '#4CAF50', 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&q=80&w=500', 1, @Now);
END
-- Translation
IF NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = @CatId_MeyveSebze AND LanguageCode = 'tr')
BEGIN
    INSERT INTO [CategoryTranslations] ([Id], [CategoryId], [LanguageCode], [Name], [CreatedAt])
    VALUES (NEWID(), @CatId_MeyveSebze, 'tr', N'Meyve & Sebze', @Now);
END


-- Atıştırmalık
SELECT TOP 1 @CatId_Atistirmalik = Id FROM Categories WHERE Name = N'Atıştırmalık' AND VendorType = 2;
IF @CatId_Atistirmalik IS NULL
BEGIN
    SET @CatId_Atistirmalik = NEWID();
    INSERT INTO [Categories] ([Id], [VendorType], [Name], [Icon], [Color], [ImageUrl], [DisplayOrder], [CreatedAt])
    VALUES (@CatId_Atistirmalik, 2, N'Atıştırmalık', 'cookie', '#FF9800', 'https://images.unsplash.com/photo-1621939514649-28b12e81658b?auto=format&fit=crop&q=80&w=500', 2, @Now);
END
-- Translation
IF NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = @CatId_Atistirmalik AND LanguageCode = 'tr')
BEGIN
    INSERT INTO [CategoryTranslations] ([Id], [CategoryId], [LanguageCode], [Name], [CreatedAt])
    VALUES (NEWID(), @CatId_Atistirmalik, 'tr', N'Atıştırmalık', @Now);
END


-- İçecekler
SELECT TOP 1 @CatId_Icecekler = Id FROM Categories WHERE Name = N'İçecekler' AND VendorType = 2;
IF @CatId_Icecekler IS NULL
BEGIN
    SET @CatId_Icecekler = NEWID();
    INSERT INTO [Categories] ([Id], [VendorType], [Name], [Icon], [Color], [ImageUrl], [DisplayOrder], [CreatedAt])
    VALUES (@CatId_Icecekler, 2, N'İçecekler', 'local_drink', '#2196F3', 'https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?auto=format&fit=crop&q=80&w=500', 3, @Now);
END
-- Translation
IF NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = @CatId_Icecekler AND LanguageCode = 'tr')
BEGIN
    INSERT INTO [CategoryTranslations] ([Id], [CategoryId], [LanguageCode], [Name], [CreatedAt])
    VALUES (NEWID(), @CatId_Icecekler, 'tr', N'İçecekler', @Now);
END


-- Temel Gıda
SELECT TOP 1 @CatId_TemelGida = Id FROM Categories WHERE Name = N'Temel Gıda' AND VendorType = 2;
IF @CatId_TemelGida IS NULL
BEGIN
    SET @CatId_TemelGida = NEWID();
    INSERT INTO [Categories] ([Id], [VendorType], [Name], [Icon], [Color], [ImageUrl], [DisplayOrder], [CreatedAt])
    VALUES (@CatId_TemelGida, 2, N'Temel Gıda', 'kitchen', '#795548', 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=500', 4, @Now);
END
-- Translation
IF NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = @CatId_TemelGida AND LanguageCode = 'tr')
BEGIN
    INSERT INTO [CategoryTranslations] ([Id], [CategoryId], [LanguageCode], [Name], [CreatedAt])
    VALUES (NEWID(), @CatId_TemelGida, 'tr', N'Temel Gıda', @Now);
END


-- Şarküteri & Kahvaltılık
SELECT TOP 1 @CatId_Sarkuteri = Id FROM Categories WHERE Name = N'Şarküteri & Kahvaltılık' AND VendorType = 2;
IF @CatId_Sarkuteri IS NULL
BEGIN
    SET @CatId_Sarkuteri = NEWID();
    INSERT INTO [Categories] ([Id], [VendorType], [Name], [Icon], [Color], [ImageUrl], [DisplayOrder], [CreatedAt])
    VALUES (@CatId_Sarkuteri, 2, N'Şarküteri & Kahvaltılık', 'lunch_dining', '#FF5722', 'https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?auto=format&fit=crop&q=80&w=500', 5, @Now);
END
-- Translation
IF NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = @CatId_Sarkuteri AND LanguageCode = 'tr')
BEGIN
    INSERT INTO [CategoryTranslations] ([Id], [CategoryId], [LanguageCode], [Name], [CreatedAt])
    VALUES (NEWID(), @CatId_Sarkuteri, 'tr', N'Şarküteri & Kahvaltılık', @Now);
END


-- Et, Tavuk & Balık
SELECT TOP 1 @CatId_EtTavukBalik = Id FROM Categories WHERE Name = N'Et, Tavuk & Balık' AND VendorType = 2;
IF @CatId_EtTavukBalik IS NULL
BEGIN
    SET @CatId_EtTavukBalik = NEWID();
    INSERT INTO [Categories] ([Id], [VendorType], [Name], [Icon], [Color], [ImageUrl], [DisplayOrder], [CreatedAt])
    VALUES (@CatId_EtTavukBalik, 2, N'Et, Tavuk & Balık', 'restaurant', '#D32F2F', 'https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?auto=format&fit=crop&q=80&w=500', 6, @Now);
END
-- Translation
IF NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = @CatId_EtTavukBalik AND LanguageCode = 'tr')
BEGIN
    INSERT INTO [CategoryTranslations] ([Id], [CategoryId], [LanguageCode], [Name], [CreatedAt])
    VALUES (NEWID(), @CatId_EtTavukBalik, 'tr', N'Et, Tavuk & Balık', @Now);
END


-- Fırın & Pastane
SELECT TOP 1 @CatId_FirinPastane = Id FROM Categories WHERE Name = N'Fırın & Pastane' AND VendorType = 2;
IF @CatId_FirinPastane IS NULL
BEGIN
    SET @CatId_FirinPastane = NEWID();
    INSERT INTO [Categories] ([Id], [VendorType], [Name], [Icon], [Color], [ImageUrl], [DisplayOrder], [CreatedAt])
    VALUES (@CatId_FirinPastane, 2, N'Fırın & Pastane', 'bakery_dining', '#FFC107', 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&q=80&w=500', 7, @Now);
END
-- Translation
IF NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = @CatId_FirinPastane AND LanguageCode = 'tr')
BEGIN
    INSERT INTO [CategoryTranslations] ([Id], [CategoryId], [LanguageCode], [Name], [CreatedAt])
    VALUES (NEWID(), @CatId_FirinPastane, 'tr', N'Fırın & Pastane', @Now);
END


-- Kişisel Bakım
SELECT TOP 1 @CatId_KisiselBakim = Id FROM Categories WHERE Name = N'Kişisel Bakım' AND VendorType = 2;
IF @CatId_KisiselBakim IS NULL
BEGIN
    SET @CatId_KisiselBakim = NEWID();
    INSERT INTO [Categories] ([Id], [VendorType], [Name], [Icon], [Color], [ImageUrl], [DisplayOrder], [CreatedAt])
    VALUES (@CatId_KisiselBakim, 2, N'Kişisel Bakım', 'spa', '#E91E63', 'https://images.unsplash.com/photo-1612817288484-6f8f6400d75b?auto=format&fit=crop&q=80&w=500', 8, @Now);
END
-- Translation
IF NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = @CatId_KisiselBakim AND LanguageCode = 'tr')
BEGIN
    INSERT INTO [CategoryTranslations] ([Id], [CategoryId], [LanguageCode], [Name], [CreatedAt])
    VALUES (NEWID(), @CatId_KisiselBakim, 'tr', N'Kişisel Bakım', @Now);
END


-- Ev Bakım & Temizlik
SELECT TOP 1 @CatId_EvTemizlik = Id FROM Categories WHERE Name = N'Ev Bakım & Temizlik' AND VendorType = 2;
IF @CatId_EvTemizlik IS NULL
BEGIN
    SET @CatId_EvTemizlik = NEWID();
    INSERT INTO [Categories] ([Id], [VendorType], [Name], [Icon], [Color], [ImageUrl], [DisplayOrder], [CreatedAt])
    VALUES (@CatId_EvTemizlik, 2, N'Ev Bakım & Temizlik', 'cleaning_services', '#00BCD4', 'https://images.unsplash.com/photo-1583947215259-38e31be8751f?auto=format&fit=crop&q=80&w=500', 9, @Now);
END
-- Translation
IF NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = @CatId_EvTemizlik AND LanguageCode = 'tr')
BEGIN
    INSERT INTO [CategoryTranslations] ([Id], [CategoryId], [LanguageCode], [Name], [CreatedAt])
    VALUES (NEWID(), @CatId_EvTemizlik, 'tr', N'Ev Bakım & Temizlik', @Now);
END


-- Dondurma & Tatlı
SELECT TOP 1 @CatId_Dondurma = Id FROM Categories WHERE Name = N'Dondurma & Tatlı' AND VendorType = 2;
IF @CatId_Dondurma IS NULL
BEGIN
    SET @CatId_Dondurma = NEWID();
    INSERT INTO [Categories] ([Id], [VendorType], [Name], [Icon], [Color], [ImageUrl], [DisplayOrder], [CreatedAt])
    VALUES (@CatId_Dondurma, 2, N'Dondurma & Tatlı', 'icecream', '#03A9F4', 'https://images.unsplash.com/photo-1574484284008-0504e0e56da3?auto=format&fit=crop&q=80&w=500', 10, @Now);
END
-- Translation
IF NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = @CatId_Dondurma AND LanguageCode = 'tr')
BEGIN
    INSERT INTO [CategoryTranslations] ([Id], [CategoryId], [LanguageCode], [Name], [CreatedAt])
    VALUES (NEWID(), @CatId_Dondurma, 'tr', N'Dondurma & Tatlı', @Now);
END


-- Bebek & Çocuk
SELECT TOP 1 @CatId_BebekCocuk = Id FROM Categories WHERE Name = N'Anne & Çocuk' AND VendorType = 2;
IF @CatId_BebekCocuk IS NULL
BEGIN
    SET @CatId_BebekCocuk = NEWID();
    INSERT INTO [Categories] ([Id], [VendorType], [Name], [Icon], [Color], [ImageUrl], [DisplayOrder], [CreatedAt])
    VALUES (@CatId_BebekCocuk, 2, N'Anne & Çocuk', 'child_care', '#F06292', 'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?auto=format&fit=crop&q=80&w=500', 11, @Now);
END
-- Translation
IF NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = @CatId_BebekCocuk AND LanguageCode = 'tr')
BEGIN
    INSERT INTO [CategoryTranslations] ([Id], [CategoryId], [LanguageCode], [Name], [CreatedAt])
    VALUES (NEWID(), @CatId_BebekCocuk, 'tr', N'Anne & Çocuk', @Now);
END


-- Evcil Dostlar
SELECT TOP 1 @CatId_EvcilDostlar = Id FROM Categories WHERE Name = N'Evcil Hayvanlar' AND VendorType = 2;
IF @CatId_EvcilDostlar IS NULL
BEGIN
    SET @CatId_EvcilDostlar = NEWID();
    INSERT INTO [Categories] ([Id], [VendorType], [Name], [Icon], [Color], [ImageUrl], [DisplayOrder], [CreatedAt])
    VALUES (@CatId_EvcilDostlar, 2, N'Evcil Hayvanlar', 'pets', '#8D6E63', 'https://images.unsplash.com/photo-1450778869180-41d0601e046e?auto=format&fit=crop&q=80&w=500', 12, @Now);
END
-- Translation
IF NOT EXISTS (SELECT 1 FROM CategoryTranslations WHERE CategoryId = @CatId_EvcilDostlar AND LanguageCode = 'tr')
BEGIN
    INSERT INTO [CategoryTranslations] ([Id], [CategoryId], [LanguageCode], [Name], [CreatedAt])
    VALUES (NEWID(), @CatId_EvcilDostlar, 'tr', N'Evcil Hayvanlar', @Now);
END


---------------------------------------------------
-- 2. Vendors
---------------------------------------------------

-- Hızlı Market
SELECT TOP 1 @MarketVendorId1 = Id FROM Vendors WHERE Name = N'Hızlı Market' AND Type = 2;
IF @MarketVendorId1 IS NULL
BEGIN
    SET @MarketVendorId1 = NEWID();
    INSERT INTO [Vendors] ([Id], [Type], [Name], [ImageUrl], [Address], [City], [Latitude], [Longitude], [Rating], [RatingCount], [PhoneNumber], [Description], [MinimumOrderAmount], [DeliveryFee], [EstimatedDeliveryTime], [IsActive], [OwnerId], [CreatedAt])
    VALUES (@MarketVendorId1, 2, N'Hızlı Market', 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=800', N'Bağdat Caddesi No:123', 'Istanbul', 41.0082, 28.9784, 4.8, 120, '5551112233', N'Taze ve hızlı market alışverişi', 100.00, 15.00, 25, 1, @SystemUserId, @Now);
END

-- Mahalle Bakkalı
SELECT TOP 1 @MarketVendorId2 = Id FROM Vendors WHERE Name = N'Mahalle Bakkalı' AND Type = 2;
IF @MarketVendorId2 IS NULL
BEGIN
    SET @MarketVendorId2 = NEWID();
    INSERT INTO [Vendors] ([Id], [Type], [Name], [ImageUrl], [Address], [City], [Latitude], [Longitude], [Rating], [RatingCount], [PhoneNumber], [Description], [MinimumOrderAmount], [DeliveryFee], [EstimatedDeliveryTime], [IsActive], [OwnerId], [CreatedAt])
    VALUES (@MarketVendorId2, 2, N'Mahalle Bakkalı', 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&q=80&w=800', N'Moda Caddesi No:45', 'Istanbul', 40.9876, 29.0234, 4.5, 45, '5554445566', N'Mahallenizin dostu', 50.00, 10.00, 15, 1, @SystemUserId, @Now);
END

---------------------------------------------------
-- 3. Products
---------------------------------------------------

-- Insert Products for Market Vendor 1 (Hızlı Market)
INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_MeyveSebze, N'Yerli Muzu', N'Anamur Muzu Kg', 39.90, 1, 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&q=80&w=500', 1, 100, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Yerli Muzu');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_MeyveSebze, N'Domates', N'Salkım Domates Kg', 24.50, 1, 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&q=80&w=500', 1, 200, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Domates');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_Icecekler, N'Süt', N'Tam Yağlı Süt 1L', 28.00, 1, 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&q=80&w=500', 1, 50, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Süt');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_TemelGida, N'Yumurta', N'15li L Boy Yumurta', 65.00, 1, 'https://images.unsplash.com/photo-1587486913049-53fc88980cfc?auto=format&fit=crop&q=80&w=500', 1, 30, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Yumurta');


-- Insert Products for Market Vendor 2 (Mahalle Bakkalı)
INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId2, @CatId_Atistirmalik, N'Cips', N'Baharatlı Cips Büyük Boy', 35.00, 1, 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&q=80&w=500', 1, 20, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId2 AND Name = N'Cips');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId2, @CatId_Icecekler, N'Kola', N'Şekersiz Kola 1L', 25.00, 1, 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=500', 1, 40, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId2 AND Name = N'Kola');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId2, @CatId_TemelGida, N'Ekmek', N'Odun Ekmeği', 10.00, 1, 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&q=80&w=500', 1, 100, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId2 AND Name = N'Ekmek');


-- Şarküteri & Kahvaltılık Products
INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_Sarkuteri, N'Ezine Peyniri', N'Tam Yağlı Ezine Peyniri 500g', 185.00, 1, 'https://images.unsplash.com/photo-1486297678162-eb2a19b0a32d?auto=format&fit=crop&q=80&w=500', 1, 40, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Ezine Peyniri');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_Sarkuteri, N'Zeytin', N'Siyah Gemlik Zeytini 1Kg', 120.00, 1, 'https://images.unsplash.com/photo-1549488346-a4c3f71c998c?auto=format&fit=crop&q=80&w=500', 1, 60, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Zeytin');


-- Et, Tavuk & Balık Products
INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_EtTavukBalik, N'Dana Kıyma', N'Yarım Yağlı Dana Kıyma 1Kg', 450.00, 1, 'https://images.unsplash.com/photo-1588168333986-5078d3ae3976?auto=format&fit=crop&q=80&w=500', 1, 20, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Dana Kıyma');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_EtTavukBalik, N'Tavuk Göğsü', N'Tavuk Göğsü Bonfile 1Kg', 180.00, 1, 'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&q=80&w=500', 1, 30, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Tavuk Göğsü');


-- Fırın & Pastane Products
INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId2, @CatId_FirinPastane, N'Simit', N'Taze Çıtır Simit', 15.00, 1, 'https://images.unsplash.com/photo-1623245402095-7b1981cb3011?auto=format&fit=crop&q=80&w=500', 1, 50, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId2 AND Name = N'Simit');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId2, @CatId_FirinPastane, N'Kruvasan', N'Tereyağlı Kruvasan', 45.00, 1, 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&q=80&w=500', 1, 25, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId2 AND Name = N'Kruvasan');


-- Kişisel Bakım Products
INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_KisiselBakim, N'Şampuan', N'Onarıcı Bakım Şampuanı 500ml', 89.90, 1, 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?auto=format&fit=crop&q=80&w=500', 1, 40, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Şampuan');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_KisiselBakim, N'Diş Macunu', N'Beyazlatıcı Diş Macunu 75ml', 65.50, 1, 'https://images.unsplash.com/photo-1559599189-fe84fea43c2d?auto=format&fit=crop&q=80&w=500', 1, 60, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Diş Macunu');


-- Ev Bakım & Temizlik Products
INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_EvTemizlik, N'Sıvı Sabun', N'Zeytinyağlı Sıvı Sabun 750ml', 45.00, 1, 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=500', 1, 55, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Sıvı Sabun');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_EvTemizlik, N'Çamaşır Suyu', N'Ultra Yoğun Çamaşır Suyu 1L', 38.90, 1, 'https://images.unsplash.com/photo-1585670146603-eeb5227e2e5e?auto=format&fit=crop&q=80&w=500', 1, 80, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Çamaşır Suyu');


-- Dondurma & Tatlı Products
INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId2, @CatId_Dondurma, N'Vanilyalı Dondurma', N'Kutu Dondurma 500ml', 90.00, 1, 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&q=80&w=500', 1, 30, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId2 AND Name = N'Vanilyalı Dondurma');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId2, @CatId_Dondurma, N'Çikolatalı Puding', N'Kakaolu Puding 4lü Paket', 45.00, 1, 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&q=80&w=500', 1, 40, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId2 AND Name = N'Çikolatalı Puding');


-- Anne & Çocuk Products
INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_BebekCocuk, N'Bebek Bezi', N'4 Numara Bebek Bezi 30lu', 220.00, 1, 'https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&q=80&w=500', 1, 50, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Bebek Bezi');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_BebekCocuk, N'Islak Mendil', N'Hassas Ciltler İçin Islak Mendil 90lı', 45.00, 1, 'https://images.unsplash.com/photo-1520013583686-dc92957b458b?auto=format&fit=crop&q=80&w=500', 1, 100, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Islak Mendil');


-- Evcil Hayvanlar Products
INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_EvcilDostlar, N'Kedi Maması', N'Yetişkin Kedi Maması Tavuklu 1.5Kg', 280.00, 1, 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&q=80&w=500', 1, 40, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Kedi Maması');

INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt], [VendorType])
SELECT NEWID(), @MarketVendorId1, @CatId_EvcilDostlar, N'Köpek Ödül Maması', N'Kemik Şekilli Ödül Maması 200g', 65.00, 1, 'https://images.unsplash.com/photo-1583337130417-3346a1be7dee?auto=format&fit=crop&q=80&w=500', 1, 50, NULL, @Now, 2
WHERE NOT EXISTS (SELECT 1 FROM Products WHERE VendorId = @MarketVendorId1 AND Name = N'Köpek Ödül Maması');


---------------------------------------------------
-- 4. Banners
---------------------------------------------------

INSERT INTO [PromotionalBanners] ([Id], [VendorType], [Title], [Subtitle], [ButtonText], [ButtonAction], [ImageUrl], [DisplayOrder], [IsActive], [StartDate], [EndDate], [CreatedAt])
SELECT NEWID(), 2, N'Taze Meyve Şenliği', N'Haftanın taze meyvelerinde %20 indirim!', N'Hemen Al', 'category:' + CAST(@CatId_MeyveSebze AS NVARCHAR(50)), 'https://images.unsplash.com/photo-1610832958506-aa56368176cf?auto=format&fit=crop&q=80&w=800', 1, 1, @Now, DATEADD(day, 7, @Now), @Now
WHERE NOT EXISTS (SELECT 1 FROM PromotionalBanners WHERE VendorType = 2 AND Title = N'Taze Meyve Şenliği');

INSERT INTO [PromotionalBanners] ([Id], [VendorType], [Title], [Subtitle], [ButtonText], [ButtonAction], [ImageUrl], [DisplayOrder], [IsActive], [StartDate], [EndDate], [CreatedAt])
SELECT NEWID(), 2, N'Hızlı Teslimat', N'Market siparişleriniz 30 dakikada kapınızda', N'Göz At', 'home', 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=800', 2, 1, @Now, DATEADD(day, 30, @Now), @Now
WHERE NOT EXISTS (SELECT 1 FROM PromotionalBanners WHERE VendorType = 2 AND Title = N'Hızlı Teslimat');

---------------------------------------------------
-- 5. Banner Translations
---------------------------------------------------
INSERT INTO [PromotionalBannerTranslations] ([Id], [PromotionalBannerId], [LanguageCode], [Title], [Subtitle], [ButtonText], [CreatedAt])
SELECT 
    NEWID(),
    Id, 
    'tr', 
    Title, 
    Subtitle, 
    ButtonText, 
    @Now
FROM [PromotionalBanners] pb
WHERE [VendorType] = 2 
AND [CreatedAt] >= DATEADD(minute, -1, @Now) -- Only for recently created/checked banners
AND NOT EXISTS (SELECT 1 FROM PromotionalBannerTranslations pbt WHERE pbt.PromotionalBannerId = pb.Id AND pbt.LanguageCode = 'tr');


PRINT 'Market dummy data (Idempotent) script executed successfully.';
