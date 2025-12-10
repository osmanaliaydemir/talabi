using AutoMapper;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;

namespace Talabi.Core.Mappings;

/// <summary>
/// Review entity to DTO mapping profile
/// </summary>
public class ReviewMappingProfile : Profile
{
    public ReviewMappingProfile()
    {
        // Review -> ReviewDto
        CreateMap<Review, ReviewDto>()
            .ForMember(dest => dest.UserFullName, opt => opt.MapFrom(src => src.User != null ? src.User.FullName : "Anonymous"))
            .ForMember(dest => dest.VendorName, opt => opt.MapFrom(src => src.Vendor != null ? src.Vendor.Name : (src.Product != null && src.Product.Vendor != null ? src.Product.Vendor.Name : null)));
    }
}
