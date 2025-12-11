using System;
using System.Linq;
using System.Threading.Tasks;
using Hangfire;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Services;

namespace Talabi.Api.Controllers;

/// <summary>
/// Error log kayıtları için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
public class LogsController : BaseController
{
    /// <summary>
    /// LogsController constructor
    /// </summary>
    public LogsController(IUnitOfWork unitOfWork, ILogger<LogsController> logger,
        ILocalizationService localizationService,IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
    }

    /// <summary>
    /// Mobile uygulamadan gelen error logları kaydet
    /// </summary>
    /// <param name="request">Error log request</param>
    /// <returns>Success response</returns>
    [HttpPost("errors")]
    [AllowAnonymous] // Mobile'dan gelen loglar için authentication gerekmez
    public IActionResult LogErrors([FromBody] ErrorLogRequestDto request)
    {
        try
        {
            if (request == null || request.Logs == null || !request.Logs.Any())
            {
                return BadRequest(new ApiResponse<object>
                {
                    Success = false,
                    Message = "Logs list cannot be empty"
                });
            }

            // Hangfire background job olarak çalıştır - fire-and-forget
            BackgroundJob.Enqueue(() => ErrorLoggingService.SaveErrorLogsAsync(request.Logs));

            Logger.LogInformation(
                "Queued {Count} error logs from mobile app for background processing",
                request.Logs.Count);

            // Hemen response dön - DB yazımı arka planda yapılacak
            return Ok(new ApiResponse<object>
            {
                Success = true,
                Message = $"Queued {request.Logs.Count} error log(s) for processing"
            });
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error queueing error logs");
            return StatusCode(500, new ApiResponse<object>
            {
                Success = false,
                Message = "An error occurred while queueing logs"
            });
        }
    }

    /// <summary>
    /// Error logları listele (Admin için)
    /// </summary>
    /// <param name="page">Sayfa numarası</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    /// <param name="level">Log seviyesi filtresi</param>
    /// <param name="userId">Kullanıcı ID filtresi</param>
    /// <returns>Error log listesi</returns>
    [HttpGet("errors")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> GetErrorLogs(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50,
        [FromQuery] string? level = null,
        [FromQuery] string? userId = null)
    {
        try
        {
            var query = UnitOfWork.ErrorLogs.Query();

            // Filtreleme
            if (!string.IsNullOrEmpty(level))
            {
                query = query.Where(log => log.Level == level);
            }

            if (!string.IsNullOrEmpty(userId))
            {
                query = query.Where(log => log.UserId == userId);
            }

            // Sıralama (en yeni önce)
            query = query.OrderByDescending(log => log.Timestamp);

            // Toplam kayıt sayısı
            var totalCount = await query.CountAsync();

            // Sayfalama
            var logs = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(log => new
                {
                    log.Id,
                    log.LogId,
                    log.Level,
                    log.Message,
                    log.Error,
                    log.StackTrace,
                    log.Timestamp,
                    log.Metadata,
                    log.UserId,
                    log.DeviceInfo,
                    log.AppVersion,
                    log.CreatedAt
                })
                .ToListAsync();

            return Ok(new ApiResponse<object>
            {
                Success = true,
                Data = new
                {
                    Logs = logs,
                    TotalCount = totalCount,
                    Page = page,
                    PageSize = pageSize,
                    TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
                }
            });
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error retrieving error logs");
            return StatusCode(500, new ApiResponse<object>
            {
                Success = false,
                Message = "An error occurred while retrieving logs"
            });
        }
    }
}

