using System.Diagnostics;
using System.Security.Claims;
using System.Text;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Middleware
{
    public class RequestResponseLoggingMiddleware
    {
        private readonly RequestDelegate _next;
        private readonly IActivityLoggingService _activityLoggingService;
        private readonly ILogger<RequestResponseLoggingMiddleware> _logger;

        public RequestResponseLoggingMiddleware(
            RequestDelegate next,
            IActivityLoggingService activityLoggingService,
            ILogger<RequestResponseLoggingMiddleware> logger)
        {
            _next = next;
            _activityLoggingService = activityLoggingService;
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

                // Asenkron logging - fire-and-forget (Hangfire background job)
                LogActivity(context, requestBodyContent, responseBodyContent, stopwatch.ElapsedMilliseconds, exception);
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

        private void LogActivity(HttpContext context, string requestBody, string responseBody, long durationMs, Exception? exception)
        {
            try
            {
                // Health check endpoint'lerini loglama
                if (context.Request.Path.StartsWithSegments("/health")) 
                {
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

                // Asenkron logging - Hangfire background job olarak çalışır
                // Bu sayede request hemen tamamlanır, log kaydı arka planda yazılır
                _activityLoggingService.LogActivityAsync(
                    userId,
                    userEmail,
                    phoneNumber,
                    context.Request.Path.ToString(),
                    context.Request.Method,
                    context.Request.QueryString.ToString(),
                    truncatedRequestBody,
                    truncatedResponseBody,
                    context.Response.StatusCode,
                    durationMs,
                    context.Connection.RemoteIpAddress?.ToString(),
                    context.Request.Headers["User-Agent"].ToString(),
                    exception?.ToString());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, 
                    "Error queueing user activity log for path: {Path}, method: {Method}, statusCode: {StatusCode}", 
                    context.Request.Path, 
                    context.Request.Method, 
                    context.Response.StatusCode);
            }
        }
    }
}
