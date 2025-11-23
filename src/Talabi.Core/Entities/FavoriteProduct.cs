namespace Talabi.Core.Entities;

public class FavoriteProduct : BaseEntity
{
    public string UserId { get; set; } = string.Empty;
    public AppUser? User { get; set; }
    
    public int ProductId { get; set; }
    public Product? Product { get; set; }
}
