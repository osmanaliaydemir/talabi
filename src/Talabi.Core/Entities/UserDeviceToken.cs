using System;

namespace Talabi.Core.Entities
{
    public class UserDeviceToken : BaseEntity
    {
        public string UserId { get; set; }
        public string FcmToken { get; set; }
        public string DeviceType { get; set; } // Android, iOS
        public DateTime LastUpdated { get; set; }

        public UserDeviceToken()
        {
            LastUpdated = DateTime.UtcNow;
        }
    }
}
