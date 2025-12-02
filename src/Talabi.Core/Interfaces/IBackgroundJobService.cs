using System.Threading.Tasks;

namespace Talabi.Core.Interfaces
{
    public interface IBackgroundJobService
    {
        Task CheckAbandonedCarts();
        Task NotifyNewVendor(Guid vendorId);
        Task NotifyNewProduct(Guid productId);
    }
}
