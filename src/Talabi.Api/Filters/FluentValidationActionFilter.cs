using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace Talabi.Api.Filters;

/// <summary>
/// Action filter that automatically validates models using FluentValidation
/// </summary>
public class FluentValidationActionFilter : IAsyncActionFilter
{
    private readonly IServiceProvider _serviceProvider;

    public FluentValidationActionFilter(IServiceProvider serviceProvider)
    {
        _serviceProvider = serviceProvider;
    }

    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        // Validate all action arguments
        if (context.ActionArguments != null)
        {
            foreach (var argument in context.ActionArguments.Values)
            {
                if (argument == null)
                {
                    continue;
                }

                var argumentType = argument.GetType();
                
                // Find validator for this type
                var validatorType = typeof(IValidator<>).MakeGenericType(argumentType);
                var validator = _serviceProvider.GetService(validatorType) as IValidator;

                if (validator != null)
                {
                    var validationContext = new ValidationContext<object>(argument);
                    var validationResult = await validator.ValidateAsync(validationContext);

                    if (!validationResult.IsValid)
                    {
                        var errors = validationResult.Errors
                            .GroupBy(e => e.PropertyName)
                            .ToDictionary(
                                g => g.Key,
                                g => g.Select(e => e.ErrorMessage).ToArray()
                            );

                        context.Result = new BadRequestObjectResult(new
                        {
                            message = "Validation failed",
                            errors = errors
                        });

                        return;
                    }
                }
            }
        }

        // Continue to the next filter or action
        await next();
    }
}

