using System.Diagnostics;
using System.Security.Claims;
using System.Text;
using Microsoft.EntityFrameworkCore;
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
                // Exception'ı context'e ekle ki ExceptionHandlingMiddleware görebilsin
                context.Items["Exception"] = ex;
                throw; // ExceptionHandlingMiddleware'in handle edebilmesi için tekrar throw et
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
                // Health check endpoint'lerini loglama
                if (context.Request.Path.StartsWithSegments("/health")) 
                {
                    return;
                }

                using var scope = _serviceScopeFactory.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<TalabiDbContext>();
                
                // Test database connection
                if (!await dbContext.Database.CanConnectAsync())
                {
                    _logger.LogError("Cannot connect to database! Skipping log save.");
                    return;
                }

                var userId = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                var userEmail = context.User?.FindFirst(ClaimTypes.Email)?.Value;
                var phoneNumber = context.User?.FindFirst(ClaimTypes.MobilePhone)?.Value;

                const int maxBodySize = 50 * 1024; // 50KB
                var truncatedRequestBody = requestBody?.Length > maxBodySize 
                    ? requestBody.Substring(0, maxBodySize) + "... [TRUNCATED]" 
                    : requestBody;
                var truncatedResponseBody = responseBody?.Length > maxBodySize 
                    ? responseBody.Substring(0, maxBodySize) + "... [TRUNCATED]" 
                    : responseBody;

                var log = new UserActivityLog
                {
                    UserId = userId,
                    UserEmail = userEmail,
                    PhoneNumber = phoneNumber,
                    Path = context.Request.Path.ToString(),
                    Method = context.Request.Method,
                    QueryString = context.Request.QueryString.ToString(),
                    RequestBody = truncatedRequestBody,
                    ResponseBody = truncatedResponseBody,
                    StatusCode = context.Response.StatusCode,
                    DurationMs = durationMs,
                    IpAddress = context.Connection.RemoteIpAddress?.ToString(),
                    UserAgent = context.Request.Headers["User-Agent"].ToString(),
                    CreatedAt = DateTime.UtcNow,
                    Exception = exception?.ToString()
                };

                dbContext.UserActivityLogs.Add(log);
                await dbContext.SaveChangesAsync();
                
                _logger.LogDebug("User activity logged: {Path} {Method} {StatusCode} {DurationMs}ms", 
                    log.Path, log.Method, log.StatusCode, log.DurationMs);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, 
                    "Error logging user activity for path: {Path}, method: {Method}, statusCode: {StatusCode}", 
                    context.Request.Path, 
                    context.Request.Method, 
                    context.Response.StatusCode);
            }
        }
    }
}
