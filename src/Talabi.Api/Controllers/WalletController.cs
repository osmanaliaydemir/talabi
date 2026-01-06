using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.Interfaces;
using Talabi.Core.Entities;
using Talabi.Core.DTOs;

namespace Talabi.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class WalletController(
        IUnitOfWork unitOfWork,
        ILogger<WalletController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        IWalletService walletService)
        : BaseController(unitOfWork, logger, localizationService, userContext)
    {
        [HttpGet]
        public async Task<IActionResult> GetWallet()
        {
            var userId = UserContext.GetUserId(); // Correct method call
            if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var wallet = await walletService.GetWalletByUserIdAsync(userId);
            return Ok(new ApiResponse<Wallet>(wallet));
        }

        [HttpGet("transactions")]
        public async Task<IActionResult> GetTransactions([FromQuery] int page = 1, [FromQuery] int pageSize = 20)
        {
            var userId = UserContext.GetUserId();
            if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var transactions = await walletService.GetTransactionsAsync(userId, page, pageSize);
            return Ok(new ApiResponse<List<WalletTransaction>>(transactions));
        }

        [HttpPost("deposit")]
        public async Task<IActionResult> Deposit([FromBody] DepositRequest request)
        {
            var userId = UserContext.GetUserId();
            if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            if (request.Amount <= 0)
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString("WalletResources", "InvalidAmount", CurrentCulture)
                ));

            try
            {
                var transaction = await walletService.DepositAsync(userId, request.Amount, "Manual Deposit");
                return Ok(new ApiResponse<WalletTransaction>(transaction));
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error depositing to wallet");
                return BadRequest(new ApiResponse<object>(ex.Message));
            }
        }

        [HttpPost("withdraw")]
        public async Task<IActionResult> Withdraw([FromBody] WithdrawRequest request)
        {
            var userId = UserContext.GetUserId();
            if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            if (request.Amount <= 0)
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString("WalletResources", "InvalidAmount", CurrentCulture)
                ));

            if (string.IsNullOrEmpty(request.Iban))
                return BadRequest(new ApiResponse<object>(
                    LocalizationService.GetLocalizedString("WalletResources", "IbanRequired", CurrentCulture)
                ));

            try
            {
                var description = $"Withdrawal to {request.Iban}";
                var transaction = await walletService.WithdrawAsync(userId, request.Amount, description);
                return Ok(new ApiResponse<WalletTransaction>(transaction));
            }
            // Catching specific exceptions if needed, but general catch covers it for now.
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error withdrawing from wallet");
                return BadRequest(new ApiResponse<object>(ex.Message));
            }
        }
    }

    public class DepositRequest
    {
        public decimal Amount { get; set; }
    }

    public class WithdrawRequest
    {
        public decimal Amount { get; set; }
        public string? Iban { get; set; }
    }
}
