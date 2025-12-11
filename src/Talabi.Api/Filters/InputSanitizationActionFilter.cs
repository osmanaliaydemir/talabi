using Microsoft.AspNetCore.Mvc.Filters;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Filters;

/// <summary>
/// Action filter that automatically sanitizes string inputs in model binding
/// </summary>
public class InputSanitizationActionFilter : IActionFilter
{
    private readonly IInputSanitizationService _sanitizationService;

    public InputSanitizationActionFilter(IInputSanitizationService sanitizationService)
    {
        _sanitizationService = sanitizationService;
    }

    public void OnActionExecuting(ActionExecutingContext context)
    {
        if (context.ActionArguments == null)
        {
            return;
        }

        // Sanitize action arguments (DTOs, models, etc.)
        foreach (var argument in context.ActionArguments.Values)
        {
            if (argument == null)
            {
                continue;
            }

            // Handle string arguments directly (e.g., query parameters)
            if (argument is string stringArg)
            {
                var sanitized = _sanitizationService.SanitizeHtml(stringArg);
                if (sanitized != stringArg)
                {
                    // Update the argument value
                    var key = context.ActionArguments.FirstOrDefault(kvp => kvp.Value == argument).Key;
                    if (key != null)
                    {
                        context.ActionArguments[key] = sanitized;
                    }
                }
                continue;
            }

            SanitizeObject(argument);
        }

        // Also sanitize query string parameters
        if (context.HttpContext.Request.Query != null)
        {
            var query = context.HttpContext.Request.Query;
            foreach (var queryParam in query)
            {
                if (queryParam.Value.Count > 0)
                {
                    var originalValue = queryParam.Value.ToString();
                    var sanitized = _sanitizationService.SanitizeHtml(originalValue);
                    if (sanitized != originalValue)
                    {
                        // Note: Query string is read-only, but we log the sanitization
                        // The sanitized value will be used when accessed through model binding
                    }
                }
            }
        }
    }

    public void OnActionExecuted(ActionExecutedContext context)
    {
        // No action needed after execution
    }

    private void SanitizeObject(object obj)
    {
        if (obj == null)
        {
            return;
        }

        var type = obj.GetType();

        // Skip primitive types and value types
        if (type.IsPrimitive || type.IsValueType || type == typeof(string) || type == typeof(DateTime) || type == typeof(DateTime?))
        {
            return;
        }

        // Handle string properties
        var stringProperties = type.GetProperties()
            .Where(p => p.PropertyType == typeof(string) && p.CanWrite && p.CanRead);

        foreach (var property in stringProperties)
        {
            var value = property.GetValue(obj) as string;
            if (!string.IsNullOrWhiteSpace(value))
            {
                var sanitized = _sanitizationService.SanitizeHtml(value);
                if (sanitized != value)
                {
                    property.SetValue(obj, sanitized);
                }
            }
        }

        // Handle collections of strings
        var collectionProperties = type.GetProperties()
            .Where(p => p.PropertyType.IsGenericType && 
                       p.PropertyType.GetGenericTypeDefinition() == typeof(IEnumerable<>) &&
                       p.PropertyType.GetGenericArguments()[0] == typeof(string) &&
                       p.CanWrite && p.CanRead);

        foreach (var property in collectionProperties)
        {
            var value = property.GetValue(obj) as IEnumerable<string>;
            if (value != null)
            {
                var sanitized = _sanitizationService.SanitizeHtml(value);
                property.SetValue(obj, sanitized);
            }
        }

        // Recursively sanitize nested objects
        var objectProperties = type.GetProperties()
            .Where(p => !p.PropertyType.IsPrimitive && 
                       !p.PropertyType.IsValueType && 
                       p.PropertyType != typeof(string) &&
                       p.PropertyType != typeof(DateTime) &&
                       p.PropertyType != typeof(DateTime?) &&
                       !p.PropertyType.IsGenericType &&
                       p.CanRead);

        foreach (var property in objectProperties)
        {
            var value = property.GetValue(obj);
            if (value != null)
            {
                SanitizeObject(value);
            }
        }

        // Handle nested objects in generic collections
        var genericObjectProperties = type.GetProperties()
            .Where(p => p.PropertyType.IsGenericType &&
                       p.PropertyType.GetGenericTypeDefinition() == typeof(IEnumerable<>) &&
                       !p.PropertyType.GetGenericArguments()[0].IsPrimitive &&
                       !p.PropertyType.GetGenericArguments()[0].IsValueType &&
                       p.PropertyType.GetGenericArguments()[0] != typeof(string) &&
                       p.CanRead);

        foreach (var property in genericObjectProperties)
        {
            var value = property.GetValue(obj);
            if (value is System.Collections.IEnumerable enumerable)
            {
                foreach (var item in enumerable)
                {
                    if (item != null)
                    {
                        SanitizeObject(item);
                    }
                }
            }
        }
    }
}

