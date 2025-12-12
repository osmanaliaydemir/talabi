using System.ComponentModel.DataAnnotations;

namespace Talabi.Portal.Models;

public class VendorCategoryDto
{
    public string Name { get; set; } = string.Empty;
    public int ProductCount { get; set; }
}

public class UpdateCategoryDto
{
    [Required]
    public string OldName { get; set; } = string.Empty;
    [Required]
    public string NewName { get; set; } = string.Empty;
}
