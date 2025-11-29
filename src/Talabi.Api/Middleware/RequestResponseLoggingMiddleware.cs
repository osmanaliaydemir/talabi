using System.Diagnostics;
using System.Security.Claims;
using System.Text;
using Talabi.Core.Entities;
using Talabi.Infrastructure.Data;

namespace Talabi.Api.Middleware
{
    public class RequestResponseLoggingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly IServiceScopeFactory _serviceScopeFactory;
        private readonly ILogger<RequestResponseLoggingMiddleware> _logger;

        public RequestResponseLoggingMiddleware(RequestDelegate next, IServiceScopeFactory serviceScopeFactory, ILogger<RequestResponseLoggingMiddleware> logger)
        {
            _next = next;
            _serviceScopeFactory = serviceScopeFactory;
            _logger = logger;
        }

        public async Task Invoke(HttpContext context)
        {
            var stopwatch = Stopwatch.StartNew();
            var requestBodyContent = await ReadRequestBody(context.Request);
            var originalBodyStream = context.Response.Body;

            using var responseBody = new MemoryStream();
            context.Response.Body = responseBody;

            Exception? exception = null;

            try
            {
                await _next(context);
            }
            catch (Exception ex)
            {
                exception = ex;
                throw; // Re-throw to let global exception handler handle it, but we log it here too
            }
            finally
            {
                stopwatch.Stop();

                var responseBodyContent = await ReadResponseBody(responseBody);
                await responseBody.CopyToAsync(originalBodyStream);

                await LogActivity(context, requestBodyContent, responseBodyContent, stopwatch.ElapsedMilliseconds, exception);
            }
        }

        private async Task<string> ReadRequestBody(HttpRequest request)
        {
            request.EnableBuffering();

            using var reader = new StreamReader(request.Body, Encoding.UTF8, true, 1024, true);
            var body = await reader.ReadToEndAsync();
            request.Body.Position = 0;

            return body;
        }

        private async Task<string> ReadResponseBody(Stream responseBody)
        {
            responseBody.Seek(0, SeekOrigin.Begin);
            var text = await new StreamReader(responseBody).ReadToEndAsync();
            responseBody.Seek(0, SeekOrigin.Begin);

            return text;
        }

        private async Task LogActivity(HttpContext context, string requestBody, string responseBody, long durationMs, Exception? exception)
        {
            try
            {
                using var scope = _serviceScopeFactory.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<TalabiDbContext>();

                var userId = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var userEmail = context.User?.FindFirst(ClaimTypes.Email)?.Value;
                var phoneNumber = context.User?.FindFirst(ClaimTypes.MobilePhone)?.Value;

                // Optional: Filter out sensitive data or specific paths (e.g., health checks)
                if (context.Request.Path.StartsWithSegments("/health")) return;

                var log = new UserActivityLog
                {
                    UserId = userId,
                    UserEmail = userEmail,
                    PhoneNumber = phoneNumber,
                    Path = context.Request.Path,
                    Method = context.Request.Method,
                    QueryString = context.Request.QueryString.ToString(),
                    RequestBody = requestBody,
                    ResponseBody = responseBody,
                    StatusCode = context.Response.StatusCode,
                    DurationMs = durationMs,
                    IpAddress = context.Connection.RemoteIpAddress?.ToString(),
                    UserAgent = context.Request.Headers["User-Agent"].ToString(),
                    CreatedAt = DateTime.UtcNow,
                    Exception = exception?.ToString()
                };

                dbContext.UserActivityLogs.Add(log);
                await dbContext.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error logging user activity");
            }
        }
    }
}
