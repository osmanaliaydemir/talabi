-- Market Dummy Data Script (Part 2: Vendors and Products)
-- Fixes FK issues and links to previously inserted categories
-- Target Database: Remote (db29009)

DECLARE @MarketVendorId1 UNIQUEIDENTIFIER = NEWID();
DECLARE @MarketVendorId2 UNIQUEIDENTIFIER = NEWID();

-- Get previously inserted Category IDs
DECLARE @CatId_MeyveSebze UNIQUEIDENTIFIER;
DECLARE @CatId_Atistirmalik UNIQUEIDENTIFIER;
DECLARE @CatId_Icecekler UNIQUEIDENTIFIER;
DECLARE @CatId_TemelGida UNIQUEIDENTIFIER;

SELECT @CatId_MeyveSebze = Id FROM [Categories] WHERE [Name] = 'Meyve & Sebze' AND [VendorType] = 2;
SELECT @CatId_Atistirmalik = Id FROM [Categories] WHERE [Name] = 'Atıştırmalık' AND [VendorType] = 2;
SELECT @CatId_Icecekler = Id FROM [Categories] WHERE [Name] = 'İçecekler' AND [VendorType] = 2;
SELECT @CatId_TemelGida = Id FROM [Categories] WHERE [Name] = 'Temel Gıda' AND [VendorType] = 2;

DECLARE @Now DATETIME2 = GETUTCDATE();
-- User ID found from AspNetUsers table
DECLARE @SystemUserId NVARCHAR(450) = '221417ab-2312-4ac7-9b93-99b3b49a70eb'; 

-- 3. Insert Market Vendors
INSERT INTO [Vendors] ([Id], [Type], [Name], [ImageUrl], [Address], [City], [Latitude], [Longitude], [Rating], [RatingCount], [PhoneNumber], [Description], [MinimumOrderAmount], [DeliveryFee], [EstimatedDeliveryTime], [IsActive], [OwnerId], [CreatedAt])
VALUES
(@MarketVendorId1, 2, 'Hızlı Market', 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&q=80&w=800', 'Bağdat Caddesi No:123', 'Istanbul', 41.0082, 28.9784, 4.8, 120, '5551112233', 'Taze ve hızlı market alışverişi', 100.00, 15.00, 25, 1, @SystemUserId, @Now),
(@MarketVendorId2, 2, 'Mahalle Bakkalı', 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&q=80&w=800', 'Moda Caddesi No:45', 'Istanbul', 40.9876, 29.0234, 4.5, 45, '5554445566', 'Mahallenizin dostu', 50.00, 10.00, 15, 1, @SystemUserId, @Now);

-- 4. Insert Products for Market Vendor 1 (Hızlı Market)
-- Only insert if Category IDs were found
IF @CatId_MeyveSebze IS NOT NULL AND @CatId_Icecekler IS NOT NULL AND @CatId_TemelGida IS NOT NULL
BEGIN
    INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt])
    VALUES
    (NEWID(), @MarketVendorId1, @CatId_MeyveSebze, 'Yerli Muz', 'Anamur Muzu Kg', 39.90, 1, 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&q=80&w=500', 1, 100, NULL, @Now),
    (NEWID(), @MarketVendorId1, @CatId_MeyveSebze, 'Domates', 'Salkım Domates Kg', 24.50, 1, 'https://images.unsplash.com/photo-1592924357228-91a4daadcfea?auto=format&fit=crop&q=80&w=500', 1, 200, NULL, @Now),
    (NEWID(), @MarketVendorId1, @CatId_Icecekler, 'Süt', 'Tam Yağlı Süt 1L', 28.00, 1, 'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&q=80&w=500', 1, 50, NULL, @Now),
    (NEWID(), @MarketVendorId1, @CatId_TemelGida, 'Yumurta', '15li L Boy Yumurta', 65.00, 1, 'https://images.unsplash.com/photo-1587486913049-53fc88980cfc?auto=format&fit=crop&q=80&w=500', 1, 30, NULL, @Now);
END

-- 5. Insert Products for Market Vendor 2 (Mahalle Bakkalı)
IF @CatId_Atistirmalik IS NOT NULL AND @CatId_Icecekler IS NOT NULL AND @CatId_TemelGida IS NOT NULL
BEGIN
    INSERT INTO [Products] ([Id], [VendorId], [CategoryId], [Name], [Description], [Price], [Currency], [ImageUrl], [IsAvailable], [Stock], [PreparationTime], [CreatedAt])
    VALUES
    (NEWID(), @MarketVendorId2, @CatId_Atistirmalik, 'Cips', 'Baharatlı Cips Büyük Boy', 35.00, 1, 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&q=80&w=500', 1, 20, NULL, @Now),
    (NEWID(), @MarketVendorId2, @CatId_Icecekler, 'Kola', 'Şekersiz Kola 1L', 25.00, 1, 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=500', 1, 40, NULL, @Now),
    (NEWID(), @MarketVendorId2, @CatId_TemelGida, 'Ekmek', 'Odun Ekmeği', 10.00, 1, 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?auto=format&fit=crop&q=80&w=500', 1, 100, NULL, @Now);
END

PRINT 'Vendors and Products inserted successfully to REMOTE database.';
