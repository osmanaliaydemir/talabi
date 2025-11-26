namespace Talabi.Core.Enums;

public enum CourierStatus
{
    Offline = 0,      // Çevrimdışı - sipariş almaz
    Available = 1,    // Müsait - sipariş alabilir
    Busy = 2,         // Meşgul - aktif teslimat yapıyor
    Break = 3,        // Mola - geçici olarak sipariş almaz
    Assigned = 4      // Sipariş atandı - kabul/red bekliyor
}
