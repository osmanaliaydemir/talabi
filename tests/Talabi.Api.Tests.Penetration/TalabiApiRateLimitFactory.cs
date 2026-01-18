using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;

namespace Talabi.Api.Tests.Penetration;

public class TalabiApiRateLimitFactory : WebApplicationFactory<Talabi.Api.Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Use Development to keep IpRateLimiting enabled (Program.cs disables it only for Test env)
        builder.UseEnvironment("Development");
    }
}

