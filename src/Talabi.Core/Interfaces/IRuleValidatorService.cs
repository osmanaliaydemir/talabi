using Talabi.Core.Entities;
using Talabi.Core.Models;

namespace Talabi.Core.Interfaces;

public interface IRuleValidatorService
{
    bool ValidateCampaign(Campaign campaign, RuleValidationContext context, out string? failureReason);
    bool ValidateCoupon(Coupon coupon, RuleValidationContext context, out string? failureReason);
}
