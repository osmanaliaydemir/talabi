namespace Talabi.Core.DTOs;

public class ValidateCouponRequest
{
    public string Code { get; set; } = string.Empty;
    public Guid? CityId { get; set; }
    public Guid? DistrictId { get; set; }
}
