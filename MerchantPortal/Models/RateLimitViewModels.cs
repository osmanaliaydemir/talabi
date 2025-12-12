namespace Getir.MerchantPortal.Models;

public class RateLimitAdminViewModel
{
    public List<RateLimitRuleResponse> Rules { get; set; } = new();
    public RateLimitSearchResponseModel? LogSearch { get; set; }
    public RateLimitCheckResponseModel? Status { get; set; }
    public string? EndpointQuery { get; set; }
    public string HttpMethodQuery { get; set; } = "GET";
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}

