using FluentValidation;
using Microsoft.Extensions.Options;
using Talabi.Core.DTOs;
using Talabi.Core.Options;

namespace Talabi.Api.Validators;

public class VendorRegisterDtoValidator : AbstractValidator<VendorRegisterDto>
{
    public VendorRegisterDtoValidator(IOptions<PasswordPolicyOptions> passwordPolicyOptions)
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format");

        RuleFor(x => x.Password)
            .ValidatePassword(passwordPolicyOptions);

        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Full Name is required");

        RuleFor(x => x.BusinessName)
            .NotEmpty().WithMessage("Business Name is required");

        RuleFor(x => x.Phone)
            .NotEmpty().WithMessage("Phone is required")
            .Matches(@"^\+?[1-9]\d{1,14}$").WithMessage("Invalid phone number format");

        RuleFor(x => x.VendorType)
            .IsInEnum().WithMessage("Invalid vendor type");
    }
}

