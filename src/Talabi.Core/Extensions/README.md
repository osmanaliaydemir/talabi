# Gelişmiş Query Desteği

Bu dokümantasyon, Repository pattern için eklenen gelişmiş query yardımcı metodlarını açıklar.

## Kullanılabilir Extension Metodlar

### 1. Pagination

#### `Paginate<T>(int page, int pageSize)`
Query'yi sayfalar.

```csharp
var products = await _unitOfWork.Products.Query()
    .Include(p => p.Vendor)
    .Paginate(page: 1, pageSize: 20)
    .ToListAsync();
```

#### `ToPagedResultAsync<T>(int page, int pageSize)`
Query'yi sayfalar ve `PagedResult<T>` döner.

```csharp
var result = await _unitOfWork.Products.Query()
    .Include(p => p.Vendor)
    .OrderBy(p => p.Name)
    .ToPagedResultAsync(page: 1, pageSize: 20);
    
// result.Items - Ürün listesi
// result.TotalCount - Toplam kayıt sayısı
// result.TotalPages - Toplam sayfa sayısı
// result.HasNextPage - Sonraki sayfa var mı?
// result.HasPreviousPage - Önceki sayfa var mı?
```

#### `ToPagedResultAsync<TEntity, TDto>(Expression<Func<TEntity, TDto>> mapper, int page, int pageSize)`
Query'yi sayfalar ve DTO'ya map eder.

```csharp
var result = await _unitOfWork.Products.Query()
    .Include(p => p.Vendor)
    .ToPagedResultAsync(
        p => new ProductDto
        {
            Id = p.Id,
            Name = p.Name,
            VendorName = p.Vendor != null ? p.Vendor.Name : null
        },
        page: 1,
        pageSize: 20);
```

### 2. Dinamik Sıralama

#### `OrderByDynamic<T>(string propertyName, bool ascending = true)`
Property adına göre dinamik sıralama yapar.

```csharp
var products = await _unitOfWork.Products.Query()
    .OrderByDynamic("Name", ascending: true)
    .ToListAsync();
```

#### `ThenByDynamic<T>(string propertyName, bool ascending = true)`
İkincil sıralama için kullanılır.

```csharp
var products = await _unitOfWork.Products.Query()
    .OrderByDynamic("Price", ascending: false)
    .ThenByDynamic("Name", ascending: true)
    .ToListAsync();
```

### 3. Case-Insensitive Arama

#### `WhereContainsIgnoreCase<T>(Expression<Func<T, string?>> propertySelector, string searchTerm)`
Büyük/küçük harf duyarsız arama yapar.

```csharp
var products = await _unitOfWork.Products.Query()
    .WhereContainsIgnoreCase(p => p.Name, "laptop")
    .ToListAsync();
```

### 4. Tarih Aralığı Filtresi

#### `WhereDateRange<T>(Expression<Func<T, DateTime?>> datePropertySelector, DateTime? startDate, DateTime? endDate)`
Tarih aralığına göre filtreler.

```csharp
var orders = await _unitOfWork.Orders.Query()
    .WhereDateRange(o => o.CreatedAt, startDate: DateTime.Today.AddDays(-30), endDate: DateTime.Today)
    .ToListAsync();
```

### 5. Null Kontrolü

#### `WhereNull<T, TProperty>(Expression<Func<T, TProperty?>> propertySelector, bool includeNull = false)`
Nullable property için null kontrolü yapar.

```csharp
// Sadece courier atanmış siparişler
var orders = await _unitOfWork.Orders.Query()
    .WhereNull(o => o.CourierId, includeNull: false)
    .ToListAsync();

// Sadece courier atanmamış siparişler
var unassignedOrders = await _unitOfWork.Orders.Query()
    .WhereNull(o => o.CourierId, includeNull: true)
    .ToListAsync();
```

## Kullanım Örnekleri

### Örnek 1: Karmaşık Query (Include, Filter, Pagination)

```csharp
IQueryable<Order> query = _unitOfWork.Orders.Query()
    .Include(o => o.Vendor)
    .Include(o => o.Customer)
    .Include(o => o.OrderItems)
        .ThenInclude(oi => oi.Product);

// Status filtresi
if (!string.IsNullOrWhiteSpace(status))
{
    if (Enum.TryParse<OrderStatus>(status, true, out var orderStatus))
    {
        query = query.Where(o => o.Status == orderStatus);
    }
}

// Tarih aralığı filtresi
query = query.WhereDateRange(o => o.CreatedAt, startDate, endDate);

// Sıralama ve pagination
var result = await query
    .OrderByDescending(o => o.CreatedAt)
    .ToPagedResultAsync(
        o => new OrderDto
        {
            Id = o.Id,
            VendorName = o.Vendor?.Name ?? "",
            TotalAmount = o.TotalAmount
        },
        page,
        pageSize);
```

### Örnek 2: Case-Insensitive Arama ile Pagination

```csharp
var query = _unitOfWork.Products.Query()
    .Include(p => p.Vendor);

if (!string.IsNullOrWhiteSpace(searchTerm))
{
    query = query.WhereContainsIgnoreCase(p => p.Name, searchTerm);
}

var result = await query
    .OrderBy(p => p.Name)
    .ToPagedResultAsync(page, pageSize);
```

## Notlar

- `Include()` ve `ThenInclude()` metodları zaten EF Core'da mevcut, bu extension metodlar ek yardımcılar sağlar
- Tüm extension metodlar `IQueryable<T>` üzerinde çalışır, bu yüzden veritabanı sorgusu yapılmadan önce zincirlenebilir
- `ToPagedResultAsync` metodları `ToListAsync()` çağrısını içerir, bu yüzden sonunda tekrar `ToListAsync()` çağırmaya gerek yoktur

