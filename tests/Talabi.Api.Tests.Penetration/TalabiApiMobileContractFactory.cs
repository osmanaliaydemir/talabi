using System.Collections.Concurrent;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Talabi.Core.DTOs.Email;
using Talabi.Core.Interfaces;
using Talabi.Core.Services;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Tests.Penetration;

/// <summary>
/// Test host tailored for mobile contract tests.
/// Uses InMemory EF Core and stubs external dependencies to keep tests deterministic.
/// </summary>
public sealed class TalabiApiMobileContractFactory : WebApplicationFactory<Talabi.Api.Program>
{
    public CapturingEmailSender EmailSender { get; } = new();
    private readonly string _dbName = $"talabi_test_{Guid.NewGuid():N}";

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Test");

        builder.ConfigureAppConfiguration((_, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Testing:DisableHangfire"] = "true",
                ["Testing:UseInMemoryDatabase"] = "true",
                ["Testing:InMemoryDatabaseName"] = _dbName,
                // Ensure JWT settings exist for successful login flows in tests.
                ["JwtSettings:Secret"] = "test_secret_test_secret_test_secret_test_secret",
                ["JwtSettings:Issuer"] = "Talabi.Test",
                ["JwtSettings:Audience"] = "Talabi.Test",
                ["JwtSettings:ExpirationInMinutes"] = "60"
            });
        });

        builder.ConfigureServices(services =>
        {
            // Stub external services (email, verification security, notifications).
            services.RemoveAll<IEmailSender>();
            services.AddSingleton<IEmailSender>(EmailSender);

            services.RemoveAll<IVerificationCodeSecurityService>();
            services.AddSingleton<IVerificationCodeSecurityService, PermissiveVerificationCodeSecurityService>();

            services.RemoveAll<INotificationService>();
            services.AddSingleton<INotificationService, NoopNotificationService>();

            // Keep token verifier but make it deterministic if ever called.
            services.RemoveAll<IExternalAuthTokenVerifier>();
            services.AddSingleton<IExternalAuthTokenVerifier, AlwaysInvalidExternalAuthTokenVerifier>();
        });
    }
}

public sealed class CapturingEmailSender : IEmailSender
{
    private readonly ConcurrentDictionary<string, string> _lastVerificationCodeByEmail = new(StringComparer.OrdinalIgnoreCase);

    public Task SendEmailAsync(EmailTemplateRequest request, CancellationToken cancellationToken = default)
    {
        if (request.Variables.TryGetValue("verificationCode", out var code) && !string.IsNullOrWhiteSpace(code))
        {
            _lastVerificationCodeByEmail[request.To] = code;
        }

        return Task.CompletedTask;
    }

    public string? GetLastVerificationCode(string email)
        => _lastVerificationCodeByEmail.TryGetValue(email, out var code) ? code : null;
}

public sealed class PermissiveVerificationCodeSecurityService : IVerificationCodeSecurityService
{
    public Task<bool> CanAttemptVerificationAsync(string email) => Task.FromResult(true);
    public Task RecordFailedAttemptAsync(string email) => Task.CompletedTask;
    public Task RecordSuccessAsync(string email) => Task.CompletedTask;
    public Task<int> GetRemainingAttemptsAsync(string email) => Task.FromResult(999);
    public Task<DateTime?> GetLockoutExpirationAsync(string email) => Task.FromResult<DateTime?>(null);
}

public sealed class NoopNotificationService : INotificationService
{
    public Task SendNotificationAsync(string token, string title, string body, object? data = null) => Task.CompletedTask;

    public Task SendMulticastNotificationAsync(List<string> tokens, string title, string body, object? data = null) =>
        Task.CompletedTask;

    public Task RegisterDeviceTokenAsync(string userId, string token, string deviceType) => Task.CompletedTask;

    public Task SendOrderAssignmentNotificationAsync(string userId, Guid orderId, string? languageCode = null) =>
        Task.CompletedTask;

    public Task SendOrderStatusUpdateNotificationAsync(string userId, Guid orderId, string status,
        string? languageCode = null) => Task.CompletedTask;

    public Task SendNewOrderNotificationAsync(string userId, Guid orderId, string? languageCode = null) =>
        Task.CompletedTask;

    public Task SendCourierAcceptedNotificationAsync(string userId, Guid orderId, string? languageCode = null) =>
        Task.CompletedTask;
}

public sealed class AlwaysInvalidExternalAuthTokenVerifier : IExternalAuthTokenVerifier
{
    public Task<bool> VerifyTokenAsync(string provider, string token, string? email = null) => Task.FromResult(false);
    public Task<string?> GetEmailFromTokenAsync(string provider, string token) => Task.FromResult<string?>(null);
}

