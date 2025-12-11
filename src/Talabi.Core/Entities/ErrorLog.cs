using System;

namespace Talabi.Core.Entities
{
    /// <summary>
    /// Mobile uygulamadan gelen error log kayıtları
    /// </summary>
    public class ErrorLog : BaseEntity
    {
        /// <summary>
        /// Log seviyesi (debug, info, warning, error, fatal)
        /// </summary>
        public string Level { get; set; } = string.Empty;

        /// <summary>
        /// Log mesajı
        /// </summary>
        public string Message { get; set; } = string.Empty;

        /// <summary>
        /// Hata detayı (varsa)
        /// </summary>
        public string? Error { get; set; }

        /// <summary>
        /// Stack trace (varsa)
        /// </summary>
        public string? StackTrace { get; set; }

        /// <summary>
        /// Log timestamp (mobile'dan gelen)
        /// </summary>
        public DateTime Timestamp { get; set; }

        /// <summary>
        /// Ek metadata (JSON formatında)
        /// </summary>
        public string? Metadata { get; set; }

        /// <summary>
        /// Kullanıcı ID (varsa)
        /// </summary>
        public string? UserId { get; set; }

        /// <summary>
        /// Device bilgisi (örn: "Android 13 (Samsung Galaxy S21)")
        /// </summary>
        public string? DeviceInfo { get; set; }

        /// <summary>
        /// Uygulama versiyonu (örn: "1.0.0+2")
        /// </summary>
        public string? AppVersion { get; set; }

        /// <summary>
        /// Log ID (mobile'dan gelen unique ID)
        /// </summary>
        public string LogId { get; set; } = string.Empty;
    }
}

