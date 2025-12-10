using AutoMapper;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;

namespace Talabi.Core.Mappings;

/// <summary>
/// User entity to DTO mapping profile
/// </summary>
public class UserMappingProfile : Profile
{
    public UserMappingProfile()
    {
        // AppUser -> UserProfileDto
        CreateMap<AppUser, UserProfileDto>();
    }
}
