using System;

namespace Talabi.Core.DTOs.Courier;

public class SubmitDeliveryProofDto
{
    public string PhotoUrl { get; set; } = string.Empty;
    public string? SignatureUrl { get; set; }
    public string? Notes { get; set; }
}
