using FluentValidation;
using Microsoft.Extensions.Options;
using Talabi.Core.DTOs;
using Talabi.Core.Options;

namespace Talabi.Api.Validators;

public class CourierRegisterDtoValidator : AbstractValidator<CourierRegisterDto>
{
    public CourierRegisterDtoValidator(IOptions<PasswordPolicyOptions> passwordPolicyOptions)
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format");

        RuleFor(x => x.Password)
            .ValidatePassword(passwordPolicyOptions);

        RuleFor(x => x.FullName)
            .NotEmpty().WithMessage("Full Name is required");

        RuleFor(x => x.Phone)
            .Matches(@"^\+?[1-9]\d{1,14}$").WithMessage("Invalid phone number format")
            .When(x => !string.IsNullOrEmpty(x.Phone));
    }
}

