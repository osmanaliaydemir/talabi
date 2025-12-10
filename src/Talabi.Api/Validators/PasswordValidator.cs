using FluentValidation;
using Microsoft.Extensions.Options;
using Talabi.Core.Options;

namespace Talabi.Api.Validators;

/// <summary>
/// Reusable password validation helper for FluentValidation
/// </summary>
public static class PasswordValidator
{
    /// <summary>
    /// Configures password validation rules for a FluentValidation rule builder
    /// </summary>
    public static IRuleBuilderOptions<T, string> ValidatePassword<T>(
        this IRuleBuilder<T, string> ruleBuilder,
        IOptions<PasswordPolicyOptions>? passwordPolicyOptions = null)
    {
        var policy = passwordPolicyOptions?.Value ?? new PasswordPolicyOptions();

        return ruleBuilder
            .NotEmpty().WithMessage("Password is required")
            .MinimumLength(policy.MinimumLength)
                .WithMessage($"Password must be at least {policy.MinimumLength} characters")
            .Must(password => !policy.RequireDigit || password.Any(char.IsDigit))
                .WithMessage("Password must contain at least one digit (0-9)")
            .Must(password => !policy.RequireLowercase || password.Any(char.IsLower))
                .WithMessage("Password must contain at least one lowercase letter (a-z)")
            .Must(password => !policy.RequireUppercase || password.Any(char.IsUpper))
                .WithMessage("Password must contain at least one uppercase letter (A-Z)")
            .Must(password => !policy.RequireNonAlphanumeric || password.Any(ch => !char.IsLetterOrDigit(ch)))
                .WithMessage("Password must contain at least one special character (!@#$%^&* etc.)");
    }

    /// <summary>
    /// Validates password against policy and returns validation errors
    /// </summary>
    public static List<string> ValidatePasswordPolicy(string password, PasswordPolicyOptions? policy = null)
    {
        var errors = new List<string>();
        policy ??= new PasswordPolicyOptions();

        if (string.IsNullOrEmpty(password))
        {
            errors.Add("Password is required");
            return errors;
        }

        if (password.Length < policy.MinimumLength)
        {
            errors.Add($"Password must be at least {policy.MinimumLength} characters");
        }

        if (policy.RequireDigit && !password.Any(char.IsDigit))
        {
            errors.Add("Password must contain at least one digit (0-9)");
        }

        if (policy.RequireLowercase && !password.Any(char.IsLower))
        {
            errors.Add("Password must contain at least one lowercase letter (a-z)");
        }

        if (policy.RequireUppercase && !password.Any(char.IsUpper))
        {
            errors.Add("Password must contain at least one uppercase letter (A-Z)");
        }

        if (policy.RequireNonAlphanumeric && !password.Any(ch => !char.IsLetterOrDigit(ch)))
        {
            errors.Add("Password must contain at least one special character (!@#$%^&* etc.)");
        }

        return errors;
    }
}

