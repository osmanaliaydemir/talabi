# Postman Test Senaryoları - Product Search & Category Filter (Cache Bypass)

## ⚠️ ÖNEMLİ: Cache Temizleme

**GetCategories endpoint'i cache kullanıyor!** Eğer kategori listesi güncel değilse:
1. Backend'i restart edin
2. Veya cache'i temizleyin

---

## Test Senaryosu 1: Kategori Filtreleme (CategoryId + Category String) - CACHE BYPASS

### Request:
```
GET https://talabi.runasp.net/api/products/search
```

### Query Parameters:
```
page: 1
pageSize: 50
categoryId: {KEBAP_DONER_CATEGORY_ID}
category: Kebap & Döner
vendorType: 1
userLatitude: 40.981753363733255
userLongitude: 29.151309728622437
```

### Headers:
```
Authorization: Bearer {YOUR_TOKEN}
Content-Type: application/json
Accept: application/json
Cache-Control: no-cache
Pragma: no-cache
```

**NOT:** `Cache-Control: no-cache` header'ını ekleyin (Search endpoint'inde cache yok ama diğer endpoint'lerde olabilir)

### Beklenen Sonuç:
- Status: 200 OK
- Response body'de "Test Ürünü" ürünü gelmelidir
- CategoryId veya Category string ile eşleşen ürünler gelmelidir
- Log'larda debug mesajlarını görmelişisiniz

---

## Test Senaryosu 2: Önce Kategori Listesini Al (CategoryId Bulmak İçin)

### Request:
```
GET https://talabi.runasp.net/api/products/categories?vendorType=1&userLatitude=40.981753363733255&userLongitude=29.151309728622437
```

### Headers:
```
Authorization: Bearer {YOUR_TOKEN}
Cache-Control: no-cache
Pragma: no-cache
```

### Response'dan:
- "Kebap & Döner" kategorisinin `id` değerini alın
- Bu ID'yi sonraki testlerde `categoryId` olarak kullanın

---

## Test Senaryosu 3: CategoryId + Category String ile Arama

### Request:
```
GET https://talabi.runasp.net/api/products/search?page=1&pageSize=50&categoryId={CATEGORY_ID}&category=Kebap%20%26%20Döner&vendorType=1&userLatitude=40.981753363733255&userLongitude=29.151309728622437
```

### Beklenen Sonuç:
- **Response'da "Test Ürünü" ürünü gelmeli!**
- Eğer gelmiyorsa, backend log'larını kontrol edin

---

## Test Senaryosu 4: Sadece CategoryId ile (Category String Olmadan)

### Request:
```
GET https://talabi.runasp.net/api/products/search?page=1&pageSize=50&categoryId={CATEGORY_ID}&vendorType=1&userLatitude=40.981753363733255&userLongitude=29.151309728622437
```

### Beklenen Sonuç:
- CategoryId ile eşleşen ürünler gelmelidir

---

## Test Senaryosu 5: Sadece Category String ile (CategoryId Olmadan)

### Request:
```
GET https://talabi.runasp.net/api/products/search?page=1&pageSize=50&category=Kebap%20%26%20Döner&vendorType=1&userLatitude=40.981753363733255&userLongitude=29.151309728622437
```

### Beklenen Sonuç:
- Category string ile eşleşen ürünler gelmelidir (case-insensitive, Contains match ile)

---

## Test Senaryosu 6: Vendor Radius Dışında Test

### Request:
```
GET https://talabi.runasp.net/api/products/search?page=1&pageSize=50&category=Kebap%20%26%20Döner&vendorType=1&userLatitude=41.082377030830514&userLongitude=29.066766165196892
```

### Not:
- Bu konum Üsküdar (vendor'ın olduğu yer)
- Eğer vendor DeliveryRadiusInKm = 0 ise, 5km default kullanılır
- 5km içindeyse ürün gelmeli, dışındaysa boş liste gelmeli

---

## Postman Collection (Hazır Test Senaryoları)

### Environment Variables:
```json
{
  "baseUrl": "https://talabi.runasp.net",
  "token": "YOUR_TOKEN_HERE",
  "categoryId": "YOUR_CATEGORY_ID_HERE",
  "userLat": "40.981753363733255",
  "userLon": "29.151309728622437"
}
```

### Test 1: Get Categories (CategoryId Bul)
```
GET {{baseUrl}}/api/products/categories?vendorType=1&userLatitude={{userLat}}&userLongitude={{userLon}}
Headers:
  Authorization: Bearer {{token}}
  Cache-Control: no-cache
```

### Test 2: Search with CategoryId + Category
```
GET {{baseUrl}}/api/products/search?page=1&pageSize=50&categoryId={{categoryId}}&category=Kebap%20%26%20Döner&vendorType=1&userLatitude={{userLat}}&userLongitude={{userLon}}
Headers:
  Authorization: Bearer {{token}}
  Cache-Control: no-cache
```

### Test 3: Search with Category String Only
```
GET {{baseUrl}}/api/products/search?page=1&pageSize=50&category=Kebap%20%26%20Döner&vendorType=1&userLatitude={{userLat}}&userLongitude={{userLon}}
Headers:
  Authorization: Bearer {{token}}
  Cache-Control: no-cache
```

---

## cURL Komutları (Hızlı Test)

```bash
# 1. Önce kategorileri al (CategoryId bul)
curl -X GET "https://talabi.runasp.net/api/products/categories?vendorType=1&userLatitude=40.981753363733255&userLongitude=29.151309728622437" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Cache-Control: no-cache"

# 2. CategoryId + Category String ile arama
curl -X GET "https://talabi.runasp.net/api/products/search?page=1&pageSize=50&categoryId=YOUR_CATEGORY_ID&category=Kebap%20%26%20Döner&vendorType=1&userLatitude=40.981753363733255&userLongitude=29.151309728622437" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Cache-Control: no-cache"

# 3. Sadece Category String ile arama
curl -X GET "https://talabi.runasp.net/api/products/search?page=1&pageSize=50&category=Kebap%20%26%20Döner&vendorType=1&userLatitude=40.981753363733255&userLongitude=29.151309728622437" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Cache-Control: no-cache"
```

---

## Backend Log Kontrol Listesi

Test yaptığınızda backend log'larında şunları görmelisiniz:

```
✅ [PRODUCT_SEARCH] CategoryId parsed successfully: {GUID}
✅ [PRODUCT_SEARCH] Category string: 'Kebap & Döner'
✅ [PRODUCT_SEARCH] Final request - CategoryId: {GUID}, Category: 'Kebap & Döner'
✅ [PRODUCT_SEARCH] Filtering {COUNT} products. CategoryId: {GUID}, Category: 'Kebap & Döner'
✅ [PRODUCT_SEARCH] Product: Test Ürünü | CategoryId: {GUID} | Category: 'Kebap & Döner' | VendorId: {GUID}
✅ [PRODUCT_SEARCH] After category filter: {COUNT} products
✅ [PRODUCT_SEARCH] Category matched product: Test Ürünü | CategoryId: {GUID} | Category: 'Kebap & Döner'
```

**Eğer bu log'lar görünmüyorsa:**
- Request doğru gitmiyor olabilir
- Endpoint'e ulaşılamıyor olabilir
- Authorization problemi olabilir

---

## Sorun Giderme Adımları

### 1. Ürün Gelmiyor mu?

**Kontrol Listesi:**
- [ ] CategoryId doğru parse edildi mi? (Log'da görünmeli)
- [ ] Category string doğru mu? (Log'da görünmeli)
- [ ] Vendor radius içinde mi? (vendorsInRadius boş mu kontrol et)
- [ ] Ürün IsAvailable = true mi?
- [ ] Ürünün CategoryId veya Category field'ı dolu mu?

### 2. CategoryId Parse Edilemiyor mu?

**Olası Nedenler:**
- CategoryId GUID formatında değil
- Query parameter doğru gönderilmemiş
- URL encoding problemi

**Çözüm:**
- CategoryId'yi direkt GUID formatında gönderin: `123e4567-e89b-12d3-a456-426614174000`
- URL'de `categoryId` parametresi camelCase olmalı

### 3. Category String Eşleşmiyor mu?

**Olası Nedenler:**
- Boşluk farklılıkları
- & karakteri encoding problemi
- Case sensitivity (ama bu case-insensitive olmalı)

**Çözüm:**
- URL encode kullanın: `Kebap%20%26%20Döner`
- Veya sadece CategoryId kullanın

### 4. Cache Problemi mi?

**GetCategories Endpoint'i Cache Kullanıyor:**
- `/api/products/categories` endpoint'i cache kullanır
- Eğer kategori listesi güncel değilse, cache'i temizleyin veya backend'i restart edin

**Search Endpoint'i Cache Kullanmıyor:**
- `/api/products/search` endpoint'i cache kullanmaz
- Her seferinde fresh data döner

---

## Beklenen Response Formatı

```json
{
  "success": true,
  "message": "ProductsRetrievedSuccessfully",
  "data": {
    "items": [
      {
        "id": "product-guid",
        "vendorId": "vendor-guid",
        "vendorName": "Kebapcı",
        "name": "Test Ürünü",
        "description": "Test Ürünü hakkında açıklama yazısı burada çıkacak.",
        "category": "Kebap & Döner",
        "categoryId": "category-guid",
        "price": 200.00,
        "currency": 1,
        "imageUrl": "...",
        "isBestSeller": false,
        "reviewCount": 0,
        "rating": null
      }
    ],
    "totalCount": 1,
    "page": 1,
    "pageSize": 50,
    "totalPages": 1
  },
  "errorCode": null,
  "errors": null
}
```

---

## Kritik Test Senaryosu: Gerçek Durum Testi

### Senaryo:
1. **Ana sayfada "Test Ürünü" görünüyor mu?** (GetPopularProducts)
   ```
   GET /api/products/popular?vendorType=1&userLatitude=40.981753363733255&userLongitude=29.151309728622437
   ```

2. **Kategori listesinde "Kebap & Döner" görünüyor mu?** (GetCategories)
   ```
   GET /api/products/categories?vendorType=1&userLatitude=40.981753363733255&userLongitude=29.151309728622437
   ```

3. **Kategori detay sayfasında ürün görünüyor mu?** (Search with CategoryId)
   ```
   GET /api/products/search?categoryId={CATEGORY_ID}&category=Kebap%20%26%20Döner&vendorType=1&userLatitude=40.981753363733255&userLongitude=29.151309728622437
   ```

**Eğer 1 ve 2 TRUE ama 3 FALSE ise:**
- Category filter logic'inde sorun var!
- Backend log'larını mutlaka kontrol edin!
