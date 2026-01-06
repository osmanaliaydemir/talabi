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
                var description =
                    LocalizationService.GetLocalizedString("WalletResources", "ManualDeposit", CurrentCulture);
                var transaction = await walletService.DepositAsync(userId, request.Amount, description);
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
                var withdrawalRequest = await walletService.CreateWithdrawalRequestAsync(
                    userId,
                    request.Amount,
                    request.Iban,
                    request.BankAccountName ?? "Mobil Hesap",
                    "Mobil uygulama üzerinden talep edildi.");

                return Ok(new ApiResponse<WithdrawalRequest>(withdrawalRequest));
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error creating withdrawal request");
                return BadRequest(new ApiResponse<object>(ex.Message));
            }
        }

        [HttpPost("sync-earnings")]
        [AllowAnonymous]
        public async Task<IActionResult> SyncEarnings()
        {
            // Ideally restricted to Admin or run once
            try
            {
                int count = await walletService.SyncPendingEarningsAsync();
                return Ok(new ApiResponse<object>(new
                    { processed = count, message = $"Successfully synced {count} pending earnings." }));
            }
            catch (Exception ex)
            {
                Logger.LogError(ex, "Error syncing earnings");
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
        public string? BankAccountName { get; set; }
    }
}
