using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.Interfaces;
using Talabi.Core.Entities;
using Talabi.Core.DTOs;
using Talabi.Core.Enums;
using System.Security.Claims;

namespace Talabi.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class WithdrawalController(
        IUnitOfWork unitOfWork,
        ILogger<WithdrawalController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        IWalletService walletService)
        : BaseController(unitOfWork, logger, localizationService, userContext)
    {
        [HttpGet("requests")]
        public async Task<IActionResult> GetRequests([FromQuery] WithdrawalStatus? status)
        {
            var userId = UserContext.GetUserId();
            if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var requests = await walletService.GetWithdrawalRequestsAsync(userId, status);
            return Ok(new ApiResponse<List<WithdrawalRequest>>(requests));
        }

        [HttpPost("request")]
        public async Task<IActionResult> CreateRequest([FromBody] CreateWithdrawalRequest request)
        {
            var userId = UserContext.GetUserId();
            if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            try
            {
                var result = await walletService.CreateWithdrawalRequestAsync(userId, request.Amount, request.Iban, request.BankAccountName, request.Note);
                return Ok(new ApiResponse<WithdrawalRequest>(result));
            }
            catch (InvalidOperationException ex)
            {
                return BadRequest(new ApiResponse<object>(ex.Message));
            }
        }
    }
}
