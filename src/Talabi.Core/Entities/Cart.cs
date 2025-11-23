namespace Talabi.Core.Entities;

public class Cart : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public AppUser? User { get; set; }
    public ICollection<CartItem> CartItems { get; set; } = new List<CartItem>();
}
