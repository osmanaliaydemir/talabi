using Talabi.Core.DTOs;

namespace Talabi.Core.Interfaces;

public interface ILocationService
{
    Task<List<LocationItemDto>> GetCountriesAsync();
    Task<List<LocationItemDto>> GetCitiesAsync(Guid? countryId = null);
    Task<List<LocationItemDto>> GetDistrictsAsync(Guid cityId);
    Task<List<LocationItemDto>> GetLocalitiesAsync(Guid districtId);
}
