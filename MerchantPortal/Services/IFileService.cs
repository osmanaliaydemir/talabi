using Getir.MerchantPortal.Models;

namespace Getir.MerchantPortal.Services;

public interface IFileService
{
	Task<FileUploadResponse?> UploadMerchantFileAsync(Stream stream, string fileName, string contentType, CancellationToken ct = default);
}


