using Talabi.Core.Entities;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Infrastructure.Data;

public class TalabiDbContextSeed
{
    public static async Task SeedAsync(TalabiDbContext context)
    {
        // 1. Geography Data (Country, City, District, Locality)
        if (!await context.Countries.AnyAsync())
        {
            // 1. Türkiye
            var turkey = new Country { NameTr = "Türkiye", NameEn = "Turkey", NameAr = "تركيا", Code = "TR" };

            var istanbul = new City { NameTr = "İstanbul", NameEn = "Istanbul", NameAr = "إسطنبول", Country = turkey };

            var atasehir = new District
                { NameTr = "Ataşehir", NameEn = "Atasehir", NameAr = "أتاشيهير", City = istanbul };

            var kayisdagi = new Locality
                { NameTr = "Kayışdağı", NameEn = "Kayisdagi", NameAr = "كايشداغي", District = atasehir };

            await context.Countries.AddAsync(turkey);
            await context.Cities.AddAsync(istanbul);
            await context.Districts.AddAsync(atasehir);
            await context.Localities.AddAsync(kayisdagi);

            // 2. Suriye
            var syria = new Country { NameTr = "Suriye", NameEn = "Syria", NameAr = "سوريا", Code = "SY" };

            var aleppo = new City { NameTr = "Halep", NameEn = "Aleppo", NameAr = "حلب", Country = syria };

            var azaz = new District { NameTr = "Azez", NameEn = "Azaz", NameAr = "أعزاز", City = aleppo };

            var akhtarin = new Locality { NameTr = "Ahterin", NameEn = "Akhtarin", NameAr = "اخترين", District = azaz };

            await context.Countries.AddAsync(syria);
            await context.Cities.AddAsync(aleppo);
            await context.Districts.AddAsync(azaz);
            await context.Localities.AddAsync(akhtarin);
        }

        await SeedLegalAndSettingsAsync(context);

        await context.SaveChangesAsync();
    }

    private static async Task SeedLegalAndSettingsAsync(TalabiDbContext context)
    {
        // 1. System Settings
        // 1. System Settings - Idempotent seeding (Add if not exists)
        var settings = new List<SystemSetting>
        {
            // Company Info
            new()
            {
                Key = "CompanyTitle", Value = "Talabi Teknoloji A.Ş.", Group = "CompanyInfo",
                Description = "Resmi Şirket Unvanı"
            },
            new()
            {
                Key = "CompanyMersisNo", Value = "012345678900001", Group = "CompanyInfo",
                Description = "MERSİS Numarası"
            },
            new()
            {
                Key = "CompanyEmail", Value = "info@talabi.com", Group = "CompanyInfo",
                Description = "İletişim E-posta Adresi"
            },
            new()
            {
                Key = "CompanyPhone", Value = "+90 216 123 45 67", Group = "CompanyInfo",
                Description = "İletişim Telefon Numarası"
            },
            new()
            {
                Key = "CompanyAddress", Value = "Kayışdağı Mah. Teknoloji Cad. No:1, Ataşehir, İstanbul",
                Group = "CompanyInfo", Description = "Resmi Adres"
            },

            // Agreements Summary (for registration checkboxes) - Localized
            // TR
            new()
            {
                Key = "CustomerMembershipAgreement_tr",
                Value = "Talabi Kullanıcı Sözleşmesi'ni okudum ve kabul ediyorum.", Group = "Agreements",
                Description = "Müşteri Üyelik Sözleşmesi Onay Metni (TR)"
            },
            new()
            {
                Key = "VendorMembershipAgreement_tr", Value = "Talabi Satıcı Sözleşmesi'ni okudum ve kabul ediyorum.",
                Group = "Agreements", Description = "Satıcı Üyelik Sözleşmesi Onay Metni (TR)"
            },
            new()
            {
                Key = "CourierMembershipAgreement_tr", Value = "Talabi Kurye Sözleşmesi'ni okudum ve kabul ediyorum.",
                Group = "Agreements", Description = "Kurye Üyelik Sözleşmesi Onay Metni (TR)"
            },
            new()
            {
                Key = "KvkkDisclosureText_tr",
                Value = "KVKK Aydınlatma Metni kapsamında verilerimin işlenmesini kabul ediyorum.",
                Group = "Agreements", Description = "KVKK Aydınlatma Metni (TR)"
            },
            new()
            {
                Key = "MarketingPermissionText_tr",
                Value =
                    "Kampanya ve duyurulardan haberdar olmak için ticari elektronik ileti gönderilmesini kabul ediyorum.",
                Group = "Agreements", Description = "Pazarlama İzin Metni (TR)"
            },
            new()
            {
                Key = "DistanceSalesAgreement_tr",
                Value = "Mesafeli Satış Sözleşmesi ve Ön Bilgilendirme Formu'nu okudum, kabul ediyorum.",
                Group = "Agreements", Description = "Mesafeli Satış Sözleşmesi Onay Metni (TR)"
            },

            // EN
            new()
            {
                Key = "CustomerMembershipAgreement_en", Value = "I have read and agree to the Talabi User Agreement.",
                Group = "Agreements", Description = "Customer Membership Agreement Approval Text (EN)"
            },
            new()
            {
                Key = "VendorMembershipAgreement_en", Value = "I have read and agree to the Talabi Vendor Agreement.",
                Group = "Agreements", Description = "Vendor Membership Agreement Approval Text (EN)"
            },
            new()
            {
                Key = "CourierMembershipAgreement_en", Value = "I have read and agree to the Talabi Courier Agreement.",
                Group = "Agreements", Description = "Courier Membership Agreement Approval Text (EN)"
            },
            new()
            {
                Key = "KvkkDisclosureText_en",
                Value = "I consent to the processing of my data within the scope of the GDPR Disclosure.",
                Group = "Agreements", Description = "GDPR Disclosure (EN)"
            },
            new()
            {
                Key = "MarketingPermissionText_en",
                Value =
                    "I agree to receive commercial electronic messages to be informed about campaigns and announcements.",
                Group = "Agreements", Description = "Marketing Permission Text (EN)"
            },
            new()
            {
                Key = "DistanceSalesAgreement_en",
                Value = "I have read and agree to the Distance Sales Agreement and Preliminary Information Form.",
                Group = "Agreements", Description = "Distance Sales Agreement Approval Text (EN)"
            },

            // AR
            new()
            {
                Key = "CustomerMembershipAgreement_ar", Value = "لقد قرأت وأوافق على اتفاقية مستخدم Talabi.",
                Group = "Agreements", Description = "نص الموافقة على اتفاقية عضوية العميل (AR)"
            },
            new()
            {
                Key = "VendorMembershipAgreement_ar", Value = "لقد قرأت وأوافق على اتفاقية بائع Talabi.",
                Group = "Agreements", Description = "نص الموافقة على اتفاقية عضوية البائع (AR)"
            },
            new()
            {
                Key = "CourierMembershipAgreement_ar", Value = "لقد قرأت وأوافق على اتفاقية ساعي Talabi.",
                Group = "Agreements", Description = "نص الموافقة على اتفاقية عضوية الساعي (AR)"
            },
            new()
            {
                Key = "KvkkDisclosureText_ar", Value = "أوافق على معالجة بياناتي في إطار بيان حماية البيانات الشخصية.",
                Group = "Agreements", Description = "بيان حماية البيانات الشخصية (AR)"
            },
            new()
            {
                Key = "MarketingPermissionText_ar",
                Value = "أوافق على تلقي الرسائل الإلكترونية التجارية للبقاء على اطلاع بالحمالت والإعلانات.",
                Group = "Agreements", Description = "نص إذن التسويق (AR)"
            },
            new()
            {
                Key = "DistanceSalesAgreement_ar",
                Value = "لقد قرأت وأوافق على اتفاقية البيع عن بعد ونموذج المعلومات الأولية.", Group = "Agreements",
                Description = "نص الموافقة على اتفاقية البيع عن بعد (AR)"
            },

            // Courier & Payment Settings
            new()
            {
                Key = "CourierDeliveryFee", Value = "5000", Group = "Payment",
                Description = "Kurye Sabit Teslimat Ücreti (SYP)"
            },
            new()
            {
                Key = "ExchangeRate_TL", Value = "450", Group = "Payment",
                Description = "1 TL'nin SYP karşılığı"
            },
            new()
            {
                Key = "ExchangeRate_USD", Value = "15000", Group = "Payment",
                Description = "1 USD'nin SYP karşılığı"
            }
        };

        foreach (var setting in settings)
        {
            if (!await context.SystemSettings.AnyAsync(s => s.Key == setting.Key))
            {
                await context.SystemSettings.AddAsync(setting);
            }
        }

        await context.SaveChangesAsync();

        // 2. Legal Documents
        if (!await context.LegalDocuments.AnyAsync())
        {
            var docs = new List<LegalDocument>();
            var types = new[]
                { "terms-of-use", "privacy-policy", "refund-policy", "distance-sales-agreement", "kvkk", "imprint" };
            var languages = new[] { "tr", "en", "ar" };

            foreach (var type in types)
            {
                foreach (var lang in languages)
                {
                    docs.Add(new LegalDocument
                    {
                        Type = type,
                        LanguageCode = lang,
                        Title = GetDefaultTitle(type, lang),
                        Content = GetDefaultContent(type, lang),
                        LastUpdated = DateTime.UtcNow
                    });
                }
            }

            await context.LegalDocuments.AddRangeAsync(docs);
        }
    }

    private static string GetDefaultTitle(string type, string lang)
    {
        return (type, lang) switch
        {
            ("terms-of-use", "tr") => "Kullanım Koşulları",
            ("terms-of-use", "en") => "Terms of Use",
            ("terms-of-use", "ar") => "şروط الاستخدام",
            ("privacy-policy", "tr") => "Gizlilik Politikası",
            ("privacy-policy", "en") => "Privacy Policy",
            ("privacy-policy", "ar") => "سياسة الخصوصية",
            ("refund-policy", "tr") => "İade Politikası",
            ("refund-policy", "en") => "Refund Policy",
            ("refund-policy", "ar") => "سياسة الاسترجاع",
            ("distance-sales-agreement", "tr") => "Mesafeli Satış Sözleşmesi",
            ("distance-sales-agreement", "en") => "Distance Sales Agreement",
            ("distance-sales-agreement", "ar") => "اتفاقية البيع عن بعد",
            ("kvkk", "tr") => "KVKK Aydınlatma Metni",
            ("kvkk", "en") => "GDPR Disclosure",
            ("kvkk", "ar") => "بيان حماية البيانات الشخصية",
            ("imprint", "tr") => "Künye ve İletişim",
            ("imprint", "en") => "Imprint & Contact",
            ("imprint", "ar") => "معلومات الشركة واﻻتصال",
            _ => type
        };
    }

    private static string GetDefaultContent(string type, string lang)
    {
        // Örnek içerikler (HTML formatında)
        return (type, lang) switch
        {
            (_, "tr") => $"<h3>{type}</h3><p>Bu bir örnek {type} içeriğidir. Lütfen gerçek içerik ile güncelleyin.</p>",
            (_, "en") => $"<h3>{type}</h3><p>This is a sample {type} content. Please update with actual content.</p>",
            (_, "ar") => $"<h3>{type}</h3><p>هذا محتوى تجريبي لـ {type}. يرجى التحديث بالمحتوى الفعلي.</p>",
            _ => $"Sample content for {type}"
        };
    }
}
