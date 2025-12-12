using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Getir.MerchantPortal.Models;
using Microsoft.AspNetCore.Http;

namespace Getir.MerchantPortal.Services;

public interface IFileManagerService
{
    Task<PagedResult<FileUploadResponse>?> GetMerchantFilesAsync(int page, int pageSize, CancellationToken ct = default);
    Task<FileUploadResponse?> UploadMerchantFileAsync(IFormFile file, CancellationToken ct = default);
    Task<bool> DeleteMerchantFileAsync(string containerName, string fileName, CancellationToken ct = default);
}

