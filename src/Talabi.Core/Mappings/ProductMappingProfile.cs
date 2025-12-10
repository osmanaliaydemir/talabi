using AutoMapper;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;

namespace Talabi.Core.Mappings;

/// <summary>
/// Product entity to DTO mapping profile
/// </summary>
public class ProductMappingProfile : Profile
{
    public ProductMappingProfile()
    {
        // Product -> ProductDto
        CreateMap<Product, ProductDto>()
            .ForMember(dest => dest.VendorName, opt => opt.MapFrom(src => src.Vendor != null ? src.Vendor.Name : null))
            .ForMember(dest => dest.Category, opt => opt.MapFrom(src => src.Category ?? (src.ProductCategory != null ? src.ProductCategory.Name : null)))
            .ForMember(dest => dest.CategoryId, opt => opt.MapFrom(src => src.CategoryId ?? (src.ProductCategory != null ? src.ProductCategory.Id : (Guid?)null)))
            .ForMember(dest => dest.VendorType, opt => opt.MapFrom(src => src.VendorType ?? (src.Vendor != null ? src.Vendor.Type : (Talabi.Core.Enums.VendorType?)null)));

        // Product -> VendorProductDto
        CreateMap<Product, VendorProductDto>()
            .ForMember(dest => dest.Category, opt => opt.MapFrom(src => src.Category ?? (src.ProductCategory != null ? src.ProductCategory.Name : null)));
    }
}
