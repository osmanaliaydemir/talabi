namespace Talabi.Core.Enums;

public enum OrderCourierStatus
{
    Assigned = 0,        // Kurye atandı
    Accepted = 1,        // Kurye kabul etti
    Rejected = 2,        // Kurye reddetti
    PickedUp = 3,        // Sipariş alındı
    OutForDelivery = 4,  // Yola çıktı
    Delivered = 5        // Teslim edildi
}

