using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
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
public class AddressesController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;

    /// <summary>
    /// AddressesController constructor
    /// </summary>
    public AddressesController(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    private string GetUserId() => User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value ?? throw new UnauthorizedAccessException();

    /// <summary>
    /// Kullanıcının tüm adreslerini getirir
    /// </summary>
    /// <returns>Adres listesi</returns>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<AddressDto>>>> GetAddresses()
    {
        var userId = GetUserId();

        IQueryable<UserAddress> query = _unitOfWork.UserAddresses.Query()
            .Where(a => a.UserId == userId);

        IOrderedQueryable<UserAddress> orderedQuery = query
            .OrderByDescending(a => a.IsDefault)
            .ThenByDescending(a => a.CreatedAt);

        var addresses = await orderedQuery
            .Select(a => new AddressDto
            {
                Id = a.Id,
                Title = a.Title,
                FullAddress = a.FullAddress,
                City = a.City,
                District = a.District,
                PostalCode = a.PostalCode,
                IsDefault = a.IsDefault,
                Latitude = a.Latitude,
                Longitude = a.Longitude
            })
            .ToListAsync();

        return Ok(new ApiResponse<List<AddressDto>>(addresses, "Adresler başarıyla getirildi"));
    }

    /// <summary>
    /// Yeni adres oluşturur
    /// </summary>
    /// <param name="dto">Adres bilgileri</param>
    /// <returns>Oluşturulan adres</returns>
    [HttpPost]
    public async Task<ActionResult<ApiResponse<AddressDto>>> CreateAddress(CreateAddressDto dto)
    {
        var userId = GetUserId();

        var address = new UserAddress
        {
            UserId = userId,
            Title = dto.Title,
            FullAddress = dto.FullAddress,
            City = dto.City,
            District = dto.District,
            PostalCode = dto.PostalCode,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            IsDefault = false
        };

        // If this is the first address, make it default
        var hasAddresses = await _unitOfWork.UserAddresses.Query()
            .AnyAsync(a => a.UserId == userId);
        if (!hasAddresses)
        {
            address.IsDefault = true;
        }

        await _unitOfWork.UserAddresses.AddAsync(address);
        await _unitOfWork.SaveChangesAsync();

        var addressDto = new AddressDto
        {
            Id = address.Id,
            Title = address.Title,
            FullAddress = address.FullAddress,
            City = address.City,
            District = address.District,
            PostalCode = address.PostalCode,
            IsDefault = address.IsDefault,
            Latitude = address.Latitude,
            Longitude = address.Longitude
        };

        return CreatedAtAction(
            nameof(GetAddresses),
            new ApiResponse<AddressDto>(addressDto, "Adres başarıyla oluşturuldu"));
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
        var userId = GetUserId();

        var address = await _unitOfWork.UserAddresses.Query()
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (address == null)
        {
            return NotFound(new ApiResponse<object>("Adres bulunamadı", "ADDRESS_NOT_FOUND"));
        }

        address.Title = dto.Title;
        address.FullAddress = dto.FullAddress;
        address.City = dto.City;
        address.District = dto.District;
        address.PostalCode = dto.PostalCode;
        address.Latitude = dto.Latitude;
        address.Longitude = dto.Longitude;

        _unitOfWork.UserAddresses.Update(address);
        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Adres başarıyla güncellendi"));
    }

    /// <summary>
    /// Varsayılan adresi ayarlar
    /// </summary>
    /// <param name="id">Adres ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpPut("{id}/set-default")]
    public async Task<ActionResult<ApiResponse<object>>> SetDefaultAddress(Guid id)
    {
        var userId = GetUserId();

        var address = await _unitOfWork.UserAddresses.Query()
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (address == null)
        {
            return NotFound(new ApiResponse<object>("Adres bulunamadı", "ADDRESS_NOT_FOUND"));
        }

        // Remove default from all other addresses
        var userAddresses = await _unitOfWork.UserAddresses.Query()
            .Where(a => a.UserId == userId)
            .ToListAsync();

        foreach (var addr in userAddresses)
        {
            addr.IsDefault = addr.Id == id;
            _unitOfWork.UserAddresses.Update(addr);
        }

        await _unitOfWork.SaveChangesAsync();

        return Ok(new ApiResponse<object>(new { }, "Varsayılan adres başarıyla güncellendi"));
    }

    /// <summary>
    /// Adresi siler
    /// </summary>
    /// <param name="id">Adres ID'si</param>
    /// <returns>İşlem sonucu</returns>
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse<object>>> DeleteAddress(Guid id)
    {
        var userId = GetUserId();

        var address = await _unitOfWork.UserAddresses.Query()
            .FirstOrDefaultAsync(a => a.Id == id && a.UserId == userId);

        if (address == null)
        {
            return NotFound(new ApiResponse<object>("Adres bulunamadı", "ADDRESS_NOT_FOUND"));
        }

        var wasDefault = address.IsDefault;
        _unitOfWork.UserAddresses.Remove(address);
        await _unitOfWork.SaveChangesAsync();

        // If deleted address was default, set another as default
        if (wasDefault)
        {
            var newDefault = await _unitOfWork.UserAddresses.Query()
                .Where(a => a.UserId == userId)
                .FirstOrDefaultAsync();

            if (newDefault != null)
            {
                newDefault.IsDefault = true;
                _unitOfWork.UserAddresses.Update(newDefault);
                await _unitOfWork.SaveChangesAsync();
            }
        }

        return Ok(new ApiResponse<object>(new { }, "Adres başarıyla silindi"));
    }
}
