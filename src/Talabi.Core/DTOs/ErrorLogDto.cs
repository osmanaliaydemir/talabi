using System;
using System.Collections.Generic;

namespace Talabi.Core.DTOs
{
    /// <summary>
    /// Error log request DTO - Mobile'dan gelen log kayıtları
    /// </summary>
    public class ErrorLogRequestDto
    {
        public List<ErrorLogItemDto> Logs { get; set; } = new();
    }

    /// <summary>
    /// Tek bir error log kaydı
    /// </summary>
    public class ErrorLogItemDto
    {
        public string Id { get; set; } = string.Empty;
        public string Level { get; set; } = string.Empty;
        public string Message { get; set; } = string.Empty;
        public string? Error { get; set; }
        public string? StackTrace { get; set; }
        public DateTime Timestamp { get; set; }
        public Dictionary<string, object>? Metadata { get; set; }
        public string? UserId { get; set; }
        public string? DeviceInfo { get; set; }
        public string? AppVersion { get; set; }
    }
}

