using AspNetCoreRateLimit;
using FluentValidation;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Localization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using System.Globalization;
using System.Text;
using Talabi.Api.Middleware;
using Talabi.Api.Filters;
using Talabi.Api.Validators;
using Talabi.Api.HealthChecks;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Core.Services;
using Talabi.Core.Mappings;
using Talabi.Infrastructure.Data;
using Talabi.Infrastructure.Repositories;
using Talabi.Infrastructure.Services;
using Talabi.Api.Services;
using Talabi.Core.Options;
using Scalar.AspNetCore;
using Hangfire;

var builder = WebApplication.CreateBuilder(args);

// Configuration - User Secrets ve Environment Variables desteği
// Development ortamında User Secrets kullanılır
if (builder.Environment.IsDevelopment())
{
    builder.Configuration.AddUserSecrets<Program>();
}

// Environment Variables her zaman yüklenir (production'da öncelikli)
// Format: ConnectionStrings__DefaultConnection, JwtSettings__Secret, etc.
builder.Configuration.AddEnvironmentVariables();

// Logging yapılandırması - Structured logging
// Not: File logging için Serilog veya benzeri bir package eklenebilir
// Şimdilik console ve debug logging kullanılıyor
builder.Logging.ClearProviders();
builder.Logging.AddConsole();
builder.Logging.AddDebug();

// Logging seviyeleri appsettings.json'da yapılandırılmıştır

// FluentValidation filter'ı register et
builder.Services.AddScoped<FluentValidationActionFilter>();

// Add services to the container.
builder.Services.AddControllers(options =>
    {
        // Add input sanitization filter globally
        options.Filters.Add<InputSanitizationActionFilter>();
        // Add FluentValidation filter globally
        options.Filters.Add<FluentValidationActionFilter>();
    })
    .AddJsonOptions(options =>
    {
        // Circular reference handling için
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
        // MaxDepth artırılması - derin object graph'ler için
        options.JsonSerializerOptions.MaxDepth = 128;
    });

// Swagger/OpenAPI yapılandırması - Swashbuckle kullanarak
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new() { Title = "Talabi API", Version = "v1" });

    // Aynı isimli DTO'lar için tam namespace kullan
    options.CustomSchemaIds(type => type.FullName);

    // JSON serializer ayarlarını kullan
    options.UseInlineDefinitionsForEnums();
});

// AutoMapper configuration
builder.Services.AddAutoMapper(typeof(OrderMappingProfile).Assembly);

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

// Password Policy Settings
builder.Services.Configure<PasswordPolicyOptions>(builder.Configuration.GetSection("PasswordPolicy"));

// Google Maps Settings
builder.Services.Configure<GoogleMapsOptions>(builder.Configuration.GetSection("GoogleMaps"));

// Cache Settings
builder.Services.Configure<CacheOptions>(builder.Configuration.GetSection("Cache"));

// Repository Pattern - Unit of Work
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();
// Generic repository (some services depend on IRepository<T> directly)
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));

// Health Checks
builder.Services.AddHealthChecks()
    .AddCheck<DatabaseHealthCheck>("database", tags: new[] { "db", "sql" })
    .AddCheck<HangfireHealthCheck>("hangfire", tags: new[] { "background", "jobs" })
    .AddCheck<MemoryHealthCheck>("memory", tags: new[] { "system", "memory" });

// Services
builder.Services.AddScoped<INotificationService, FirebaseNotificationService>();
builder.Services.AddScoped<IDashboardNotificationService, DashboardNotificationService>();
builder.Services.AddScoped<ISignalRNotificationService, SignalRNotificationService>();
builder.Services.AddScoped<IBackgroundJobService, BackgroundJobService>();
builder.Services.AddScoped<IOrderAssignmentService, OrderAssignmentService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IEmailSender, EmailSender>();
builder.Services.AddScoped<IRuleValidatorService, RuleValidatorService>();
builder.Services.AddScoped<IEmailTemplateRenderer, EmailTemplateRenderer>();
builder.Services.AddScoped<ILocalizationService, LocalizationService>();
builder.Services.AddScoped<ILocationService, LocationService>();
builder.Services.AddScoped<IUserContextService, UserContextService>();
builder.Services.AddScoped<ISystemSettingsService, SystemSettingsService>();

builder.Services.AddScoped<IInputSanitizationService, InputSanitizationService>();
builder.Services.AddScoped<ICacheService, CacheService>();
builder.Services.AddScoped<ICampaignCalculator, CampaignCalculator>();
builder.Services.AddScoped<IWalletService, WalletService>();
// External Auth Token Verifier
builder.Services.AddHttpClient<IExternalAuthTokenVerifier, ExternalAuthTokenVerifier>();
// Map Service
builder.Services.AddHttpClient<IMapService, GoogleMapService>();
// File Upload Security Service
builder.Services.Configure<FileUploadSecurityOptions>(builder.Configuration.GetSection("FileUploadSecurity"));
builder.Services.AddScoped<IFileUploadSecurityService, FileUploadSecurityService>();
// ActivityLoggingService Singleton olmalı çünkü middleware'lerde kullanılıyor
// Middleware'ler singleton olarak çalışır ve scoped service'leri inject edemez
builder.Services.AddSingleton<IActivityLoggingService, ActivityLoggingService>();
builder.Services.AddHttpContextAccessor();

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
    // Explicitly enable endpoint rate limiting so rules can target specific verbs+paths
    options.EnableEndpointRateLimiting = true;

    options.GeneralRules = new List<RateLimitRule>
    {
        // Login endpoint - strict rate limiting to prevent brute force attacks
        new RateLimitRule
        {
            Endpoint = "POST:/api/auth/login",
            Period = "1m",
            Limit = 5 // Max 5 login attempts per minute
        },
        // Register endpoint - very strict rate limiting to prevent abuse
        new RateLimitRule
        {
            Endpoint = "POST:/api/auth/register",
            Period = "1h",
            Limit = 3 // Max 3 registrations per hour
        },
        // Email verification endpoint - very strict rate limiting
        new RateLimitRule
        {
            Endpoint = "POST:/api/auth/verify-email-code",
            Period = "1m",
            Limit = 5 // Max 5 attempts per minute
        },
        // Resend verification code - limit to prevent abuse
        new RateLimitRule
        {
            Endpoint = "POST:/api/auth/resend-verification-code",
            Period = "1h",
            Limit = 3 // Max 3 resends per hour
        },
        // Confirm email endpoint - strict rate limiting to prevent token brute force
        new RateLimitRule
        {
            Endpoint = "GET:/api/auth/confirm-email",
            Period = "1m",
            Limit = 5 // Max 5 attempts per minute
        },
        // General rate limit
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

// Verification Code Security
builder.Services.Configure<VerificationCodeSecurityOptions>(
    builder.Configuration.GetSection("VerificationCodeSecurity"));
builder.Services.AddScoped<IVerificationCodeSecurityService, VerificationCodeSecurityService>();

// FluentValidation
builder.Services.AddValidatorsFromAssemblyContaining<LoginDtoValidator>();

// CORS yapılandırması - Environment bazlı URL'ler
var corsSettings = builder.Configuration.GetSection("Cors");
string[] allowedOrigins;

// Environment'a göre CORS URL'lerini seç
if (builder.Environment.IsDevelopment())
{
    // Development ortamında Local URL'leri kullan
    allowedOrigins = corsSettings.GetSection("Local").GetSection("AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
}
else if (builder.Environment.EnvironmentName.Equals("Test", StringComparison.OrdinalIgnoreCase))
{
    // Test ortamında Test URL'lerini kullan
    allowedOrigins = corsSettings.GetSection("Test").GetSection("AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
}
else if (builder.Environment.IsProduction())
{
    // Production ortamında Production URL'lerini kullan
    allowedOrigins = corsSettings.GetSection("Production").GetSection("AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
}
else
{
    // Diğer ortamlar için Local URL'leri kullan (fallback)
    allowedOrigins = corsSettings.GetSection("Local").GetSection("AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
}

var allowCredentials = corsSettings.GetValue("AllowCredentials", true);
var allowedMethods = corsSettings.GetSection("AllowedMethods").Get<string[]>() ??
                     new[] { "GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS" };
var allowedHeaders = corsSettings.GetSection("AllowedHeaders").Get<string[]>() ?? new[] { "*" };
var exposedHeaders = corsSettings.GetSection("ExposedHeaders").Get<string[]>() ?? new[] { "*" };
var maxAge = corsSettings.GetValue("MaxAge", 3600);

builder.Services.AddCors(options =>
{
    options.AddPolicy("DefaultCorsPolicy", policy =>
    {
        // Test environment: keep CORS permissive to avoid integration test flakiness.
        // (Real environments should rely on explicit AllowedOrigins.)
        if (builder.Environment.EnvironmentName.Equals("Test", StringComparison.OrdinalIgnoreCase))
        {
            policy.AllowAnyOrigin();
            policy.AllowAnyHeader();
            policy.AllowAnyMethod();
            policy.SetPreflightMaxAge(TimeSpan.FromSeconds(maxAge));
            return;
        }

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
            // Eğer hiç origin belirtilmemişse, sadece development için tüm origin'lere izin ver
            // Production ve Test ortamlarında boş origin listesi güvenlik riski oluşturur
            if (builder.Environment.IsDevelopment() ||
                builder.Environment.EnvironmentName.Equals("Test", StringComparison.OrdinalIgnoreCase))
            {
                policy.AllowAnyOrigin();
                // AllowCredentials() kullanılamaz çünkü AllowAnyOrigin() ile uyumsuz
            }
            else
            {
                // Production ve Test ortamlarında origin belirtilmediyse uyarı
                // Not: Logger bu aşamada henüz yapılandırılmamış olabilir, bu yüzden Console.WriteLine kullanıyoruz
                Console.WriteLine(
                    $"WARNING: CORS: {builder.Environment.EnvironmentName} ortamı için AllowedOrigins boş! CORS yapılandırması kontrol edilmeli.");
            }
        }

        // Methods
        if (allowedMethods.Length == 1 && allowedMethods[0] == "*")
        {
            policy.AllowAnyMethod();
        }
        else
        {
            policy.WithMethods(allowedMethods);
        }

        // Headers
        if (allowedHeaders.Length == 1 && allowedHeaders[0] == "*")
        {
            policy.AllowAnyHeader();
        }
        else
        {
            policy.WithHeaders(allowedHeaders);
        }

        // Exposed headers (never allow "*" - keep explicit list)
        var safeExposedHeaders = exposedHeaders.Where(h => h != "*").ToArray();
        if (safeExposedHeaders.Length > 0)
        {
            policy.WithExposedHeaders(safeExposedHeaders);
        }

        policy.SetPreflightMaxAge(TimeSpan.FromSeconds(maxAge));
    });
});

// Identity
var passwordPolicy = builder.Configuration.GetSection("PasswordPolicy").Get<PasswordPolicyOptions>() ??
                     new PasswordPolicyOptions();

builder.Services.AddIdentity<AppUser, IdentityRole>(options =>
    {
        options.SignIn.RequireConfirmedEmail = true;
        options.User.RequireUniqueEmail =
            false; // Soft delete senaryosu için false yapıldı. Uniqueness kontrolü servis katmanında yapılacak.

        // Password Policy
        options.Password.RequireDigit = passwordPolicy.RequireDigit;
        options.Password.RequireLowercase = passwordPolicy.RequireLowercase;
        options.Password.RequireUppercase = passwordPolicy.RequireUppercase;
        options.Password.RequireNonAlphanumeric = passwordPolicy.RequireNonAlphanumeric;
        options.Password.RequiredLength = passwordPolicy.MinimumLength;

        // Account Lockout Policy
        options.Lockout.AllowedForNewUsers = true;
        options.Lockout.MaxFailedAccessAttempts = passwordPolicy.MaxFailedAttempts;
        options.Lockout.DefaultLockoutTimeSpan = TimeSpan.FromMinutes(passwordPolicy.LockoutDurationMinutes);
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

        // SignalR Authentication - Read token from query string
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];

                // If the request is for our hub...
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) &&
                    (path.StartsWithSegments("/hubs/notifications")))
                {
                    // Read the token out of the query string
                    context.Token = accessToken;
                }

                return Task.CompletedTask;
            }
        };
    });

var app = builder.Build();

// ActivityLoggingService ve ErrorLoggingService için service provider'ı set et (Hangfire job'ları için gerekli)
ErrorLoggingService.SetServiceProvider(app.Services);
ActivityLoggingService.SetServiceProvider(app.Services);

// Configure the HTTP request pipeline.
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

// HTTPS redirection/HSTS: disable in TestServer integration tests to avoid 30x responses
if (!app.Environment.EnvironmentName.Equals("Test", StringComparison.OrdinalIgnoreCase))
{
    app.UseHsts();
    app.UseHttpsRedirection();
}

// Routing must run before CORS (for endpoint metadata)
app.UseRouting();

// CORS - Authentication'dan önce olmalı
app.UseCors("DefaultCorsPolicy");

// Static files (swagger/scalar assets etc.)
app.UseStaticFiles();

// Localization middleware
app.UseRequestLocalization();

// Rate limiting can interfere with penetration suites that make many requests.
// Keep it enabled for real environments; disable only for explicit Test environment.
if (!app.Environment.EnvironmentName.Equals("Test", StringComparison.OrdinalIgnoreCase))
{
    app.UseIpRateLimiting();
}

app.UseAuthentication();
app.UseAuthorization();

app.UseMiddleware<SecurityHeadersMiddleware>();
app.UseMiddleware<RequestResponseLoggingMiddleware>();
app.UseMiddleware<ExceptionHandlingMiddleware>();

// Scalar ve Swagger için basit authentication
app.Use(async (context, next) =>
{
    var path = context.Request.Path.Value?.ToLower() ?? "";

    // Sadece /scalar ve /swagger path'leri için authentication iste
    if (path.StartsWith("/scalar") || path.StartsWith("/swagger"))
    {
        // Authorization header'ı kontrol et
        var authHeader = context.Request.Headers.Authorization.ToString();

        if (string.IsNullOrEmpty(authHeader) || !authHeader.StartsWith("Basic "))
        {
            // Authentication iste
            context.Response.StatusCode = 401;
            context.Response.Headers.Append("WWW-Authenticate", "Basic realm=\"Talabi API Documentation\"");
            await context.Response.WriteAsync("Authentication required");
            return;
        }

        // Basic auth decode et
        var encodedCredentials = authHeader.Substring("Basic ".Length).Trim();
        var credentials = Encoding.UTF8.GetString(Convert.FromBase64String(encodedCredentials));
        var parts = credentials.Split(':', 2);

        var username = parts[0];
        var password = parts.Length > 1 ? parts[1] : "";

        // Kullanıcı adı ve şifre kontrolü (appsettings'den oku veya sabit kullan)
        var validUsername = builder.Configuration["Documentation:Username"] ?? "admin";
        var validPassword = builder.Configuration["Documentation:Password"] ?? "talabi2024";

        if (username != validUsername || password != validPassword)
        {
            context.Response.StatusCode = 401;
            context.Response.Headers.Append("WWW-Authenticate", "Basic realm=\"Talabi API Documentation\"");
            await context.Response.WriteAsync("Invalid credentials");
            return;
        }
    }

    await next();
});

// Swagger middleware - OpenAPI JSON üretimi
app.UseSwagger();

// Scalar API Documentation - Swagger spec kullanarak
app.MapScalarApiReference(options =>
{
    options
        .WithTitle("Talabi API Documentation")
        .WithDefaultHttpClient(ScalarTarget.CSharp, ScalarClient.HttpClient)
        .WithTheme(ScalarTheme.BluePlanet)
        .WithOpenApiRoutePattern("/swagger/v1/swagger.json"); // Swagger spec kullan
});

// Root path'i Scalar'a yönlendir (Scalar default path: /scalar/v1)
// Kullanıcı root path'e geldiğinde direkt Scalar dokümantasyonu açılır
app.MapGet("/", () => Results.Redirect("/scalar/v1", permanent: false));

app.MapControllers();
app.MapHub<Talabi.Api.Hubs.NotificationHub>("/hubs/notifications");

// Health Checks endpoints
app.MapHealthChecks("/health", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    ResponseWriter = async (context, report) =>
    {
        context.Response.ContentType = "application/json";

        // Production'da hassas bilgileri gizle
        var isDevelopment = app.Environment.IsDevelopment();

        var result = System.Text.Json.JsonSerializer.Serialize(new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString(),
                description = e.Value.Description,
                // Production'da data ve exception detaylarını gizle
                data = isDevelopment ? e.Value.Data : new Dictionary<string, object>(),
                duration = e.Value.Duration.TotalMilliseconds,
                // Exception detaylarını sadece development'ta göster
                exception = isDevelopment && e.Value.Exception != null ? e.Value.Exception.Message : null
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

        // Production'da hassas bilgileri gizle - sadece status bilgisi
        var result = System.Text.Json.JsonSerializer.Serialize(new
        {
            status = report.Status.ToString(),
            checks = report.Entries.Select(e => new
            {
                name = e.Key,
                status = e.Value.Status.ToString()
                // Description ve diğer detayları production'da gizle
            })
        });
        await context.Response.WriteAsync(result);
    }
});

app.MapHealthChecks("/health/live", new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    Predicate = _ => false, // Sadece uygulamanın çalıştığını kontrol et
    ResponseWriter = async (context, _) =>
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

// Hangfire Dashboard with authentication
app.UseHangfireDashboard("/hangfire", new DashboardOptions
{
    Authorization = new[] { new HangfireAuthorizationFilter() },
    DashboardTitle = "Talabi Background Jobs",
    StatsPollingInterval = 2000,
    DisplayStorageConnectionString = false, // Security: Don't display connection string
    IgnoreAntiforgeryToken = false
});

// Schedule Recurring Jobs
RecurringJob.AddOrUpdate<IBackgroundJobService>(
    "check-abandoned-carts",
    service => service.CheckAbandonedCarts(),
    Cron.Hourly);

app.Run();