using AutoMapper;
using Talabi.Core.DTOs;
using Talabi.Core.DTOs.Courier;
using Talabi.Core.Entities;

namespace Talabi.Core.Mappings;

/// <summary>
/// Courier entity to DTO mapping profile
/// </summary>
public class CourierMappingProfile : Profile
{
    public CourierMappingProfile()
    {
        // Courier -> CourierProfileDto
        CreateMap<Courier, CourierProfileDto>()
            .ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.Status.ToString()));
            // AverageRating ve IsWithinWorkingHours zaten Courier entity'sinde var, otomatik map edilecek

        // Courier -> CourierLocationDto
        CreateMap<Courier, CourierLocationDto>()
            .ForMember(dest => dest.CourierId, opt => opt.MapFrom(src => src.Id))
            .ForMember(dest => dest.CourierName, opt => opt.MapFrom(src => src.Name))
            .ForMember(dest => dest.Latitude, opt => opt.MapFrom(src => src.CurrentLatitude ?? 0))
            .ForMember(dest => dest.Longitude, opt => opt.MapFrom(src => src.CurrentLongitude ?? 0))
            .ForMember(dest => dest.LastUpdate, opt => opt.MapFrom(src => src.LastLocationUpdate ?? DateTime.UtcNow));

        // CourierEarning -> CourierEarningDto
        CreateMap<CourierEarning, CourierEarningDto>();

        // OrderItem -> CourierOrderItemDto
        CreateMap<OrderItem, CourierOrderItemDto>()
            .ForMember(dest => dest.ProductName, opt => opt.MapFrom(src => src.Product != null ? src.Product.Name : "Unknown Product"));

        // Order -> CourierOrderDto (OrderCourier bilgileri controller'da eklenecek)
        CreateMap<Order, CourierOrderDto>()
            .ForMember(dest => dest.CustomerOrderId, opt => opt.MapFrom(src => src.CustomerOrderId))
            .ForMember(dest => dest.VendorName, opt => opt.MapFrom(src => src.Vendor != null ? src.Vendor.Name : "Unknown Vendor"))
            .ForMember(dest => dest.VendorAddress, opt => opt.MapFrom(src => src.Vendor != null ? src.Vendor.Address : ""))
            .ForMember(dest => dest.VendorLatitude, opt => opt.MapFrom(src => src.Vendor != null && src.Vendor.Latitude.HasValue ? (double)src.Vendor.Latitude.Value : 0))
            .ForMember(dest => dest.VendorLongitude, opt => opt.MapFrom(src => src.Vendor != null && src.Vendor.Longitude.HasValue ? (double)src.Vendor.Longitude.Value : 0))
            .ForMember(dest => dest.CustomerName, opt => opt.MapFrom(src => src.Customer != null ? src.Customer.FullName : "Unknown Customer"))
            .ForMember(dest => dest.DeliveryAddress, opt => opt.MapFrom(src => src.DeliveryAddress != null ? src.DeliveryAddress.FullAddress : ""))
            .ForMember(dest => dest.DeliveryLatitude, opt => opt.MapFrom(src => src.DeliveryAddress != null && src.DeliveryAddress.Latitude.HasValue ? (double)src.DeliveryAddress.Latitude.Value : 0))
            .ForMember(dest => dest.DeliveryLongitude, opt => opt.MapFrom(src => src.DeliveryAddress != null && src.DeliveryAddress.Longitude.HasValue ? (double)src.DeliveryAddress.Longitude.Value : 0))
            .ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.Status.ToString()))
            .ForMember(dest => dest.Items, opt => opt.MapFrom(src => src.OrderItems));

        // OrderCourier -> CourierOrderDto (Order bilgileri OrderCourier.Order üzerinden)
        CreateMap<OrderCourier, CourierOrderDto>()
            .ForMember(dest => dest.Id, opt => opt.MapFrom(src => src.Order != null ? src.Order.Id : Guid.Empty))
            .ForMember(dest => dest.CustomerOrderId, opt => opt.MapFrom(src => src.Order != null ? src.Order.CustomerOrderId : string.Empty))
            .ForMember(dest => dest.VendorName, opt => opt.MapFrom(src => src.Order != null && src.Order.Vendor != null ? src.Order.Vendor.Name : "Unknown Vendor"))
            .ForMember(dest => dest.VendorAddress, opt => opt.MapFrom(src => src.Order != null && src.Order.Vendor != null ? src.Order.Vendor.Address : ""))
            .ForMember(dest => dest.VendorLatitude, opt => opt.MapFrom(src => src.Order != null && src.Order.Vendor != null && src.Order.Vendor.Latitude.HasValue ? (double)src.Order.Vendor.Latitude.Value : 0))
            .ForMember(dest => dest.VendorLongitude, opt => opt.MapFrom(src => src.Order != null && src.Order.Vendor != null && src.Order.Vendor.Longitude.HasValue ? (double)src.Order.Vendor.Longitude.Value : 0))
            .ForMember(dest => dest.CustomerName, opt => opt.MapFrom(src => src.Order != null && src.Order.Customer != null ? src.Order.Customer.FullName : "Unknown Customer"))
            .ForMember(dest => dest.DeliveryAddress, opt => opt.MapFrom(src => src.Order != null && src.Order.DeliveryAddress != null ? src.Order.DeliveryAddress.FullAddress : ""))
            .ForMember(dest => dest.DeliveryLatitude, opt => opt.MapFrom(src => src.Order != null && src.Order.DeliveryAddress != null && src.Order.DeliveryAddress.Latitude.HasValue ? (double)src.Order.DeliveryAddress.Latitude.Value : 0))
            .ForMember(dest => dest.DeliveryLongitude, opt => opt.MapFrom(src => src.Order != null && src.Order.DeliveryAddress != null && src.Order.DeliveryAddress.Longitude.HasValue ? (double)src.Order.DeliveryAddress.Longitude.Value : 0))
            .ForMember(dest => dest.TotalAmount, opt => opt.MapFrom(src => src.Order != null ? src.Order.TotalAmount : 0))
            .ForMember(dest => dest.DeliveryFee, opt => opt.MapFrom(src => src.DeliveryFee))
            .ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.Order != null ? src.Order.Status.ToString() : ""))
            .ForMember(dest => dest.CreatedAt, opt => opt.MapFrom(src => src.Order != null ? src.Order.CreatedAt : DateTime.UtcNow))
            .ForMember(dest => dest.Items, opt => opt.MapFrom(src => src.Order != null ? src.Order.OrderItems : new List<OrderItem>()))
            .ForMember(dest => dest.CourierStatus, opt => opt.MapFrom(src => src.Status))
            .ForMember(dest => dest.CourierAssignedAt, opt => opt.MapFrom(src => src.CourierAssignedAt))
            .ForMember(dest => dest.CourierAcceptedAt, opt => opt.MapFrom(src => src.CourierAcceptedAt))
            .ForMember(dest => dest.CourierRejectedAt, opt => opt.MapFrom(src => src.CourierRejectedAt))
            .ForMember(dest => dest.RejectReason, opt => opt.MapFrom(src => src.RejectReason))
            .ForMember(dest => dest.PickedUpAt, opt => opt.MapFrom(src => src.PickedUpAt))
            .ForMember(dest => dest.OutForDeliveryAt, opt => opt.MapFrom(src => src.OutForDeliveryAt))
            .ForMember(dest => dest.DeliveredAt, opt => opt.MapFrom(src => src.DeliveredAt))
            .ForMember(dest => dest.CourierTip, opt => opt.MapFrom(src => src.CourierTip));
    }
}
