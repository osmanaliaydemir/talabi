using Talabi.Portal.Middleware;
using Talabi.Portal.Models;
using Talabi.Portal.Services;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Localization;
using System.Globalization;
using Serilog;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Identity;
using Talabi.Infrastructure.Data;
using Talabi.Core.Entities;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File(
        path: "Logs/talabiportal-.log",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}"
    )
    .CreateLogger();

builder.Host.UseSerilog();

// Configuration
var apiSettings = builder.Configuration.GetSection("ApiSettings").Get<ApiSettings>() ?? new ApiSettings();
builder.Services.AddSingleton(apiSettings);

// Data Protection
builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(Path.Combine(Directory.GetCurrentDirectory(), "Keys")))
    .SetApplicationName("TalabiPortal");

// Database
builder.Services.AddDbContext<TalabiDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Identity & Auth
builder.Services.AddIdentity<AppUser, IdentityRole>(options =>
    {
        options.SignIn.RequireConfirmedEmail = true;
        options.User.RequireUniqueEmail = true;
        options.Password.RequireDigit = true;
        options.Password.RequiredLength = 8;
        options.Lockout.AllowedForNewUsers = true;
        options.Lockout.MaxFailedAccessAttempts = 5;
        options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(15);
    })
    .AddEntityFrameworkStores<TalabiDbContext>()
    .AddDefaultTokenProviders()
    .AddClaimsPrincipalFactory<Talabi.Portal.Services.CustomUserClaimsPrincipalFactory>();

builder.Services.ConfigureApplicationCookie(options =>
{
    options.LoginPath = "/Auth/Login";
    options.LogoutPath = "/Auth/Logout";
    options.AccessDeniedPath = "/Auth/AccessDenied";
    options.ExpireTimeSpan = TimeSpan.FromHours(12);
    options.SlidingExpiration = true;
    options.Cookie.Name = "TalabiPortalAuth";
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.None; // Make secure in prod
    options.Cookie.SameSite = SameSiteMode.Lax;
});

// Localization
var supportedCultures = new[]
{
    new CultureInfo("tr-TR"),
    new CultureInfo("en-US"),
    new CultureInfo("ar-SA"),
};

builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    options.DefaultRequestCulture = new RequestCulture("en-US");
    options.SupportedCultures = supportedCultures;
    options.SupportedUICultures = supportedCultures;
    options.RequestCultureProviders.Clear();
    options.RequestCultureProviders.Add(new CookieRequestCultureProvider
    {
        CookieName = "Talabi.Portal.Culture"
    });
});

// Services
builder.Services.AddControllersWithViews(options =>
{
    options.Filters.Add<Talabi.Portal.Filters.VendorProfileCompletionFilter>();
});
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromHours(12);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

builder.Services.AddHttpContextAccessor();

// App Services
builder.Services.AddScoped(typeof(Talabi.Core.Interfaces.IRepository<>), typeof(Talabi.Infrastructure.Repositories.Repository<>));
builder.Services.AddScoped<Talabi.Core.Interfaces.IUnitOfWork, Talabi.Infrastructure.Repositories.UnitOfWork>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IHomeService, HomeService>();
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<ISettingsService, SettingsService>();
builder.Services.AddSingleton<ILocalizationService, LocalizationService>();
builder.Services.AddScoped<Talabi.Core.Interfaces.ILocationService, Talabi.Infrastructure.Services.LocationService>();
builder.Services.AddScoped<IDeliveryZoneService, DeliveryZoneService>();
builder.Services.AddScoped<Talabi.Core.Interfaces.IUserContextService, Talabi.Infrastructure.Services.UserContextService>();
builder.Services.AddScoped<Talabi.Core.Interfaces.IDashboardNotificationService, Talabi.Infrastructure.Services.DashboardNotificationService>();
builder.Services.AddScoped<ICourierService, CourierService>();
builder.Services.AddScoped<IVendorService, VendorService>();

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
}

app.UseStaticFiles();
app.UseRequestLocalization();
app.UseCultureMiddleware();

using (var scope = app.Services.CreateScope())
{
    var localizationService = scope.ServiceProvider.GetRequiredService<ILocalizationService>();
    await localizationService.LoadTranslationsAsync();

    var dbContext = scope.ServiceProvider.GetRequiredService<TalabiDbContext>();
    await TalabiDbContextSeed.SeedAsync(dbContext);
}

app.UseRouting();
app.UseSession();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

try
{
    Log.Information("Starting Talabi.Portal application (Direct DB Mode)");
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Talabi.Portal application failed to start");
    throw;
}
finally
{
    Log.CloseAndFlush();
}
