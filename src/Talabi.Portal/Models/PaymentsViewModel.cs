using Talabi.Core.DTOs;
using Talabi.Core.Entities;

namespace Talabi.Portal.Models;

public class PaymentsViewModel
{
  public decimal DailyEarnings { get; set; }
  public decimal WeeklyEarnings { get; set; }
  public decimal MonthlyEarnings { get; set; }
  public decimal TotalEarnings { get; set; }

  public List<OrderDto> Transactions { get; set; } = new List<OrderDto>();

  public List<BankAccount> BankAccounts { get; set; } =
    new List<BankAccount>();
}
