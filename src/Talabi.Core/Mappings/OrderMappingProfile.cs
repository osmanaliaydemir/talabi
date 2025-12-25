using AutoMapper;
using Talabi.Core.DTOs;
using Talabi.Core.Entities;

namespace Talabi.Core.Mappings;

/// <summary>
/// Order entity to DTO mapping profile
/// </summary>
public class OrderMappingProfile : Profile
{
    public OrderMappingProfile()
    {
        // Order -> OrderDto
        CreateMap<Order, OrderDto>()
            .ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.Status.ToString()))
            .ForMember(dest => dest.VendorName, opt => opt.MapFrom(src => src.Vendor != null ? src.Vendor.Name : string.Empty))
            .ForMember(dest => dest.ActiveOrderCourier, opt => opt.Ignore());

        // Order -> OrderDetailDto
        CreateMap<Order, OrderDetailDto>()
            .ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.Status.ToString()))
            .ForMember(dest => dest.VendorName, opt => opt.MapFrom(src => src.Vendor != null ? src.Vendor.Name : string.Empty))
            .ForMember(dest => dest.CustomerName, opt => opt.MapFrom(src => src.Customer != null ? src.Customer.FullName : string.Empty))
            .ForMember(dest => dest.ActiveOrderCourier, opt => opt.Ignore())
            .ForMember(dest => dest.Items, opt => opt.MapFrom(src => src.OrderItems.Select(oi => new OrderItemDetailDto
            {
                ProductId = oi.ProductId,
                CustomerOrderItemId = oi.CustomerOrderItemId,
                ProductName = oi.Product != null ? oi.Product.Name : string.Empty,
                ProductImageUrl = oi.Product != null ? oi.Product.ImageUrl : null,
                Quantity = oi.Quantity,
                UnitPrice = oi.UnitPrice,
                TotalPrice = oi.Quantity * oi.UnitPrice,
                IsCancelled = oi.IsCancelled,
                CancelledAt = oi.CancelledAt,
                CancelReason = oi.CancelReason
            }).ToList()))
            .ForMember(dest => dest.StatusHistory, opt => opt.MapFrom(src => src.StatusHistory.Select(sh => new OrderStatusHistoryDto
            {
                Status = sh.Status.ToString(),
                Note = sh.Note,
                CreatedAt = sh.CreatedAt,
                CreatedBy = sh.CreatedBy
            }).ToList()));

        // Order -> VendorOrderDto
        CreateMap<Order, VendorOrderDto>()
            .ForMember(dest => dest.Status, opt => opt.MapFrom(src => src.Status.ToString()))
            .ForMember(dest => dest.CustomerName, opt => opt.MapFrom(src => src.Customer != null ? src.Customer.FullName : string.Empty))
            .ForMember(dest => dest.CustomerEmail, opt => opt.MapFrom(src => src.Customer != null ? src.Customer.Email : string.Empty))
            .ForMember(dest => dest.Items, opt => opt.MapFrom(src => src.OrderItems));

        // OrderItem -> VendorOrderItemDto
        CreateMap<OrderItem, VendorOrderItemDto>()
            .ForMember(dest => dest.ProductName, opt => opt.MapFrom(src => src.Product != null ? src.Product.Name : string.Empty))
            .ForMember(dest => dest.ProductImageUrl, opt => opt.MapFrom(src => src.Product != null ? src.Product.ImageUrl : null))
            .ForMember(dest => dest.TotalPrice, opt => opt.MapFrom(src => src.Quantity * src.UnitPrice));
    }
}
