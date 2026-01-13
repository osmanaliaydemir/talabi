# Product Search API Request Örnekleri

## Base URL
- **HTTP:** `http://localhost:5205`
- **HTTPS:** `https://localhost:7278`

## Endpoint
`GET /api/products/search`

## Örnek Request URL'leri

### 1. Basit Arama (Sadece Query + Konum)
```
GET http://localhost:5205/api/products/search?query=burger&userLatitude=41.0082&userLongitude=28.9784&page=1&pageSize=20
```

### 2. Kategori Filtresi ile Arama
```
GET http://localhost:5205/api/products/search?query=burger&categoryId=123e4567-e89b-12d3-a456-426614174000&userLatitude=41.0082&userLongitude=28.9784&page=1&pageSize=20
```

### 3. VendorType Filtresi ile Arama (Restaurant = 1, Market = 2)
```
GET http://localhost:5205/api/products/search?query=pizza&vendorType=1&userLatitude=41.0082&userLongitude=28.9784&page=1&pageSize=20
```

### 4. Fiyat Aralığı ile Arama
```
GET http://localhost:5205/api/products/search?query=burger&minPrice=50&maxPrice=200&userLatitude=41.0082&userLongitude=28.9784&page=1&pageSize=20
```

### 5. Sıralama ile Arama
```
GET http://localhost:5205/api/products/search?query=burger&sortBy=price_asc&userLatitude=41.0082&userLongitude=28.9784&page=1&pageSize=20
```

### 6. Tüm Filtreler ile Arama
```
GET http://localhost:5205/api/products/search?query=burger&categoryId=123e4567-e89b-12d3-a456-426614174000&vendorType=1&minPrice=50&maxPrice=200&sortBy=price_asc&userLatitude=41.0082&userLongitude=28.9784&page=1&pageSize=20
```

### 7. Sadece Konum ile Arama (Query olmadan)
```
GET http://localhost:5205/api/products/search?userLatitude=41.0082&userLongitude=28.9784&page=1&pageSize=20
```

## cURL Örnekleri

### Basit Arama
```bash
curl -X GET "http://localhost:5205/api/products/search?query=burger&userLatitude=41.0082&userLongitude=28.9784&page=1&pageSize=20" \
  -H "Content-Type: application/json"
```

### Tüm Filtreler ile
```bash
curl -X GET "http://localhost:5205/api/products/search?query=burger&categoryId=123e4567-e89b-12d3-a456-426614174000&vendorType=1&minPrice=50&maxPrice=200&sortBy=price_asc&userLatitude=41.0082&userLongitude=28.9784&page=1&pageSize=20" \
  -H "Content-Type: application/json"
```

## Postman Collection Örneği

```json
{
  "name": "Product Search",
  "request": {
    "method": "GET",
    "header": [
      {
        "key": "Content-Type",
        "value": "application/json"
      }
    ],
    "url": {
      "raw": "http://localhost:5205/api/products/search?query=burger&userLatitude=41.0082&userLongitude=28.9784&page=1&pageSize=20",
      "protocol": "http",
      "host": ["localhost"],
      "port": "5205",
      "path": ["api", "products", "search"],
      "query": [
        {
          "key": "query",
          "value": "burger"
        },
        {
          "key": "userLatitude",
          "value": "41.0082"
        },
        {
          "key": "userLongitude",
          "value": "28.9784"
        },
        {
          "key": "page",
          "value": "1"
        },
        {
          "key": "pageSize",
          "value": "20"
        }
      ]
    }
  }
}
```

## Önemli Notlar

1. **userLatitude ve userLongitude ZORUNLU** - Bu parametreler gönderilmezse API boş liste döndürür.

2. **Koordinat Formatı** - Koordinatlar nokta (.) ile ayrılmış ondalık sayılar olmalı:
   - ✅ Doğru: `41.0082`, `28.9784`
   - ❌ Yanlış: `41,0082`, `28,9784` (virgül kullanılmamalı)

3. **VendorType Değerleri:**
   - `1` = Restaurant
   - `2` = Market

4. **SortBy Değerleri:**
   - `price_asc` = Fiyata göre artan
   - `price_desc` = Fiyata göre azalan
   - `name` = İsme göre
   - `newest` = En yeni

5. **Sayfalama:**
   - `page`: Sayfa numarası (varsayılan: 1)
   - `pageSize`: Sayfa başına kayıt sayısı (varsayılan: 20)

## Beklenen Response

```json
{
  "success": true,
  "message": "Products retrieved successfully",
  "data": {
    "items": [
      {
        "id": "guid",
        "vendorId": "guid",
        "vendorName": "Vendor Name",
        "name": "Product Name",
        "description": "Product Description",
        "category": "Category Name",
        "categoryId": "guid",
        "price": 100.0,
        "currency": 1,
        "imageUrl": "https://...",
        "rating": 4.5,
        "reviewCount": 10
      }
    ],
    "totalCount": 50,
    "page": 1,
    "pageSize": 20,
    "totalPages": 3
  },
  "errorCode": null,
  "errors": null
}
```

## Debug Log'ları

API log'larında şunları göreceksiniz:
- `[PRODUCT_SEARCH] Raw userLatitude from query: '41.0082'`
- `[PRODUCT_SEARCH] Parsed userLatitude: 41.0082`
- `[PRODUCT_SEARCH] Raw userLongitude from query: '28.9784'`
- `[PRODUCT_SEARCH] Parsed userLongitude: 28.9784`
- `[PRODUCT_SEARCH] Final location - UserLatitude: 41.0082, UserLongitude: 28.9784`

Eğer konum bilgisi parse edilemezse:
- `[PRODUCT_SEARCH] Failed to parse userLatitude: '...'`
- `[PRODUCT_SEARCH] User location is missing! UserLatitude: null, UserLongitude: null`
