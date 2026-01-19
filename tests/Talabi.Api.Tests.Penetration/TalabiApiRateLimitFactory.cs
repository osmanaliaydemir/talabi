using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;

namespace Talabi.Api.Tests.Penetration;

public class TalabiApiRateLimitFactory : WebApplicationFactory<Talabi.Api.Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Use Development to keep IpRateLimiting enabled (Program.cs disables it only for Test env)
        builder.UseEnvironment("Development");

        builder.ConfigureAppConfiguration((_, config) =>
        {
            // Keep host shutdown deterministic in tests
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Testing:DisableHangfire"] = "true"
            });
        });
    }
}

