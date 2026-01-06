using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;

namespace Talabi.Infrastructure.Services;

public class WalletService : IWalletService
{
    private readonly TalabiDbContext _context;

    public WalletService(TalabiDbContext context)
    {
        _context = context;
    }

    public async Task<Wallet> GetWalletByUserIdAsync(string userId)
    {
        var wallet = await _context.Wallets
            .Include(w => w.Transactions)
            .FirstOrDefaultAsync(w => w.AppUserId == userId);

        if (wallet == null)
        {
            // Create wallet if not exists
            wallet = new Wallet
            {
                AppUserId = userId,
                Balance = 0,
                Currency = "TRY"
            };
            _context.Wallets.Add(wallet);
            await _context.SaveChangesAsync();
        }

        return wallet;
    }

    public async Task<decimal> GetBalanceAsync(string userId)
    {
        var wallet = await GetWalletByUserIdAsync(userId);
        return wallet.Balance;
    }

    public async Task<WalletTransaction> DepositAsync(string userId, decimal amount, string description, string referenceId = null)
    {
        var wallet = await GetWalletByUserIdAsync(userId);

        wallet.Balance += amount;
        wallet.UpdatedAt = DateTime.UtcNow;

        var transaction = new WalletTransaction
        {
            WalletId = wallet.Id,
            Amount = amount,
            TransactionType = TransactionType.Deposit,
            Description = description,
            ReferenceId = referenceId,
            TransactionDate = DateTime.UtcNow
        };

        _context.WalletTransactions.Add(transaction);
        await _context.SaveChangesAsync();

        return transaction;
    }

    public async Task<WalletTransaction> WithdrawAsync(string userId, decimal amount, string description)
    {
        var wallet = await GetWalletByUserIdAsync(userId);

        if (wallet.Balance < amount)
        {
            throw new InvalidOperationException("Insufficient balance");
        }

        wallet.Balance -= amount;
        wallet.UpdatedAt = DateTime.UtcNow;

        var transaction = new WalletTransaction
        {
            WalletId = wallet.Id,
            Amount = amount,
            TransactionType = TransactionType.Withdrawal,
            Description = description,
            TransactionDate = DateTime.UtcNow
        };

        _context.WalletTransactions.Add(transaction);
        await _context.SaveChangesAsync();

        return transaction;
    }

    public async Task<WalletTransaction> ProcessPaymentAsync(string userId, decimal amount, string orderId, string description)
    {
        var wallet = await GetWalletByUserIdAsync(userId);

        if (wallet.Balance < amount)
        {
            throw new InvalidOperationException("Insufficient balance");
        }

        wallet.Balance -= amount;
        wallet.UpdatedAt = DateTime.UtcNow;

        var transaction = new WalletTransaction
        {
            WalletId = wallet.Id,
            Amount = amount,
            TransactionType = TransactionType.Payment,
            ReferenceId = orderId,
            Description = description,
            TransactionDate = DateTime.UtcNow
        };

        _context.WalletTransactions.Add(transaction);
        await _context.SaveChangesAsync();

        return transaction;
    }

    public async Task<WalletTransaction> AddEarningAsync(string userId, decimal amount, string referenceId, string description)
    {
        var wallet = await GetWalletByUserIdAsync(userId);

        wallet.Balance += amount;
        wallet.UpdatedAt = DateTime.UtcNow;

        var transaction = new WalletTransaction
        {
            WalletId = wallet.Id,
            Amount = amount,
            TransactionType = TransactionType.Earning,
            ReferenceId = referenceId,
            Description = description,
            TransactionDate = DateTime.UtcNow
        };

        _context.WalletTransactions.Add(transaction);
        await _context.SaveChangesAsync();

        return transaction;
    }

    public async Task<List<WalletTransaction>> GetTransactionsAsync(string userId, int page = 1, int pageSize = 20)
    {
        var wallet = await GetWalletByUserIdAsync(userId);

        return await _context.WalletTransactions
            .Where(t => t.WalletId == wallet.Id)
            .OrderByDescending(t => t.TransactionDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();
    }
}
