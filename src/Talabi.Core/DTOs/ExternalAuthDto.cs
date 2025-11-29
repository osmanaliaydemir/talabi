namespace Talabi.Core.DTOs
{
    public class ExternalAuthDto
    {
        public string Provider { get; set; } = string.Empty; // "Google", "Apple", "Facebook"
        public string IdToken { get; set; } = string.Empty;
        public string? Email { get; set; }
        public string? FullName { get; set; }
        public string? Language { get; set; }
    }
}
