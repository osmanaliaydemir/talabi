using Talabi.Core.Entities;
using Talabi.Core.DTOs;

namespace Talabi.Core.Interfaces;

public interface IWalletService
{
    Task<Wallet> GetWalletByUserIdAsync(string userId);
    Task<decimal> GetBalanceAsync(string userId);
    Task<WalletTransaction> DepositAsync(string userId, decimal amount, string description, string? referenceId = null);
    Task<WalletTransaction> WithdrawAsync(string userId, decimal amount, string description);

    Task<WalletTransaction> ProcessPaymentAsync(string userId, decimal amount, string orderId, string customerOrderId,
        string description);

    Task<WalletTransaction> AddEarningAsync(string userId, decimal amount, string referenceId, string customerOrderId,
        string description);

    Task<List<WalletTransaction>> GetTransactionsAsync(string userId, int page = 1, int pageSize = 20);
    Task<int> SyncPendingEarningsAsync();

    // Bank Account Management
    Task<List<BankAccount>> GetBankAccountsAsync(string userId);
    Task<BankAccount> AddBankAccountAsync(string userId, CreateBankAccountRequest request);
    Task<BankAccount> UpdateBankAccountAsync(string userId, UpdateBankAccountRequest request);
    Task DeleteBankAccountAsync(string userId, Guid id);
    Task SetDefaultBankAccountAsync(string userId, Guid id);
}
