using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Globalization;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;

namespace Talabi.Api.Controllers;

/// <summary>
/// Kullanıcı adres işlemleri için controller
/// </summary>
[Route("api/[controller]")]
[ApiController]
[Authorize]
public class AddressesController : BaseController
{
    private const string ResourceName = "AddressResources";

    /// <summary>
    /// AddressesController constructor
    /// </summary>
    public AddressesController(
        IUnitOfWork unitOfWork,
        ILogger<AddressesController> logger,
        ILocalizationService localizationService,
        IUserContextService userContext)
        : base(unitOfWork, logger, localizationService, userContext)
    {
    }

    private string GetLocalizedName(dynamic? entity)
    {
        if (entity == null) return string.Empty;
        var culture = CurrentCulture.TwoLetterISOLanguageName;
        return culture switch
        {
            "tr" => entity.NameTr,
            "en" => !string.IsNullOrEmpty(entity.NameEn) ? entity.NameEn : entity.NameTr,
            "ar" => !string.IsNullOrEmpty(entity.NameAr) ? entity.NameAr : entity.NameTr,
            _ => entity.NameTr
        };
    }

    /// <summary>
    /// Kullanıcının tüm adreslerini getirir
    /// </summary>
    /// <returns>Adres listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<AddressDto>>>> GetAddresses()
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        IQueryable<UserAddress> query = UnitOfWork.UserAddresses.Query()
            .Include(a => a.City)
            .Include(a => a.District)
            .Include(a => a.Locality)
            .Where(a => a.UserId == userId);

        IOrderedQueryable<UserAddress> orderedQuery = query
            .OrderByDescending(a => a.IsDefault)
            .ThenByDescending(a => a.CreatedAt);

        var addresses = await orderedQuery.ToListAsync();
        
        var dtos = addresses.Select(a => new AddressDto
        {
            Id = a.Id,
            Title = a.Title,
            FullAddress = a.FullAddress,
            CityId = a.CityId,
            CityName = GetLocalizedName(a.City),
            DistrictId = a.DistrictId,
            DistrictName = GetLocalizedName(a.District),
            LocalityId = a.LocalityId,
            LocalityName = GetLocalizedName(a.Locality),
            PostalCode = a.PostalCode,
            IsDefault = a.IsDefault,
            Latitude = a.Latitude,
            Longitude = a.Longitude
        }).ToList();

        return Ok(new ApiResponse<List<AddressDto>>(
            dtos,
            LocalizationService.GetLocalizedString(ResourceName, "AddressesRetrievedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Yeni adres oluşturur
    /// </summary>
    /// <param name="dto">Adres bilgileri</param>
    /// <returns>Oluşturulan adres</returns>
    [HttpPost]
    public async Task<ActionResult<ApiResponse<AddressDto>>> CreateAddress(CreateAddressDto dto)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var address = new UserAddress
        {
            UserId = userId,
            Title = dto.Title,
            FullAddress = dto.FullAddress,
            CityId = dto.CityId,
            DistrictId = dto.DistrictId,
            LocalityId = dto.LocalityId,
            PostalCode = dto.PostalCode,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            IsDefault = false
        };

        // If this is the first address, make it default
        var hasAddresses = await UnitOfWork.UserAddresses.Query()
            .AnyAsync(a => a.UserId == userId);
        if (!hasAddresses)
        {
            address.IsDefault = true;
        }

        await UnitOfWork.UserAddresses.AddAsync(address);
        await UnitOfWork.SaveChangesAsync();

        // Reload to get navigation properties for DTO
        var createdAddress = await UnitOfWork.UserAddresses.Query()
            .Include(a => a.City)
            .Include(a => a.District)
            .Include(a => a.Locality)
            .FirstOrDefaultAsync(a => a.Id == address.Id);

        var addressDto = new AddressDto
        {
            Id = address.Id,
            Title = address.Title,
            FullAddress = address.FullAddress,
            CityId = address.CityId,
            CityName = GetLocalizedName(createdAddress?.City),
            DistrictId = address.DistrictId,
            DistrictName = GetLocalizedName(createdAddress?.District),
            LocalityId = address.LocalityId,
            LocalityName = GetLocalizedName(createdAddress?.Locality),
            PostalCode = address.PostalCode,
            IsDefault = address.IsDefault,
            Latitude = address.Latitude,
            Longitude = address.Longitude
        };

        return CreatedAtAction(
            nameof(GetAddresses),
            new ApiResponse<AddressDto>(
                addressDto,
                LocalizationService.GetLocalizedString(ResourceName, "AddressCreatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Adres bilgilerini günceller
    /// </summary>
    /// <param name="id">Adres ID'si</param>
    /// <param name="dto">Güncellenecek adres bilgileri</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<object>>> UpdateAddress(Guid id, UpdateAddressDto dto)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var address = await UnitOfWork.UserAddresses.Query()
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (address == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "AddressNotFound", CurrentCulture),
                "ADDRESS_NOT_FOUND"));
        }

        address.Title = dto.Title;
        address.FullAddress = dto.FullAddress;
        address.CityId = dto.CityId;
        address.DistrictId = dto.DistrictId;
        address.LocalityId = dto.LocalityId;
        address.PostalCode = dto.PostalCode;
        address.Latitude = dto.Latitude;
        address.Longitude = dto.Longitude;

        UnitOfWork.UserAddresses.Update(address);
        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(
            new { },
            LocalizationService.GetLocalizedString(ResourceName, "AddressUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Varsayılan adresi ayarlar
    /// </summary>
    /// <param name="id">Adres ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{id}/set-default")]
    public async Task<ActionResult<ApiResponse<object>>> SetDefaultAddress(Guid id)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var address = await UnitOfWork.UserAddresses.Query()
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (address == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "AddressNotFound", CurrentCulture),
                "ADDRESS_NOT_FOUND"));
        }

        // Remove default from all other addresses
        var userAddresses = await UnitOfWork.UserAddresses.Query()
            .Where(a => a.UserId == userId)
            .ToListAsync();

        foreach (var addr in userAddresses)
        {
            addr.IsDefault = addr.Id == id;
            UnitOfWork.UserAddresses.Update(addr);
        }

        await UnitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(
            new { },
            LocalizationService.GetLocalizedString(ResourceName, "DefaultAddressUpdatedSuccessfully", CurrentCulture)));
    }

    /// <summary>
    /// Adresi siler
    /// </summary>
    /// <param name="id">Adres ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteAddress(Guid id)
    {
        var userId = UserContext.GetUserId();
        if (userId == null)
        {
            return Unauthorized();
        }

        var address = await UnitOfWork.UserAddresses.Query()
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (address == null)
        {
            return NotFound(new ApiResponse<object>(
                LocalizationService.GetLocalizedString(ResourceName, "AddressNotFound", CurrentCulture),
                "ADDRESS_NOT_FOUND"));
        }

        var wasDefault = address.IsDefault;
        UnitOfWork.UserAddresses.Remove(address);
        await UnitOfWork.SaveChangesAsync();

        // If deleted address was default, set another as default
        if (wasDefault)
        {
            var newDefault = await UnitOfWork.UserAddresses.Query()
                .Where(a => a.UserId == userId)
                .FirstOrDefaultAsync();

            if (newDefault != null)
            {
                newDefault.IsDefault = true;
                UnitOfWork.UserAddresses.Update(newDefault);
                await UnitOfWork.SaveChangesAsync();
            }
        }

        return Ok(new ApiResponse<object>(
            new { },
            LocalizationService.GetLocalizedString(ResourceName, "AddressDeletedSuccessfully", CurrentCulture)));
    }
}
