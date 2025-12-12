using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace Getir.MerchantPortal.Models;

public class MerchantListFilter
{
    public string? CategoryType { get; set; }
    public bool OnlyActive { get; set; }
    public int Page { get; set; } = 1;
}

public class MerchantListViewModel
{
    public PagedResult<MerchantResponse> Merchants { get; set; } = new();
    public MerchantListFilter Filter { get; set; } = new();
    public IReadOnlyList<ServiceCategoryResponse> ServiceCategories { get; set; } = Array.Empty<ServiceCategoryResponse>();
}

public class MerchantCreateViewModel
{
    public CreateMerchantInput Input { get; set; } = new();
    public IReadOnlyList<ServiceCategoryResponse> ServiceCategories { get; set; } = Array.Empty<ServiceCategoryResponse>();
}

public class CreateMerchantInput
{
    [Required]
    [Display(Name = "Mağaza Adı")]
    public string Name { get; set; } = string.Empty;

    [Display(Name = "Açıklama")]
    public string? Description { get; set; }

    [Required]
    [Display(Name = "Hizmet Kategorisi")]
    public Guid ServiceCategoryId { get; set; }

    [Required]
    [Display(Name = "Adres")]
    public string Address { get; set; } = string.Empty;

    [Display(Name = "Enlem")]
    [Range(-90, 90, ErrorMessage = "Enlem -90 ile 90 arasında olmalıdır.")]
    public decimal Latitude { get; set; }

    [Display(Name = "Boylam")]
    [Range(-180, 180, ErrorMessage = "Boylam -180 ile 180 arasında olmalıdır.")]
    public decimal Longitude { get; set; }

    [Required]
    [Phone]
    [Display(Name = "Telefon")]
    public string PhoneNumber { get; set; } = string.Empty;

    [EmailAddress]
    [Display(Name = "E-posta")]
    public string? Email { get; set; }

    [Display(Name = "Minimum Sipariş Tutarı")]
    [Range(0, double.MaxValue)]
    public decimal MinimumOrderAmount { get; set; }

    [Display(Name = "Teslimat Ücreti")]
    [Range(0, double.MaxValue)]
    public decimal DeliveryFee { get; set; }
}

public class MerchantDetailViewModel
{
    public MerchantResponse Merchant { get; set; } = default!;
    public IReadOnlyList<ServiceCategoryResponse> ServiceCategories { get; set; } = Array.Empty<ServiceCategoryResponse>();
}

