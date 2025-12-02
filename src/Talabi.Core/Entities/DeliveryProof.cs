namespace Talabi.Core.Entities;

public class DeliveryProof : BaseEntity
{
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }

    public string? PhotoUrl { get; set; }
    public string? SignatureUrl { get; set; }
    public string? Notes { get; set; }
    public DateTime ProofSubmittedAt { get; set; } = DateTime.UtcNow;
}
