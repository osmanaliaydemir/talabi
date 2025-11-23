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

        Console.WriteLine($"Seeding Vendors for User ID: {user.Id}");

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
                    new Product { Name = "Et Döner Dürüm", Price = 120, Description = "100gr et döner, özel sos", ImageUrl = "https://images.unsplash.com/photo-1669276730278-01431530c37c?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8ZG9uZXJ8ZW58MHx8MHx8fDA%3D" },
                    new Product { Name = "İskender", Price = 250, Description = "Tereyağlı, soslu", ImageUrl = "https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTJ8fGtlYmFwfGVufDB8fDB8fHww" },
                    new Product { Name = "Ayran", Price = 30, Description = "Yayık ayranı", ImageUrl = "https://images.unsplash.com/photo-1626132647523-66f5bf380027?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YXlyYW58ZW58MHx8MHx8fDA%3D" }
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
                    new Product { Name = "Whopper Menü", Price = 200, Description = "Whopper, Patates, Kola", ImageUrl = "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YnVyZ2VyfGVufDB8fDB8fHww" },
                    new Product { Name = "Chicken Royale", Price = 180, Description = "Tavuk burger", ImageUrl = "https://images.unsplash.com/photo-1513185158878-8d8c2a2a3da3?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8YnVyZ2VyfGVufDB8fDB8fHww" }
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
                    new Product { Name = "Latte", Price = 90, Description = "Tall boy", ImageUrl = "https://images.unsplash.com/photo-1570968992193-73e0967205bd?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8M3x8bGF0dGV8ZW58MHx8MHx8fDA%3D" },
                    new Product { Name = "Americano", Price = 75, Description = "Sıcak/Soğuk", ImageUrl = "https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YW1lcmljYW5vfGVufDB8fDB8fHww" }
                }
            }
        };

        context.Vendors.AddRange(vendors);
        await context.SaveChangesAsync();
    }
}
