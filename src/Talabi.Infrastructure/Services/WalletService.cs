using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.Entities;
using Talabi.Core.Enums;
using Talabi.Core.Interfaces;
using Talabi.Core.DTOs;
using Talabi.Infrastructure.Data;

namespace Talabi.Infrastructure.Services;

public class WalletService : IWalletService
{
    private readonly TalabiDbContext _context;
    private readonly ILocalizationService _localizationService;

    public WalletService(TalabiDbContext context, ILocalizationService localizationService)
    {
        _context = context;
        _localizationService = localizationService;
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

    public async Task<WalletTransaction> DepositAsync(string userId, decimal amount, string description,
        string? referenceId = null)
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

    public async Task<WalletTransaction> ProcessPaymentAsync(string userId, decimal amount, string orderId,
        string customerOrderId,
        string description)
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
            CustomerOrderId = customerOrderId,
            Description = description,
            TransactionDate = DateTime.UtcNow
        };

        _context.WalletTransactions.Add(transaction);
        await _context.SaveChangesAsync();

        return transaction;
    }

    public async Task<WalletTransaction> AddEarningAsync(string userId, decimal amount, string referenceId,
        string customerOrderId,
        string description)
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
            CustomerOrderId = customerOrderId,
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

    public async Task<int> SyncPendingEarningsAsync()
    {
        int processedCount = 0;
        // Get culture from thread or default
        var culture = CultureInfo.CurrentUICulture;

        // 1. Sync Courier Earnings
        var pendingCourier = await _context.CourierEarnings
            .Include(ce => ce.Courier)
            .Include(ce => ce.Order)
            .Where(ce => !ce.IsPaid && ce.Courier != null && !string.IsNullOrEmpty(ce.Courier.UserId))
            .ToListAsync();

        foreach (var earning in pendingCourier)
        {
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                await AddEarningAsync(
                    earning.Courier!.UserId,
                    earning.TotalEarning,
                    earning.OrderId.ToString(),
                    earning.Order?.CustomerOrderId ?? earning.OrderId.ToString(),
                    _localizationService.GetLocalizedString("OrderAssignmentResources", "EarningDescription", culture,
                        earning.Order?.CustomerOrderId ?? earning.OrderId.ToString()));

                earning.IsPaid = true;
                earning.PaidAt = DateTime.UtcNow;
                _context.CourierEarnings.Update(earning);

                await _context.SaveChangesAsync();
                await transaction.CommitAsync();
                processedCount++;
            }
            catch
            {
                await transaction.RollbackAsync();
            }
        }

        // 2. Sync Vendor Earnings
        var deliveredOrders = await _context.Orders
            .Include(o => o.Vendor)
            .Where(o => o.Status == OrderStatus.Delivered && o.Vendor != null &&
                        !string.IsNullOrEmpty(o.Vendor.OwnerId))
            .ToListAsync();

        foreach (var order in deliveredOrders)
        {
            var wallet = await GetWalletByUserIdAsync(order.Vendor!.OwnerId);
            var exists = await _context.WalletTransactions
                .AnyAsync(t => t.WalletId == wallet.Id &&
                               t.ReferenceId == order.Id.ToString() &&
                               t.TransactionType == TransactionType.Earning);

            if (!exists)
            {
                using var transaction = await _context.Database.BeginTransactionAsync();
                try
                {
                    await AddEarningAsync(
                        order.Vendor.OwnerId,
                        order.TotalAmount,
                        order.Id.ToString(),
                        order.CustomerOrderId,
                        _localizationService.GetLocalizedString("WalletResources", "VendorSaleEarning", culture,
                            order.CustomerOrderId));

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();
                    processedCount++;
                }
                catch
                {
                    await transaction.RollbackAsync();
                }
            }
        }

        return processedCount;
    }

    public async Task<List<BankAccount>> GetBankAccountsAsync(string userId)
    {
        return await _context.BankAccounts
            .Where(b => b.AppUserId == userId)
            .OrderByDescending(b => b.IsDefault)
            .ThenByDescending(b => b.CreatedAt)
            .ToListAsync();
    }

    public async Task<BankAccount> AddBankAccountAsync(string userId, CreateBankAccountRequest request)
    {
        if (request.IsDefault)
        {
            var defaults = await _context.BankAccounts
                .Where(b => b.AppUserId == userId && b.IsDefault)
                .ToListAsync();
            foreach (var d in defaults) d.IsDefault = false;
        }

        var account = new BankAccount
        {
            AppUserId = userId,
            AccountName = request.AccountName,
            Iban = request.Iban,
            IsDefault = request.IsDefault
        };

        _context.BankAccounts.Add(account);
        await _context.SaveChangesAsync();
        return account;
    }

    public async Task<BankAccount> UpdateBankAccountAsync(string userId, UpdateBankAccountRequest request)
    {
        var account = await _context.BankAccounts
            .FirstOrDefaultAsync(b => b.Id == request.Id && b.AppUserId == userId);

        if (account == null) throw new KeyNotFoundException("Bank account not found");

        if (request.IsDefault && !account.IsDefault)
        {
            var defaults = await _context.BankAccounts
                .Where(b => b.AppUserId == userId && b.IsDefault)
                .ToListAsync();
            foreach (var d in defaults) d.IsDefault = false;
        }

        account.AccountName = request.AccountName;
        account.Iban = request.Iban;
        account.IsDefault = request.IsDefault;

        _context.BankAccounts.Update(account);
        await _context.SaveChangesAsync();
        return account;
    }

    public async Task DeleteBankAccountAsync(string userId, Guid id)
    {
        var account = await _context.BankAccounts
            .FirstOrDefaultAsync(b => b.Id == id && b.AppUserId == userId);
        if (account != null)
        {
            _context.BankAccounts.Remove(account);
            await _context.SaveChangesAsync();
        }
    }

    public async Task SetDefaultBankAccountAsync(string userId, Guid id)
    {
        var accounts = await _context.BankAccounts
            .Where(b => b.AppUserId == userId)
            .ToListAsync();

        foreach (var account in accounts)
        {
            account.IsDefault = account.Id == id;
        }

        await _context.SaveChangesAsync();
    }
}

