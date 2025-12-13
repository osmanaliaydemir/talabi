using Talabi.Core.Entities;
using Microsoft.EntityFrameworkCore;

namespace Talabi.Infrastructure.Data;

public class TalabiDbContextSeed
{
    public static async Task SeedAsync(TalabiDbContext context)
    {
        if (await context.Countries.AnyAsync())
            return;

        // 1. Türkiye
        var turkey = new Country { NameTr = "Türkiye", NameEn = "Turkey", NameAr = "تركيا", Code = "TR" };
        
        var istanbul = new City { NameTr = "İstanbul", NameEn = "Istanbul", NameAr = "إسطنبول", Country = turkey };
        
        var atasehir = new District { NameTr = "Ataşehir", NameEn = "Atasehir", NameAr = "أتاشيهير", City = istanbul };
        
        var kayisdagi = new Locality { NameTr = "Kayışdağı", NameEn = "Kayisdagi", NameAr = "كايشداغي", District = atasehir };

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

        await context.SaveChangesAsync();
    }
}
