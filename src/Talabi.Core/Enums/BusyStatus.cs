namespace Talabi.Core.Enums;

public enum BusyStatus
{
    Normal = 0,
    Busy = 1,      // +15 mins to delivery time
    Overloaded = 2 // +45 mins to delivery time
}
