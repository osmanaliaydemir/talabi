using System;

namespace Talabi.Core.Entities
{
    public class UserDeviceToken : BaseEntity
    {
        public string UserId { get; set; } = string.Empty;
        public string FcmToken { get; set; } = string.Empty;
        public string DeviceType { get; set; } = string.Empty; // Android, iOS
        public DateTime LastUpdated { get; set; }

        public UserDeviceToken()
        {
            LastUpdated = DateTime.UtcNow;
        }
    }
}
