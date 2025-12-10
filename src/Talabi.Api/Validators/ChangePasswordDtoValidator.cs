using FluentValidation;
using Microsoft.Extensions.Options;
using Talabi.Core.DTOs;
using Talabi.Core.Options;

namespace Talabi.Api.Validators;

public class ChangePasswordDtoValidator : AbstractValidator<ChangePasswordDto>
{
    public ChangePasswordDtoValidator(IOptions<PasswordPolicyOptions> passwordPolicyOptions)
    {
        RuleFor(x => x.CurrentPassword)
            .NotEmpty().WithMessage("Current password is required");

        RuleFor(x => x.NewPassword)
            .ValidatePassword(passwordPolicyOptions)
            .Must((dto, newPassword) => newPassword != dto.CurrentPassword)
            .WithMessage("New password must be different from current password");
    }
}

