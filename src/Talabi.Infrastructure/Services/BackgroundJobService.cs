using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;
using System.Globalization;
using System.Resources;

namespace Talabi.Infrastructure.Services
{
    public class BackgroundJobService : IBackgroundJobService
    {
        private readonly TalabiDbContext _context;
        private readonly INotificationService _notificationService;
        private readonly ILogger<BackgroundJobService> _logger;
        private readonly ResourceManager _resourceManager;

        public BackgroundJobService(TalabiDbContext context, INotificationService notificationService, ILogger<BackgroundJobService> logger)
        {
            _context = context;
            _notificationService = notificationService;
            _logger = logger;
            
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
        }

        public async Task CheckAbandonedCarts()
        {
            _logger.LogInformation("Checking for abandoned carts...");

            // Define "abandoned" as updated more than 2 hours ago but less than 24 hours
            var cutoffTime = DateTime.UtcNow.AddHours(-2);
            var limitTime = DateTime.UtcNow.AddHours(-24);

            var abandonedCarts = await _context.Carts.Include(c => c.User).Include(c => c.CartItems)
                .Where(c => c.UpdatedAt.HasValue && c.UpdatedAt.Value <= cutoffTime && c.UpdatedAt.Value >= limitTime && c.CartItems.Any())
                .ToListAsync();

            foreach (var cart in abandonedCarts)
            {
                // Check if we already sent a notification recently (optional, requires tracking)
                // For now, we'll just send it if they have a device token

                var tokens = await _context.UserDeviceTokens.Where(t => t.UserId == cart.UserId).Select(t => t.FcmToken).ToListAsync();

                if (tokens.Any())
                {
                    // Get user's preferred language
                    var userLanguage = await GetUserLanguageAsync(cart.UserId);
                    var culture = new CultureInfo(userLanguage);
                    
                    var title = _resourceManager.GetString("AbandonedCartTitle", culture) ?? "Items in Your Cart! 🛒";
                    var body = _resourceManager.GetString("AbandonedCartBody", culture) ?? "Complete your cart items before they run out.";

                    await _notificationService.SendMulticastNotificationAsync(
                        tokens,
                        title,
                        body,
                        new { type = "cart", cartId = cart.Id }
                    );
                    _logger.LogInformation($"Sent abandoned cart notification to user {cart.UserId}");
                }
            }
        }

        public async Task NotifyNewProduct(int productId)
        {
            var product = await _context.Products.Include(p => p.Vendor).FirstOrDefaultAsync(p => p.Id == productId);

            if (product == null) return;

            // Notify all users (or subscribed users)
            // Warning: Sending to ALL users might be heavy. Ideally use Topics.
            // For this demo, we'll assume we send to a topic "all_users" or just log it.
            // Firebase Topics are better for broadcast.

            // Default language for topic notifications (can be enhanced to send multiple languages)
            var culture = new CultureInfo("tr");
            var title = _resourceManager.GetString("NewProductTitle", culture) ?? "New Product Added! 🎉";
            var bodyTemplate = _resourceManager.GetString("NewProductBody", culture) ?? "{0} added a new product: {1}";
            var body = string.Format(bodyTemplate, product.Vendor.Name, product.Name);

            await _notificationService.SendNotificationAsync("/topics/all_users", // Topic subscription required on mobile
                title, body,
                new { type = "product", productId = productId }
            );
        }

        public async Task NotifyNewVendor(int vendorId)
        {
            var vendor = await _context.Vendors.FindAsync(vendorId);
            if (vendor == null) return;

            // Default language for topic notifications
            var culture = new CultureInfo("tr");
            var title = _resourceManager.GetString("NewVendorTitle", culture) ?? "New Vendor! 🏪";
            var bodyTemplate = _resourceManager.GetString("NewVendorBody", culture) ?? "{0} has joined us. Discover now!";
            var body = string.Format(bodyTemplate, vendor.Name);

            await _notificationService.SendNotificationAsync("/topics/all_users", title, body, 
                new { type = "vendor", vendorId = vendorId });
        }

        private async Task<string> GetUserLanguageAsync(string userId)
        {
            var userPreference = await _context.UserPreferences
                .Where(up => up.UserId == userId)
                .Select(up => up.Language)
                .FirstOrDefaultAsync();

            return userPreference ?? "tr"; // Default to Turkish
        }
    }
}
