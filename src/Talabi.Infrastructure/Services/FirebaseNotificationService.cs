using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;
using System.Globalization;
using System.Resources;

namespace Talabi.Infrastructure.Services
{
    public class FirebaseNotificationService : INotificationService
    {
        private readonly TalabiDbContext _context;
        private readonly ILogger<FirebaseNotificationService> _logger;
        private readonly ResourceManager _resourceManager;
        private readonly IConfiguration _configuration;

        public FirebaseNotificationService(
            TalabiDbContext context,
            ILogger<FirebaseNotificationService> logger,
            IConfiguration configuration)
        {
            _context = context;
            _logger = logger;
            _configuration = configuration;

            // Try to load resources from Talabi.Api assembly
            try
            {
                var apiAssembly = AppDomain.CurrentDomain.GetAssemblies()
                    .FirstOrDefault(a => a.GetName().Name == "Talabi.Api");

                if (apiAssembly != null)
                {
                    _resourceManager = new ResourceManager("Talabi.Api.Resources.NotificationResources", apiAssembly);
                }
                else
                {
                    _logger.LogWarning("Could not find Talabi.Api assembly for resource localization");
                    _resourceManager = null!;
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning($"Failed to load notification resources: {ex.Message}");
                _resourceManager = null!;
            }

            if (FirebaseApp.DefaultInstance == null)
            {
                try
                {
                    string? credentialPath = null;

                    // 1. Öncelik: Environment Variable
                    credentialPath = Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS");

                    if (!string.IsNullOrEmpty(credentialPath) && File.Exists(credentialPath))
                    {
                        FirebaseApp.Create(new AppOptions()
                        {
                            Credential = GoogleCredential.FromFile(credentialPath)
                        });
                        _logger.LogInformation("✅ Firebase initialized from ENVIRONMENT VARIABLE: {Path}", credentialPath);
                        return;
                    }

                    // 2. İkinci öncelik: appsettings.json
                    credentialPath = _configuration["Firebase:CredentialPath"];

                    if (!string.IsNullOrEmpty(credentialPath))
                    {
                        // Relative path ise, base directory ile birleştir
                        if (!Path.IsPathRooted(credentialPath))
                        {
                            credentialPath = Path.Combine(AppContext.BaseDirectory, credentialPath);
                        }

                        if (File.Exists(credentialPath))
                        {
                            FirebaseApp.Create(new AppOptions()
                            {
                                Credential = GoogleCredential.FromFile(credentialPath)
                            });
                            _logger.LogInformation("✅ Firebase initialized from APPSETTINGS.JSON: {Path}", credentialPath);
                            return;
                        }
                        else
                        {
                            _logger.LogWarning("⚠️ Firebase credential file not found at configured path: {Path}", credentialPath);
                        }
                    }

                    // 3. Üçüncü öncelik: Default konumlar
                    var defaultPaths = new[]
                    {
                        Path.Combine(AppContext.BaseDirectory, "firebase-adminsdk.json"),
                        Path.Combine(AppContext.BaseDirectory, "credentials", "firebase-adminsdk.json"),
                        Path.Combine(Directory.GetCurrentDirectory(), "firebase-adminsdk.json")
                    };

                    foreach (var path in defaultPaths)
                    {
                        if (File.Exists(path))
                        {
                            FirebaseApp.Create(new AppOptions()
                            {
                                Credential = GoogleCredential.FromFile(path)
                            });
                            _logger.LogInformation("✅ Firebase initialized from DEFAULT LOCATION: {Path}", path);
                            return;
                        }
                    }

                    // 4. Son çare: Google Cloud Default Credentials
                    FirebaseApp.Create(new AppOptions()
                    {
                        Credential = GoogleCredential.GetApplicationDefault()
                    });
                    _logger.LogInformation("✅ Firebase initialized with GOOGLE CLOUD DEFAULT CREDENTIALS");
                }
                catch (Exception ex)
                {
                    _logger.LogError("❌ Firebase initialization failed: {Message}. Push notifications will NOT work!", ex.Message);
                    _logger.LogError("💡 Please configure Firebase credentials in one of these ways:");
                    _logger.LogError("   1. Set GOOGLE_APPLICATION_CREDENTIALS environment variable");
                    _logger.LogError("   2. Configure Firebase:CredentialPath in appsettings.json");
                    _logger.LogError("   3. Place firebase-adminsdk.json in application directory");
                }
            }
        }

        public async Task RegisterDeviceTokenAsync(string userId, string token, string deviceType)
        {
            var existingToken = await _context.UserDeviceTokens
                .FirstOrDefaultAsync(t => t.UserId == userId && t.FcmToken == token);

            if (existingToken != null)
            {
                existingToken.LastUpdated = DateTime.UtcNow;
                _context.UserDeviceTokens.Update(existingToken);
            }
            else
            {
                var newToken = new UserDeviceToken
                {
                    UserId = userId,
                    FcmToken = token,
                    DeviceType = deviceType,
                    LastUpdated = DateTime.UtcNow
                };
                await _context.UserDeviceTokens.AddAsync(newToken);
            }

            await _context.SaveChangesAsync();
        }

        public async Task SendNotificationAsync(string token, string title, string body, object data = null)
        {
            var message = new Message()
            {
                Token = token,
                Notification = new Notification()
                {
                    Title = title,
                    Body = body
                },
                Data = data != null ? ConvertData(data) : null
            };

            try
            {
                string response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
                _logger.LogInformation($"Successfully sent message: {response}");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error sending notification: {ex.Message}");
                // TODO: Handle invalid token (remove from DB)
            }
        }

        public async Task SendMulticastNotificationAsync(List<string> tokens, string title, string body, object data = null)
        {
            var message = new MulticastMessage()
            {
                Tokens = tokens,
                Notification = new Notification()
                {
                    Title = title,
                    Body = body
                },
                Data = data != null ? ConvertData(data) : null
            };

            try
            {
                var response = await FirebaseMessaging.DefaultInstance.SendMulticastAsync(message);
                _logger.LogInformation($"{response.SuccessCount} messages were sent successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError($"Error sending multicast notification: {ex.Message}");
            }
        }

        public async Task SendOrderAssignmentNotificationAsync(string userId, Guid orderId, string? languageCode = null)
        {
            var tokens = await _context.UserDeviceTokens
                .Where(t => t.UserId == userId)
                .Select(t => t.FcmToken)
                .ToListAsync();

            if (!tokens.Any())
            {
                _logger.LogWarning($"No device tokens found for user {userId}");
                return;
            }

            // Get user's preferred language if not provided
            if (string.IsNullOrEmpty(languageCode))
            {
                languageCode = await GetUserLanguageAsync(userId);
            }

            var culture = GetCultureInfo(languageCode);
            var title = _resourceManager.GetString("NewOrderAssignedTitle", culture) ?? "New Order Assigned! 🚀";
            var bodyTemplate = _resourceManager.GetString("NewOrderAssignedBody", culture) ?? "Order #{0} has been assigned to you. Check it out now!";
            var body = string.Format(bodyTemplate, orderId);

            await SendMulticastNotificationAsync(
                tokens,
                title,
                body,
                new { type = "order_assigned", orderId = orderId }
            );
        }

        public async Task SendOrderStatusUpdateNotificationAsync(string userId, Guid orderId, string status, string? languageCode = null)
        {
            var tokens = await _context.UserDeviceTokens
                .Where(t => t.UserId == userId)
                .Select(t => t.FcmToken)
                .ToListAsync();

            if (!tokens.Any())
            {
                _logger.LogWarning($"No device tokens found for user {userId}");
                return;
            }

            // Get user's preferred language if not provided
            if (string.IsNullOrEmpty(languageCode))
            {
                languageCode = await GetUserLanguageAsync(userId);
            }

            var culture = GetCultureInfo(languageCode);
            var (title, body) = GetStatusNotificationText(status, orderId, culture);

            await SendMulticastNotificationAsync(
                tokens,
                title,
                body,
                new { type = "order_status_update", orderId = orderId, status = status }
            );
        }

        private async Task<string> GetUserLanguageAsync(string userId)
        {
            var userPreference = await _context.UserPreferences
                .Where(up => up.UserId == userId)
                .Select(up => up.Language)
                .FirstOrDefaultAsync();

            return userPreference ?? "tr"; // Default to Turkish
        }

        private CultureInfo GetCultureInfo(string languageCode)
        {
            try
            {
                return new CultureInfo(languageCode);
            }
            catch
            {
                return new CultureInfo("tr"); // Fallback to Turkish
            }
        }

        private (string title, string body) GetStatusNotificationText(string status, Guid orderId, CultureInfo culture)
        {
            var titleKey = status switch
            {
                "Ready" => "OrderReadyTitle",
                "Delivered" => "OrderDeliveredTitle",
                "Assigned" => "OrderAssignedTitle",
                "Accepted" => "OrderAcceptedTitle",
                "OutForDelivery" => "OrderOutForDeliveryTitle",
                _ => "OrderUpdateTitle"
            };

            var bodyKey = status switch
            {
                "Ready" => "OrderReadyBody",
                "Delivered" => "OrderDeliveredBody",
                "Assigned" => "OrderAssignedBody",
                "Accepted" => "OrderAcceptedBody",
                "OutForDelivery" => "OrderOutForDeliveryBody",
                _ => "OrderUpdateBody"
            };

            var title = _resourceManager.GetString(titleKey, culture) ?? "Order Update";
            var bodyTemplate = _resourceManager.GetString(bodyKey, culture) ?? "There's an update on your order #{0}.";
            var body = string.Format(bodyTemplate, orderId);

            return (title, body);
        }

        private Dictionary<string, string> ConvertData(object data)
        {
            var dictionary = new Dictionary<string, string>();
            foreach (var prop in data.GetType().GetProperties())
            {
                var value = prop.GetValue(data)?.ToString();
                if (value != null)
                {
                    dictionary.Add(prop.Name, value);
                }
            }
            return dictionary;
        }
    }
}
