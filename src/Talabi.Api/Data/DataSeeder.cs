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

        if (context.Vendors.Any()) return;

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

        // Create Categories with Translations
        var categories = new List<Category>
        {
            new Category
            {
                Name = "Kebap & Döner",
                Icon = "fa-solid fa-drumstick-bite",
                Color = "#FF6B6B",
                Translations = new List<CategoryTranslation>
                {
                    new CategoryTranslation { LanguageCode = "tr", Name = "Kebap & Döner" },
                    new CategoryTranslation { LanguageCode = "en", Name = "Kebab & Doner" },
                    new CategoryTranslation { LanguageCode = "ar", Name = "كباب ودونر" }
                }
            },
            new Category
            {
                Name = "Burger",
                Icon = "fa-solid fa-burger",
                Color = "#FFD93D",
                Translations = new List<CategoryTranslation>
                {
                    new CategoryTranslation { LanguageCode = "tr", Name = "Burger" },
                    new CategoryTranslation { LanguageCode = "en", Name = "Burger" },
                    new CategoryTranslation { LanguageCode = "ar", Name = "برجر" }
                }
            },
            new Category
            {
                Name = "Kahve & İçecekler",
                Icon = "fa-solid fa-mug-hot",
                Color = "#6C5B7B",
                Translations = new List<CategoryTranslation>
                {
                    new CategoryTranslation { LanguageCode = "tr", Name = "Kahve & İçecekler" },
                    new CategoryTranslation { LanguageCode = "en", Name = "Coffee & Drinks" },
                    new CategoryTranslation { LanguageCode = "ar", Name = "قهوة ومشروبات" }
                }
            },
            new Category
            {
                Name = "Pizza",
                Icon = "fa-solid fa-pizza-slice",
                Color = "#E74C3C",
                Translations = new List<CategoryTranslation>
                {
                    new CategoryTranslation { LanguageCode = "tr", Name = "Pizza" },
                    new CategoryTranslation { LanguageCode = "en", Name = "Pizza" },
                    new CategoryTranslation { LanguageCode = "ar", Name = "بيتزا" }
                }
            },
            new Category
            {
                Name = "Tatlı & Pasta",
                Icon = "fa-solid fa-cake-candles",
                Color = "#F39C12",
                Translations = new List<CategoryTranslation>
                {
                    new CategoryTranslation { LanguageCode = "tr", Name = "Tatlı & Pasta" },
                    new CategoryTranslation { LanguageCode = "en", Name = "Dessert & Cake" },
                    new CategoryTranslation { LanguageCode = "ar", Name = "حلويات وكيك" }
                }
            },
            new Category
            {
                Name = "Sushi & Asya Mutfağı",
                Icon = "fa-solid fa-bowl-rice",
                Color = "#3498DB",
                Translations = new List<CategoryTranslation>
                {
                    new CategoryTranslation { LanguageCode = "tr", Name = "Sushi & Asya Mutfağı" },
                    new CategoryTranslation { LanguageCode = "en", Name = "Sushi & Asian Cuisine" },
                    new CategoryTranslation { LanguageCode = "ar", Name = "سوشي ومطبخ آسيوي" }
                }
            },
            new Category
            {
                Name = "Salata & Sağlıklı",
                Icon = "fa-solid fa-bowl-food",
                Color = "#27AE60",
                Translations = new List<CategoryTranslation>
                {
                    new CategoryTranslation { LanguageCode = "tr", Name = "Salata & Sağlıklı" },
                    new CategoryTranslation { LanguageCode = "en", Name = "Salad & Healthy" },
                    new CategoryTranslation { LanguageCode = "ar", Name = "سلطة وصحي" }
                }
            },
            new Category
            {
                Name = "Deniz Ürünleri",
                Icon = "fa-solid fa-fish",
                Color = "#1ABC9C",
                Translations = new List<CategoryTranslation>
                {
                    new CategoryTranslation { LanguageCode = "tr", Name = "Deniz Ürünleri" },
                    new CategoryTranslation { LanguageCode = "en", Name = "Seafood" },
                    new CategoryTranslation { LanguageCode = "ar", Name = "مأكولات بحرية" }
                }
            }
        };

        context.Categories.AddRange(categories);
        await context.SaveChangesAsync();

        // Get category references
        var kebapCategory = categories.First(c => c.Name == "Kebap & Döner");
        var burgerCategory = categories.First(c => c.Name == "Burger");
        var coffeeCategory = categories.First(c => c.Name == "Kahve & İçecekler");

        var vendors = new List<Vendor>
        {
            new Vendor
            {
                Name = "Lezzet Döner",
                Address = "Atatürk Cad. No:1",
                ImageUrl = "https://images.unsplash.com/photo-1529042410759-befb1204b468?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8ZG9uZXJ8ZW58MHx8MHx8fDA%3D",
                Owner = user,
                Products = new List<Product>
                {
                    new Product
                    {
                        Name = "Et Döner Dürüm",
                        Price = 120,
                        Description = "100gr et döner, özel sos",
                        ImageUrl = "https://images.unsplash.com/photo-1669276730278-01431530c37c?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZG9uZXJ8ZW58MHx8MHx8fDA%3D",
                        CategoryId = kebapCategory.Id,
                        Category = "Kebap & Döner"
                    },
                    new Product
                    {
                        Name = "İskender",
                        Price = 250,
                        Description = "Tereyağlı, soslu",
                        ImageUrl = "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTJ8fGtlYmFwfGVufDB8fDB8fHww",
                        CategoryId = kebapCategory.Id,
                        Category = "Kebap & Döner"
                    },
                    new Product
                    {
                        Name = "Ayran",
                        Price = 30,
                        Description = "Yayık ayranı",
                        ImageUrl = "https://images.unsplash.com/photo-1626132647523-66f5bf380027?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YXlyYW58ZW58MHx8MHx8fDA%3D",
                        CategoryId = coffeeCategory.Id,
                        Category = "Kahve & İçecekler"
                    }
                }
            },
            new Vendor
            {
                Name = "Burger King",
                Address = "AVM Kat:3",
                ImageUrl = "https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8YnVyZ2VyJTIwa2luZ3xlbnwwfHwwfHx8MA%3D%3D",
                Owner = user,
                Products = new List<Product>
                {
                    new Product
                    {
                        Name = "Whopper Menü",
                        Price = 200,
                        Description = "Whopper, Patates, Kola",
                        ImageUrl = "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YnVyZ2VyfGVufDB8fDB8fHww",
                        CategoryId = burgerCategory.Id,
                        Category = "Burger"
                    },
                    new Product
                    {
                        Name = "Chicken Royale",
                        Price = 180,
                        Description = "Tavuk burger",
                        ImageUrl = "https://images.unsplash.com/photo-1513185158878-8d8c2a2a3da3?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8YnVyZ2VyfGVufDB8fDB8fHww",
                        CategoryId = burgerCategory.Id,
                        Category = "Burger"
                    }
                }
            },
            new Vendor
            {
                Name = "Starbucks",
                Address = "Meydan AVM",
                ImageUrl = "https://images.unsplash.com/photo-1577401239170-897942555fb3?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTl8fGNvZmZlZSUyMHNob3B8ZW58MHx8MHx8fDA%3D",
                Owner = user,
                Products = new List<Product>
                {
                    new Product
                    {
                        Name = "Latte",
                        Price = 90,
                        Description = "Tall boy",
                        ImageUrl = "https://images.unsplash.com/photo-1570968992193-73e0967205bd?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8bGF0dGV8ZW58MHx8MHx8fDA%3D",
                        CategoryId = coffeeCategory.Id,
                        Category = "Kahve & İçecekler"
                    },
                    new Product
                    {
                        Name = "Americano",
                        Price = 75,
                        Description = "Sıcak/Soğuk",
                        ImageUrl = "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YW1lcmljYW5vfGVufDB8fDB8fHww",
                        CategoryId = coffeeCategory.Id,
                        Category = "Kahve & İçecekler"
                    }
                }
            }
        };

        context.Vendors.AddRange(vendors);
        await context.SaveChangesAsync();
    }
}
