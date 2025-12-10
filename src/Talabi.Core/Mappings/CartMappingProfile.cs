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
            .ForMember(dest => dest.ProductName, opt => opt.MapFrom(src => src.Product != null ? src.Product.Name : string.Empty))
            .ForMember(dest => dest.ProductPrice, opt => opt.MapFrom(src => src.Product != null ? src.Product.Price : 0))
            .ForMember(dest => dest.ProductImageUrl, opt => opt.MapFrom(src => src.Product != null ? src.Product.ImageUrl : null));

        // Cart -> CartDto
        CreateMap<Cart, CartDto>()
            .ForMember(dest => dest.Items, opt => opt.MapFrom(src => src.CartItems));
    }
}

