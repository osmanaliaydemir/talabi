using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Talabi.Core.Interfaces;
using Talabi.Core.Entities;
using Talabi.Core.DTOs;
using System.Security.Claims;

namespace Talabi.Api.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class BankAccountController(
        IUnitOfWork unitOfWork,
        ILogger<BankAccountController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext,
        IWalletService walletService)
        : BaseController(unitOfWork, logger, localizationService, userContext)
    {
        [HttpGet]
        public async Task<IActionResult> GetBankAccounts()
        {
            var userId = UserContext.GetUserId();
            if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var accounts = await walletService.GetBankAccountsAsync(userId);
            return Ok(new ApiResponse<List<BankAccount>>(accounts));
        }

        [HttpPost]
        public async Task<IActionResult> AddBankAccount([FromBody] CreateBankAccountRequest request)
        {
            var userId = UserContext.GetUserId();
            if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var account = await walletService.AddBankAccountAsync(userId, request);
            return Ok(new ApiResponse<BankAccount>(account));
        }

        [HttpPost("update")]
        public async Task<IActionResult> UpdateBankAccount([FromBody] UpdateBankAccountRequest request)
        {
            var userId = UserContext.GetUserId();
            if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            try
            {
                var account = await walletService.UpdateBankAccountAsync(userId, request);
                return Ok(new ApiResponse<BankAccount>(account));
            }
            catch (KeyNotFoundException ex)
            {
                return NotFound(new ApiResponse<object>(ex.Message));
            }
        }

        [HttpPost("{id}/delete")]
        public async Task<IActionResult> DeleteBankAccount(Guid id)
        {
            var userId = UserContext.GetUserId();
            if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            await walletService.DeleteBankAccountAsync(userId, id);
            return Ok(new ApiResponse<object>(true));
        }

        [HttpPost("{id}/default")]
        public async Task<IActionResult> SetDefault(Guid id)
        {
            var userId = UserContext.GetUserId();
            if (string.IsNullOrEmpty(userId)) userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            await walletService.SetDefaultBankAccountAsync(userId, id);
            return Ok(new ApiResponse<object>(true));
        }
    }
}
