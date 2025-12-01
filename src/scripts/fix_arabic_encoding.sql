-- Fix Arabic Character Encoding Issues
-- Using N prefix for Unicode strings

UPDATE CategoryTranslations SET Name = N'طعام' WHERE CategoryId = (SELECT Id FROM Categories WHERE Name = 'Yemek') AND LanguageCode = 'ar';
UPDATE CategoryTranslations SET Name = N'متاجر' WHERE CategoryId = (SELECT Id FROM Categories WHERE Name = 'Mağazalar') AND LanguageCode = 'ar';
UPDATE CategoryTranslations SET Name = N'بقالة' WHERE CategoryId = (SELECT Id FROM Categories WHERE Name = 'Market') AND LanguageCode = 'ar';
UPDATE CategoryTranslations SET Name = N'مشروبات' WHERE CategoryId = (SELECT Id FROM Categories WHERE Name = 'İçecek') AND LanguageCode = 'ar';
UPDATE CategoryTranslations SET Name = N'حلويات' WHERE CategoryId = (SELECT Id FROM Categories WHERE Name = 'Tatlı') AND LanguageCode = 'ar';
UPDATE CategoryTranslations SET Name = N'إلكترونيات' WHERE CategoryId = (SELECT Id FROM Categories WHERE Name = 'Elektronik') AND LanguageCode = 'ar';
UPDATE CategoryTranslations SET Name = N'ملابس' WHERE CategoryId = (SELECT Id FROM Categories WHERE Name = 'Giyim') AND LanguageCode = 'ar';
