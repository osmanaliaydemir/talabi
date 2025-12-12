using Getir.MerchantPortal.Middleware;
using Getir.MerchantPortal.Services;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.Localization;
using System.Globalization;
using Serilog;

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .WriteTo.File(
        path: "Logs/merchantportal-.log",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj}{NewLine}{Exception}"
    )
    .CreateLogger();

builder.Host.UseSerilog();

// Configuration
var apiSettings = builder.Configuration.GetSection("ApiSettings").Get<ApiSettings>()!;

// Data Protection (Cookie encryption için)
builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(Path.Combine(Directory.GetCurrentDirectory(), "Keys")))
    .SetApplicationName("GetirMerchantPortal");

// Simple Localization
var supportedCultures = new[]
{
    new CultureInfo("tr-TR"), // Türkçe (Default)
    new CultureInfo("en-US"), // English
    new CultureInfo("ar-SA")  // Arabic
};

builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    options.DefaultRequestCulture = new RequestCulture("tr-TR");
    options.SupportedCultures = supportedCultures;
    options.SupportedUICultures = supportedCultures;
    
    // Cookie-based culture provider
    options.RequestCultureProviders.Insert(0, new CookieRequestCultureProvider
    {
        CookieName = "MerchantPortal.Culture"
    });
});

// Add services to the container
builder.Services.AddControllersWithViews();

// Session
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromHours(12);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.None; // ✅ HTTP için None olmalı
    options.Cookie.SameSite = SameSiteMode.Lax; // ✅ Cross-origin için Lax
});

// Authentication
builder.Services.AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Auth/Login";
        options.LogoutPath = "/Auth/Logout";
        options.AccessDeniedPath = "/Auth/AccessDenied";
        options.ExpireTimeSpan = TimeSpan.FromHours(12);
        options.SlidingExpiration = true;
        options.Cookie.Name = "GetirMerchantAuth";
        options.Cookie.HttpOnly = true;
        options.Cookie.SecurePolicy = CookieSecurePolicy.None; // ✅ HTTP için None olmalı
        options.Cookie.SameSite = SameSiteMode.Lax; // ✅ Cross-origin için Lax
    });

// HttpContext
builder.Services.AddHttpContextAccessor();

// Register AuthTokenHandler
builder.Services.AddTransient<AuthTokenHandler>();
builder.Services.AddTransient<RetryPolicyHandler>();

// HttpClient for API calls
builder.Services.AddHttpClient<IApiClient, ApiClient>(client =>
{
    client.BaseAddress = new Uri(apiSettings.BaseUrl);
    client.DefaultRequestHeaders.Add("Accept", "application/json");
    client.Timeout = TimeSpan.FromSeconds(30);
})
.AddHttpMessageHandler<AuthTokenHandler>() // Auto-inject JWT token from session
.AddHttpMessageHandler<RetryPolicyHandler>()
.ConfigurePrimaryHttpMessageHandler(() =>
{
    var handler = new HttpClientHandler();
    
    // Development ortamında SSL certificate validation'ı bypass et
    if (builder.Environment.IsDevelopment())
    {
        handler.ServerCertificateCustomValidationCallback = 
            HttpClientHandler.DangerousAcceptAnyServerCertificateValidator;
    }
    
    return handler;
});

// Application Services
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IMerchantService, MerchantService>();
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IWorkingHoursService, WorkingHoursService>();
builder.Services.AddScoped<IPaymentService, PaymentService>();
builder.Services.AddScoped<IReportService, ReportService>();
builder.Services.AddScoped<IStockService, StockService>();
builder.Services.AddScoped<IProductReviewService, ProductReviewService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddSingleton<ISignalRService, SignalRService>();
builder.Services.AddScoped<ISettingsService, SettingsService>();
builder.Services.AddScoped<ISearchService, SearchService>();
builder.Services.AddScoped<ICampaignService, CampaignService>();
builder.Services.AddScoped<ICouponService, CouponService>();
builder.Services.AddScoped<IProductOptionService, ProductOptionService>();
builder.Services.AddScoped<IMarketProductVariantService, MarketProductVariantService>();
builder.Services.AddScoped<IDeliveryZoneService, DeliveryZoneService>();
builder.Services.AddScoped<IDeliveryOptimizationService, DeliveryOptimizationService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IServiceCategoryDirectory, ServiceCategoryDirectory>();
builder.Services.AddScoped<ISpecialHolidayService, SpecialHolidayService>();
builder.Services.AddScoped<IInternationalizationService, InternationalizationService>();
builder.Services.AddScoped<IRateLimitAdminService, RateLimitAdminService>();
builder.Services.AddScoped<IRealtimeTrackingPortalService, RealtimeTrackingPortalService>();
builder.Services.AddScoped<IInventoryService, InventoryService>();
builder.Services.AddScoped<IAuditLoggingPortalService, AuditLoggingPortalService>();
builder.Services.AddScoped<IPlatformAdminPortalService, PlatformAdminPortalService>();
builder.Services.AddScoped<IUserSelfService, UserSelfService>();
builder.Services.AddScoped<IGeoAnalyticsPortalService, GeoAnalyticsPortalService>();
builder.Services.AddHttpClient<IMerchantDocumentService, MerchantDocumentService>(client =>
{
	client.BaseAddress = new Uri(apiSettings.BaseUrl);
	client.DefaultRequestHeaders.Add("Accept", "application/json");
	client.Timeout = TimeSpan.FromSeconds(60);
})
.AddHttpMessageHandler<AuthTokenHandler>()
.AddHttpMessageHandler<RetryPolicyHandler>()
.ConfigurePrimaryHttpMessageHandler(() =>
{
	var handler = new HttpClientHandler();
	if (builder.Environment.IsDevelopment())
		handler.ServerCertificateCustomValidationCallback = HttpClientHandler.DangerousAcceptAnyServerCertificateValidator;
	return handler;
});
builder.Services.AddScoped<IMerchantOnboardingService, MerchantOnboardingService>();
builder.Services.AddHttpClient<IFileService, FileService>(client =>
{
	client.BaseAddress = new Uri(apiSettings.BaseUrl);
	client.DefaultRequestHeaders.Add("Accept", "application/json");
	client.Timeout = TimeSpan.FromSeconds(30);
})
.AddHttpMessageHandler<AuthTokenHandler>()
.AddHttpMessageHandler<RetryPolicyHandler>()
.ConfigurePrimaryHttpMessageHandler(() =>
{
	var handler = new HttpClientHandler();
	if (builder.Environment.IsDevelopment())
	{
		handler.ServerCertificateCustomValidationCallback = HttpClientHandler.DangerousAcceptAnyServerCertificateValidator;
	}
	return handler;
});
builder.Services.AddHttpClient<IFileManagerService, FileManagerService>(client =>
{
	client.BaseAddress = new Uri(apiSettings.BaseUrl);
	client.DefaultRequestHeaders.Add("Accept", "application/json");
	client.Timeout = TimeSpan.FromSeconds(60);
})
.AddHttpMessageHandler<AuthTokenHandler>()
.AddHttpMessageHandler<RetryPolicyHandler>()
.ConfigurePrimaryHttpMessageHandler(() =>
{
	var handler = new HttpClientHandler();
	if (builder.Environment.IsDevelopment())
	{
		handler.ServerCertificateCustomValidationCallback = HttpClientHandler.DangerousAcceptAnyServerCertificateValidator;
	}
	return handler;
});

// Simple JSON-based Localization Service
builder.Services.AddSingleton<ILocalizationService, LocalizationService>();

// Settings
builder.Services.AddSingleton(apiSettings);

var app = builder.Build();

// Configure the HTTP request pipeline
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // app.UseHsts(); // ✅ HTTP için HSTS kapalı
}

// app.UseHttpsRedirection(); // ✅ HTTP için HTTPS redirect kapalı
app.UseStaticFiles();

// 🌐 Use Request Localization (before routing!)
app.UseRequestLocalization();

// 🌐 Use Custom Culture Middleware (after localization, before routing)
app.UseCultureMiddleware();

// Load translations on startup
using (var scope = app.Services.CreateScope())
{
    var localizationService = scope.ServiceProvider.GetRequiredService<ILocalizationService>();
    await localizationService.LoadTranslationsAsync();
}

app.UseRouting();

app.UseSession();
app.UseAuthentication();
app.UseSessionValidation(); // Validate session/cookie consistency
app.UseMiddleware<SerilogEnrichMiddleware>();
app.UseAuthorization();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Auth}/{action=Login}/{id?}");

try
{
    Log.Information("Starting MerchantPortal application");
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "MerchantPortal application failed to start");
    throw;
}
finally
{
    Log.CloseAndFlush();
}
