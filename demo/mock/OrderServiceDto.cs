// ============================================================================
// ApexOperations ERP - Synthetic C# .NET 8 Domain & Service Model
// Demonstrates modern C# 12 patterns, immutability, and clean repository access.
// ============================================================================

namespace ApexOperations.Core.Orders;

public enum OrderStatus
{
    Draft = 10,
    Approved = 20,
    Allocated = 30,
    InProduction = 40,
    QualityChecked = 50,
    Dispatched = 60,
    Invoiced = 70,
    Cancelled = 99
}

public sealed record OrderLineItemDto(
    int ComponentId,
    string ComponentSku,
    int Quantity,
    decimal UnitPrice
)
{
    public decimal LineTotal => Quantity * UnitPrice;
}

public sealed record CreateOrderRequest(
    int CustomerId,
    string DeliveryAddress,
    IReadOnlyList<OrderLineItemDto> Items
);

public sealed record OrderSummaryResponse(
    int OrderId,
    int CustomerId,
    string CustomerName,
    OrderStatus Status,
    decimal TotalAmount,
    DateTime CreatedUtc
);

public interface IOrderService
{
    Task<OrderSummaryResponse> CreateOrderAsync(CreateOrderRequest request, CancellationToken cancellationToken = default);
    Task<bool> TransitionStatusAsync(int orderId, OrderStatus targetStatus, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<OrderSummaryResponse>> GetPendingAllocationsAsync(CancellationToken cancellationToken = default);
}
