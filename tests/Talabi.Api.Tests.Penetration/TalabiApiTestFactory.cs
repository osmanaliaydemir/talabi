using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

namespace Talabi.Api.Tests.Penetration;

public class TalabiApiTestFactory : WebApplicationFactory<Talabi.Api.Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Test");

        builder.ConfigureAppConfiguration((_, config) =>
        {
            // Minimal config to make CORS deterministic in tests
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Testing:DisableHangfire"] = "true",
                ["Cors:AllowCredentials"] = "true",
                ["Cors:Test:AllowedOrigins:0"] = "https://example.com",
                ["Cors:AllowedMethods:0"] = "GET",
                ["Cors:AllowedMethods:1"] = "POST",
                ["Cors:AllowedMethods:2"] = "PUT",
                ["Cors:AllowedMethods:3"] = "DELETE",
                ["Cors:AllowedMethods:4"] = "PATCH",
                ["Cors:AllowedMethods:5"] = "OPTIONS",
                ["Cors:AllowedHeaders:0"] = "*",
                ["Cors:ExposedHeaders:0"] = "*",
                ["Cors:MaxAge"] = "3600"
            });
        });
    }
}

