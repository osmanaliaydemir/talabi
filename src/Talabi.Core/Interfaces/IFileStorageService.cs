using Microsoft.AspNetCore.Http;

namespace Talabi.Core.Interfaces;

public interface IFileStorageService
{
    /// <summary>
    /// Uploads a file and returns the relative URL/Path
    /// </summary>
    Task<string> SaveFileAsync(IFormFile file, string folderName, CancellationToken cancellationToken = default);

    /// <summary>
    /// Deletes a file by its path
    /// </summary>
    Task DeleteFileAsync(string filePath, CancellationToken cancellationToken = default);
}
