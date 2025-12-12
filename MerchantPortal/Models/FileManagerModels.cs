using System.Collections.Generic;

namespace Getir.MerchantPortal.Models;

public class FileManagerViewModel
{
    public PagedResult<FileUploadResponse> Files { get; set; } = new()
    {
        Items = new List<FileUploadResponse>()
    };
}

