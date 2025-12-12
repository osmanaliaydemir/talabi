using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Getir.MerchantPortal.Models;

public class SpecialHolidayListViewModel
{
    public List<SpecialHolidayResponse> Holidays { get; set; } = new();
    public List<SpecialHolidayResponse> Upcoming { get; set; } = new();
    public bool IncludeInactive { get; set; }
    public Guid MerchantId { get; set; }
    public MerchantAvailabilityResponse? Availability { get; set; }
}

public class SpecialHolidayFormViewModel
{
    public Guid? Id { get; set; }

    [Required(ErrorMessage = "Başlık zorunludur")]
    [Display(Name = "Başlık")]
    public string Title { get; set; } = string.Empty;

    [Display(Name = "Açıklama")]
    public string? Description { get; set; }

    [Required]
    [Display(Name = "Başlangıç Tarihi")]
    [DataType(DataType.Date)]
    public DateTime StartDate { get; set; } = DateTime.Today;

    [Required]
    [Display(Name = "Bitiş Tarihi")]
    [DataType(DataType.Date)]
    public DateTime EndDate { get; set; } = DateTime.Today;

    [Display(Name = "Tamamen Kapalı")]
    public bool IsClosed { get; set; }

    [Display(Name = "Tekrarlayan Etkinlik")]
    public bool IsRecurring { get; set; }

    [Display(Name = "Özel Açılış Saati")]
    [DataType(DataType.Time)]
    public string? SpecialOpenTime { get; set; }

    [Display(Name = "Özel Kapanış Saati")]
    [DataType(DataType.Time)]
    public string? SpecialCloseTime { get; set; }

    [Display(Name = "Aktif")]
    public bool IsActive { get; set; } = true;

    public Guid MerchantId { get; set; }
}

