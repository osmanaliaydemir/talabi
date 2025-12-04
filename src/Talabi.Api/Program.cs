using AspNetCoreRateLimit;
using FluentValidation;
using FluentValidation.AspNetCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Localization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Globalization;
using System.Text;
using Talabi.Api.Middleware;
using Talabi.Api.Validators;
using Talabi.Api.HealthChecks;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Services;
using Talabi.Infrastructure.Data;
using Talabi.Infrastructure.Repositories;
using Talabi.Infrastructure.Services;
using Hangfire;
using Talabi.Core.Options;

var builder = WebApplication.CreateBuilder(args);

// Logging yapılandırması - Structured logging
// Not: File logging için Serilog veya benzeri bir package eklenebilir
// Şimdilik console ve debug logging kullanılıyor
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

// Logging seviyeleri appsettings.json'da yapılandırılmıştır

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddOpenApi();

// Localization
builder.Services.AddLocalization(options => options.ResourcesPath = "Resources");
builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    var supportedCultures = new[]
    {
        new CultureInfo("tr"),
        new CultureInfo("en"),
        new CultureInfo("ar")
    };

    options.DefaultRequestCulture = new RequestCulture("tr");
    options.SupportedCultures = supportedCultures;
    options.SupportedUICultures = supportedCultures;

    options.RequestCultureProviders.Clear();
    options.RequestCultureProviders.Add(new QueryStringRequestCultureProvider());
    options.RequestCultureProviders.Add(new AcceptLanguageHeaderRequestCultureProvider());
});

// Database
builder.Services.AddDbContext<TalabiDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Email Settings
builder.Services.Configure<EmailSettings>(builder.Configuration.GetSection("Email"));

// Repository Pattern - Unit of Work
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

// Health Checks
builder.Services.AddHealthChecks()
    .AddCheck<DatabaseHealthCheck>("database", tags: new[] { "db", "sql" })
    .AddCheck<HangfireHealthCheck>("hangfire", tags: new[] { "background", "jobs" })
    .AddCheck<MemoryHealthCheck>("memory", tags: new[] { "system", "memory" });

// Services
builder.Services.AddScoped<INotificationService, FirebaseNotificationService>();
builder.Services.AddScoped<IBackgroundJobService, BackgroundJobService>();
builder.Services.AddScoped<IOrderAssignmentService, OrderAssignmentService>();
builder.Services.AddScoped<IEmailSender, EmailSender>();
builder.Services.AddScoped<IEmailTemplateRenderer, EmailTemplateRenderer>();

// Hangfire
builder.Services.AddHangfire(config =>
    config.UseSqlServerStorage(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddHangfireServer();

// SignalR
builder.Services.AddSignalR();

// Rate Limiting
builder.Services.AddMemoryCache();
builder.Services.Configure<IpRateLimitOptions>(options =>
{
    options.GeneralRules = new List<RateLimitRule>
    {
        new RateLimitRule
        {
            Endpoint = "*",
            Period = "1m",
            Limit = 60
        }
    };
});
builder.Services.AddInMemoryRateLimiting();
builder.Services.AddSingleton<IRateLimitConfiguration, RateLimitConfiguration>();

// FluentValidation
builder.Services.AddFluentValidationAutoValidation();
builder.Services.AddValidatorsFromAssemblyContaining<LoginDtoValidator>();

// CORS yapılandırması
var corsSettings = builder.Configuration.GetSection("Cors");
var allowedOrigins = corsSettings.GetSection("AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
var allowCredentials = corsSettings.GetValue<bool>("AllowCredentials", true);
var allowedMethods = corsSettings.GetSection("AllowedMethods").Get<string[]>() ?? new[] { "GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS" };
var allowedHeaders = corsSettings.GetSection("AllowedHeaders").Get<string[]>() ?? new[] { "*" };
var exposedHeaders = corsSettings.GetSection("ExposedHeaders").Get<string[]>() ?? new[] { "*" };
var maxAge = corsSettings.GetValue<int>("MaxAge", 3600);

builder.Services.AddCors(options =>
{
    options.AddPolicy("DefaultCorsPolicy", policy =>
    {
        if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins);
            
            // Credentials sadece belirli origin'lerle kullanılabilir
            if (allowCredentials)
            {
                policy.AllowCredentials();
            }
        }
        else
        {
            // Eğer hiç origin belirtilmemişse, tüm origin'lere izin ver (sadece development için)
            // Not: AllowAnyOrigin() kullanıldığında AllowCredentials() kullanılamaz
            if (builder.Environment.IsDevelopment())
            {
                policy.AllowAnyOrigin();
                // AllowCredentials() kullanılamaz çünkü AllowAnyOrigin() ile uyumsuz
            }
        }

        policy.WithMethods(allowedMethods);
        policy.WithHeaders(allowedHeaders);
        policy.WithExposedHeaders(exposedHeaders);
        policy.SetPreflightMaxAge(TimeSpan.FromSeconds(maxAge));
    });
});

// Identity
builder.Services.AddIdentity<AppUser, IdentityRole>(options =>
{
    options.SignIn.RequireConfirmedEmail = true;
    options.User.RequireUniqueEmail = true;
})
.AddEntityFrameworkStores<TalabiDbContext>()
.AddDefaultTokenProviders();

// JWT Authentication
var jwtSettings = builder.Configuration.GetSection("JwtSettings");
var secret = jwtSettings["Secret"];

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidAudience = jwtSettings["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret!))
    };
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();

    // Seed Data (only if database is accessible)
    using (var scope = app.Services.CreateScope())
    {
        try
        {
            var context = scope.ServiceProvider.GetRequiredService<TalabiDbContext>();

            // Apply migrations and test connection
            await context.Database.MigrateAsync();

            if (await context.Database.CanConnectAsync())
            {
                var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();
                var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole>>();
                await Talabi.Api.Data.DataSeeder.SeedAsync(context, userManager, roleManager);
            }
            else
            {
                Console.WriteLine("Warning: Cannot connect to database. Skipping seed data.");
            }
        }
        catch (Exception ex)
        {
            // Log but don't fail the application startup
            Console.WriteLine($"Warning: Seeding skipped - {ex.GetType().Name}: {ex.Message}");
            if (ex.InnerException != null)
            {
                Console.WriteLine($"Inner: {ex.InnerException.Message}");
            }
        }
    }
}
else
{
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();

// CORS - Authentication'dan önce olmalı
app.UseCors("DefaultCorsPolicy");

// Localization middleware
app.UseRequestLocalization();

app.UseIpRateLimiting();

app.UseAuthentication();
app.UseAuthorization();

app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseMiddleware<RequestResponseLoggingMiddleware>();

app.MapControllers();
app.MapHub<Talabi.Api.Hubs.NotificationHub>("/hubs/notifications");

// Health Checks endpoints
app.MapHealthChecks("/health", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var result = System.Text.Json.JsonSerializer.Serialize(new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                data = e.Value.Data,
                duration = e.Value.Duration.TotalMilliseconds
            }),
            totalDuration = report.TotalDuration.TotalMilliseconds
        });
        await context.Response.WriteAsync(result);
    }
});

app.MapHealthChecks("/health/ready", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("db") || check.Tags.Contains("sql"),
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var result = System.Text.Json.JsonSerializer.Serialize(new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description
            })
        });
        await context.Response.WriteAsync(result);
    }
});

app.MapHealthChecks("/health/live", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = _ => false, // Sadece uygulamanın çalıştığını kontrol et
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";
        var result = System.Text.Json.JsonSerializer.Serialize(new
        {
            status = "Healthy",
            message = "Application is running"
        });
        await context.Response.WriteAsync(result);
    }
});

app.UseHangfireDashboard();

// Schedule Recurring Jobs
RecurringJob.AddOrUpdate<IBackgroundJobService>(
    "check-abandoned-carts",
    service => service.CheckAbandonedCarts(),
    Cron.Hourly);

app.Run();
