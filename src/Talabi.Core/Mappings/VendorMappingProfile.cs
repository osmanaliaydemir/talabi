using AutoMapper;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;

namespace Talabi.Core.Mappings;

/// <summary>
/// Vendor entity to DTO mapping profile
/// </summary>
public class VendorMappingProfile : Profile
{
    public VendorMappingProfile()
    {
        // Vendor -> VendorDto
        CreateMap<Vendor, VendorDto>()
            .ForMember(dest => dest.Rating, opt => opt.MapFrom(src => src.Rating ?? 0))
            .ForMember(dest => dest.RatingCount, opt => opt.MapFrom(src => src.RatingCount))
            .ForMember(dest => dest.DeliveryRadiusInKm, opt => opt.MapFrom(src => src.DeliveryRadiusInKm));

        // Vendor -> VendorMapDto
        CreateMap<Vendor, VendorMapDto>()
            .ForMember(dest => dest.Latitude, opt => opt.MapFrom(src => src.Latitude ?? 0))
            .ForMember(dest => dest.Longitude, opt => opt.MapFrom(src => src.Longitude ?? 0));
    }
}
