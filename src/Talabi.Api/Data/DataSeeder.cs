using Microsoft.AspNetCore.Identity;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Data;

public static class DataSeeder
{
    public static async Task SeedAsync(TalabiDbContext context, UserManager<AppUser> userManager, RoleManager<IdentityRole> roleManager)
    {
        // Create roles if they don't exist
        if (!await roleManager.RoleExistsAsync("Vendor"))
        {
            await roleManager.CreateAsync(new IdentityRole("Vendor"));
        }
        if (!await roleManager.RoleExistsAsync("Customer"))
        {
            await roleManager.CreateAsync(new IdentityRole("Customer"));
        }
        if (!await roleManager.RoleExistsAsync("Courier"))
        {
            await roleManager.CreateAsync(new IdentityRole("Courier"));
        }
        if (!await roleManager.RoleExistsAsync("Admin"))
        {
            await roleManager.CreateAsync(new IdentityRole("Admin"));
        }

        var user = await userManager.FindByEmailAsync("admin@talabi.com");
        if (user == null)
        {
            user = new AppUser
            {
                UserName = "admin@talabi.com",
                Email = "admin@talabi.com",
                FullName = "Talabi Admin",
                EmailConfirmed = true
            };
            var result = await userManager.CreateAsync(user, "Talabi123!");
            if (!result.Succeeded)
            {
                throw new Exception($"Failed to create seed user: {string.Join(", ", result.Errors.Select(e => e.Description))}");
            }

            // Assign Vendor role
            await userManager.AddToRoleAsync(user, "Vendor");
        }
        else
        {
            // Ensure user has Vendor role
            if (!await userManager.IsInRoleAsync(user, "Vendor"))
            {
                await userManager.AddToRoleAsync(user, "Vendor");
            }
        }

        Console.WriteLine($"Seeding Categories and Vendors for User ID: {user.Id}");

        // Seed Promotional Banners (independent of vendors)
        if (!context.PromotionalBanners.Any())
        {
            var banner1 = new PromotionalBanner
            {
                Title = "Harika Bir Gün Olacak!",
                Subtitle = "Ücretsiz teslimat, düşük ücretler & %10 nakit iade!",
                ButtonText = "Şimdi Sipariş Ver",
                ButtonAction = "order",
                ImageUrl = null,
                DisplayOrder = 1,
                IsActive = true,
                StartDate = null,
                EndDate = null,
                Translations = new List<PromotionalBannerTranslation>
                {
                    new PromotionalBannerTranslation
                    {
                        LanguageCode = "tr",
                        Title = "Harika Bir Gün Olacak!",
                        Subtitle = "Ücretsiz teslimat, düşük ücretler & %10 nakit iade!",
                        ButtonText = "Şimdi Sipariş Ver"
                    },
                    new PromotionalBannerTranslation
                    {
                        LanguageCode = "en",
                        Title = "It's Going to Be a Great Day!",
                        Subtitle = "Free delivery, low fees & 10% cashback!",
                        ButtonText = "Order Now"
                    },
                    new PromotionalBannerTranslation
                    {
                        LanguageCode = "ar",
                        Title = "سيكون يوماً رائعاً!",
                        Subtitle = "توصيل مجاني، رسوم منخفضة و 10% استرداد نقدي!",
                        ButtonText = "اطلب الآن"
                    }
                }
            };

            var banner2 = new PromotionalBanner
            {
                Title = "Yeni Ürünler Keşfedin!",
                Subtitle = "Taze ve lezzetli ürünlerimizi keşfedin, özel fiyatlarla sipariş verin!",
                ButtonText = "Keşfet",
                ButtonAction = "discover",
                ImageUrl = null,
                DisplayOrder = 2,
                IsActive = true,
                StartDate = null,
                EndDate = null,
                Translations = new List<PromotionalBannerTranslation>
                {
                    new PromotionalBannerTranslation
                    {
                        LanguageCode = "tr",
                        Title = "Yeni Ürünler Keşfedin!",
                        Subtitle = "Taze ve lezzetli ürünlerimizi keşfedin, özel fiyatlarla sipariş verin!",
                        ButtonText = "Keşfet"
                    },
                    new PromotionalBannerTranslation
                    {
                        LanguageCode = "en",
                        Title = "Discover New Products!",
                        Subtitle = "Discover our fresh and delicious products, order at special prices!",
                        ButtonText = "Discover"
                    },
                    new PromotionalBannerTranslation
                    {
                        LanguageCode = "ar",
                        Title = "اكتشف منتجات جديدة!",
                        Subtitle = "اكتشف منتجاتنا الطازجة واللذيذة، اطلب بأسعار خاصة!",
                        ButtonText = "اكتشف"
                    }
                }
            };

            var banner3 = new PromotionalBanner
            {
                Title = "Hızlı Teslimat Garantisi!",
                Subtitle = "30 dakika içinde kapınızda! Ücretsiz kargo fırsatını kaçırmayın.",
                ButtonText = "Sipariş Ver",
                ButtonAction = "order",
                ImageUrl = null,
                DisplayOrder = 3,
                IsActive = true,
                StartDate = null,
                EndDate = null,
                Translations = new List<PromotionalBannerTranslation>
                {
                    new PromotionalBannerTranslation
                    {
                        LanguageCode = "tr",
                        Title = "Hızlı Teslimat Garantisi!",
                        Subtitle = "30 dakika içinde kapınızda! Ücretsiz kargo fırsatını kaçırmayın.",
                        ButtonText = "Sipariş Ver"
                    },
                    new PromotionalBannerTranslation
                    {
                        LanguageCode = "en",
                        Title = "Fast Delivery Guarantee!",
                        Subtitle = "At your door in 30 minutes! Don't miss the free shipping opportunity.",
                        ButtonText = "Place Order"
                    },
                    new PromotionalBannerTranslation
                    {
                        LanguageCode = "ar",
                        Title = "ضمان التوصيل السريع!",
                        Subtitle = "عند بابك في 30 دقيقة! لا تفوت فرصة الشحن المجاني.",
                        ButtonText = "تقديم الطلب"
                    }
                }
            };

            context.PromotionalBanners.AddRange(banner1, banner2, banner3);
            await context.SaveChangesAsync();
            Console.WriteLine("Promotional banners seeded successfully!");
        }

        if (context.Vendors.Any()) return;

       


    }
}
