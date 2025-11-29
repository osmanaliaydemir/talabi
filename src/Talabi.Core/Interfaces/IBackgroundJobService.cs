using System.Threading.Tasks;

namespace Talabi.Core.Interfaces
{
    public interface IBackgroundJobService
    {
        Task CheckAbandonedCarts();
        Task NotifyNewVendor(int vendorId);
        Task NotifyNewProduct(int productId);
    }
}
