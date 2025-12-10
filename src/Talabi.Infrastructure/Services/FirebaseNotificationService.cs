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

                    // 1. Öncelik: Environment Variable (JSON dosyası path'i)
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

                    // 2. İkinci öncelik: appsettings.json'dan JSON içeriği (string olarak)
                    var credentialJson = _configuration["Firebase:CredentialJson"];
                    if (!string.IsNullOrEmpty(credentialJson))
                    {
                        try
                        {
                            FirebaseApp.Create(new AppOptions()
                            {
                                Credential = GoogleCredential.FromJson(credentialJson)
                            });
                            _logger.LogInformation("✅ Firebase initialized from APPSETTINGS.JSON (JSON content)");
                            return;
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning("⚠️ Failed to parse Firebase:CredentialJson: {Message}", ex.Message);
                        }
                    }

                    // 3. Üçüncü öncelik: appsettings.json'dan JSON dosyası path'i
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
                            _logger.LogInformation("✅ Firebase initialized from APPSETTINGS.JSON (file path): {Path}", credentialPath);
                            return;
                        }
                        else
                        {
                            _logger.LogWarning("⚠️ Firebase credential file not found at configured path: {Path}", credentialPath);
                        }
                    }

                    // 4. Dördüncü öncelik: Default konumlar
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

                    // 5. Son çare: Google Cloud Default Credentials
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
                    _logger.LogError("   1. Set GOOGLE_APPLICATION_CREDENTIALS environment variable (JSON file path)");
                    _logger.LogError("   2. Configure Firebase:CredentialJson in appsettings.json (JSON content as string)");
                    _logger.LogError("   3. Configure Firebase:CredentialPath in appsettings.json (JSON file path)");
                    _logger.LogError("   4. Place firebase-adminsdk.json in application directory");
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

        public async Task SendNotificationAsync(string token, string title, string body, object? data = null)
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

            // Firebase'in initialize edilip edilmediğini kontrol et
            if (FirebaseMessaging.DefaultInstance == null)
            {
                _logger.LogError("Firebase is not initialized. Cannot send notification.");
                return;
            }

            try
            {
                string response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
                _logger.LogInformation($"Successfully sent message: {response}");
            }
            catch (FirebaseMessagingException ex)
            {
                _logger.LogError(ex, $"Firebase error sending notification: {ex.Message}");
                
                // Handle invalid token - remove from database
                if (ex.MessagingErrorCode == MessagingErrorCode.InvalidArgument ||
                    ex.MessagingErrorCode == MessagingErrorCode.Unregistered)
                {
                    _logger.LogWarning($"Removing invalid token from database: {token}");
                    var invalidToken = await _context.UserDeviceTokens
                        .FirstOrDefaultAsync(t => t.FcmToken == token);
                    if (invalidToken != null)
                    {
                        _context.UserDeviceTokens.Remove(invalidToken);
                        await _context.SaveChangesAsync();
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending notification: {ex.Message}");
            }
        }

        public async Task SendMulticastNotificationAsync(List<string> tokens, string title, string body, object? data = null)
        {
            // Firebase'in initialize edilip edilmediğini kontrol et
            if (FirebaseMessaging.DefaultInstance == null)
            {
                _logger.LogError("Firebase is not initialized. Cannot send multicast notification.");
                return;
            }

            if (tokens == null || tokens.Count == 0)
            {
                _logger.LogWarning("No tokens provided for multicast notification");
                return;
            }

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
                // Use SendEachForMulticastAsync instead of obsolete SendMulticastAsync
                var response = await FirebaseMessaging.DefaultInstance.SendEachForMulticastAsync(message);
                _logger.LogInformation($"{response.SuccessCount} messages were sent successfully out of {tokens.Count}");
                
                // Handle failed tokens - remove invalid tokens from database
                if (response.FailureCount > 0)
                {
                    _logger.LogWarning($"{response.FailureCount} messages failed to send");
                    
                    var invalidTokens = new List<string>();
                    for (int i = 0; i < response.Responses.Count; i++)
                    {
                        var sendResponse = response.Responses[i];
                        if (!sendResponse.IsSuccess && sendResponse.Exception is FirebaseMessagingException ex)
                        {
                            // Handle invalid token errors
                            if (ex.MessagingErrorCode == MessagingErrorCode.InvalidArgument ||
                                ex.MessagingErrorCode == MessagingErrorCode.Unregistered)
                            {
                                invalidTokens.Add(tokens[i]);
                                _logger.LogWarning($"Invalid token detected: {tokens[i]} - {ex.Message}");
                            }
                        }
                    }
                    
                    // Remove invalid tokens from database
                    if (invalidTokens.Any())
                    {
                        var tokensToRemove = await _context.UserDeviceTokens
                            .Where(t => invalidTokens.Contains(t.FcmToken))
                            .ToListAsync();
                        
                        if (tokensToRemove.Any())
                        {
                            _context.UserDeviceTokens.RemoveRange(tokensToRemove);
                            await _context.SaveChangesAsync();
                            _logger.LogInformation($"Removed {tokensToRemove.Count} invalid tokens from database");
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error sending multicast notification: {ex.Message}");
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
            var title = _resourceManager?.GetString("NewOrderAssignedTitle", culture) ?? "New Order Assigned! 🚀";
            var bodyTemplate = _resourceManager?.GetString("NewOrderAssignedBody", culture) ?? "Order #{0} has been assigned to you. Check it out now!";
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

            var title = _resourceManager?.GetString(titleKey, culture) ?? "Order Update";
            var bodyTemplate = _resourceManager?.GetString(bodyKey, culture) ?? "There's an update on your order #{0}.";
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
