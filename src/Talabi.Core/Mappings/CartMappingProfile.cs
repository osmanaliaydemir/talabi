using AutoMapper;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;

namespace Talabi.Core.Mappings;

/// <summary>
/// Cart entity to DTO mapping profile
/// </summary>
public class CartMappingProfile : Profile
{
    public CartMappingProfile()
    {
        // CartItem -> CartItemDto
        CreateMap<CartItem, CartItemDto>()
            .ForMember(dest => dest.ProductName,
                opt => opt.MapFrom(src => src.Product != null ? src.Product.Name : string.Empty))
            .ForMember(dest => dest.ProductPrice,
                opt => opt.MapFrom(src => src.Product != null ? src.Product.Price : 0))
            .ForMember(dest => dest.ProductImageUrl,
                opt => opt.MapFrom(src => src.Product != null ? src.Product.ImageUrl : null))
            .ForMember(dest => dest.VendorId,
                opt => opt.MapFrom(src => src.Product != null ? src.Product.VendorId : Guid.Empty))
            .ForMember(dest => dest.VendorName,
                opt => opt.MapFrom(src =>
                    src.Product != null && src.Product.Vendor != null ? src.Product.Vendor.Name : string.Empty))
            .ForMember(dest => dest.VendorType,
                opt => opt.MapFrom(src =>
                    src.Product != null && src.Product.Vendor != null ? (int)src.Product.Vendor.Type : 0))
            .ForMember(dest => dest.Currency,
                opt => opt.MapFrom(src => src.Product != null ? (int)src.Product.Currency : 0))
            .ForMember(dest => dest.CurrencyCode,
                opt => opt.MapFrom(src => src.Product != null ? src.Product.Currency.ToString() : "TRY"))
            .ForMember(dest => dest.SelectedOptions, opt => opt.MapFrom(src =>
                !string.IsNullOrEmpty(src.SelectedOptions)
                    ? System.Text.Json.JsonSerializer.Deserialize<List<CartItemOptionDto>>(src.SelectedOptions,
                        (System.Text.Json.JsonSerializerOptions?)null)
                    : null));

        // Cart -> CartDto
        CreateMap<Cart, CartDto>()
            .ForMember(dest => dest.Items, opt => opt.MapFrom(src => src.CartItems));
    }
}

