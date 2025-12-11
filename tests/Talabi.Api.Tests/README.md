# Talabi.Api.Tests

Bu proje, Talabi API controller'ları için unit testleri içerir.

## Kullanılan Teknolojiler

- **xUnit**: Test framework
- **Moq**: Mocking framework
- **FluentAssertions**: Assertion library
- **Microsoft.AspNetCore.Mvc.Testing**: Integration test desteği
- **Microsoft.EntityFrameworkCore.InMemory**: In-memory database test desteği

## Test Yapısı

### Controllers/
Controller'lar için unit testler bu klasörde bulunur.

### Helpers/
Test helper metodları ve mock factory'ler bu klasörde bulunur.

## Test Çalıştırma

```bash
# Tüm testleri çalıştır
dotnet test

# Belirli bir test sınıfını çalıştır
dotnet test --filter "FullyQualifiedName~MapControllerTests"

# Verbose output ile çalıştır
dotnet test --verbosity normal
```

## Örnek Testler

### MapControllerTests
- `GetApiKey_WhenApiKeyExists_ReturnsOkWithApiKey`: API key başarıyla döndürülür
- `GetApiKey_WhenApiKeyNotConfigured_ReturnsNotFound`: API key yapılandırılmamışsa 404 döner
- `GetApiKey_WhenConfigurationIsNull_ReturnsInternalServerError`: Configuration null ise 500 döner

### BaseControllerTests
- `GetLanguageFromRequest_WithQueryParameter_ReturnsNormalizedLanguage`: Query parametresinden dil alınır
- `GetLanguageFromRequest_WithAcceptLanguageHeader_ReturnsNormalizedLanguage`: Accept-Language header'ından dil alınır
- `GetLanguageFromRequest_WithoutLanguage_ReturnsDefaultTurkish`: Dil belirtilmezse varsayılan Türkçe döner
- `NormalizeLanguageCode_WithVariousInputs_ReturnsCorrectLanguage`: Çeşitli dil kodları normalize edilir

### AuthControllerTests
- `Register_WhenValidDto_ReturnsOk`: Geçerli kayıt DTO'su ile başarılı kayıt
- `Register_WhenInvalidOperationException_ReturnsBadRequest`: Geçersiz işlem exception'ı durumunda BadRequest
- `Register_WhenException_ReturnsInternalServerError`: Genel exception durumunda InternalServerError

### ProductsControllerTests
- `GetProduct_WhenProductExists_ReturnsOk`: Ürün bulunduğunda başarılı dönüş
- `GetProduct_WhenProductNotFound_ReturnsNotFound`: Ürün bulunamadığında NotFound
- `GetProduct_WhenProductHasVendor_ReturnsOkWithVendorInfo`: Vendor bilgisi ile ürün döndürme

### VendorsControllerTests
- `GetVendors_WhenNoFilters_ReturnsAllActiveVendors`: Filtre olmadan tüm aktif vendor'ları getirme
- `GetVendors_WhenVendorTypeFilter_ReturnsFilteredVendors`: VendorType filtresi ile filtreleme
- `GetVendors_WhenPageIsLessThanOne_SetsPageToOne`: Sayfa numarası düzeltme
- `GetVendors_WhenPageSizeIsLessThanOne_SetsPageSizeToSix`: Sayfa boyutu düzeltme

## Yeni Test Ekleme

1. `Controllers/` klasörüne yeni test dosyası ekleyin
2. `ControllerTestHelpers` sınıfını kullanarak mock'lar oluşturun
3. FluentAssertions kullanarak assertion'lar yazın

## Örnek Test Yazımı

```csharp
public class MyControllerTests
{
    [Fact]
    public void MyAction_WhenCondition_ReturnsExpected()
    {
        // Arrange
        var mockUnitOfWork = ControllerTestHelpers.CreateMockUnitOfWork();
        var logger = ControllerTestHelpers.CreateMockLogger<MyController>();
        // ... diğer mock'lar

        var controller = new MyController(
            mockUnitOfWork.Object,
            logger,
            // ... diğer bağımlılıklar
        )
        {
            ControllerContext = ControllerTestHelpers.CreateControllerContext()
        };

        // Act
        var result = controller.MyAction();

        // Assert
        result.Should().NotBeNull();
        // ... diğer assertion'lar
    }
}
```

