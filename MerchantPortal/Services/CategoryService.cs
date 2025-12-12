using Getir.MerchantPortal.Models;
using Microsoft.Extensions.Caching.Memory;

namespace Getir.MerchantPortal.Services;

public class CategoryService : ICategoryService
{
    private readonly IApiClient _apiClient;
    private readonly ILogger<CategoryService> _logger;
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly IMemoryCache _cache;

    /// <summary>
    /// CategoryService constructor
    /// </summary>
    /// <param name="apiClient">API client</param>
    /// <param name="logger">Logger instance</param>
    /// <param name="httpContextAccessor">HTTP context erişimi</param>
    public CategoryService(
        IApiClient apiClient, 
        ILogger<CategoryService> logger,
        IHttpContextAccessor httpContextAccessor,
        IMemoryCache cache)
    {
        _apiClient = apiClient;
        _logger = logger;
        _httpContextAccessor = httpContextAccessor;
        _cache = cache;
    }

    /// <summary>
    /// Session'dan merchant ID'yi al
    /// </summary>
    /// <returns>Merchant ID</returns>
    private Guid GetMerchantIdFromContext()
    {
        var merchantIdStr = _httpContextAccessor.HttpContext?.Session.GetString("MerchantId");
        _logger.LogInformation("GetMerchantIdFromContext - Session MerchantId: '{MerchantId}'", merchantIdStr ?? "(null)");
        
        if (string.IsNullOrEmpty(merchantIdStr) || !Guid.TryParse(merchantIdStr, out var merchantId))
        {
            _logger.LogError("MerchantId not found or invalid in session. Value: '{Value}'", merchantIdStr ?? "(null)");
            throw new InvalidOperationException("MerchantId not found in session");
        }
        
        _logger.LogInformation("MerchantId parsed: {MerchantId}", merchantId);
        return merchantId;
    }
    /// <summary>
    /// Kategorileri getir
    /// </summary>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Kategori listesi</returns>

    public async Task<List<ProductCategoryResponse>?> GetCategoriesAsync(CancellationToken ct = default)
    {
        try
        {
            if (_cache.TryGetValue("categories:all", out List<ProductCategoryResponse>? cached) && cached != null)
                return cached;

            var response = await _apiClient.GetAsync<ApiResponse<List<ProductCategoryResponse>>>("api/v1/productcategory", ct);
            var data = response?.Data ?? new List<ProductCategoryResponse>();
            _cache.Set("categories:all", data, TimeSpan.FromMinutes(5));
            return data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting categories");
            return null;
        }
    }

    /// <summary>
    /// Mağaza kategorilerini getir
    /// </summary>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Mağaza kategorileri</returns>
    public async Task<List<ProductCategoryResponse>?> GetMyCategoriesAsync(CancellationToken ct = default)
    {
        try
        {
            // Get merchantId and use the flat list endpoint
            var merchantId = GetMerchantIdFromContext();
            var response = await _apiClient.GetAsync<ApiResponse<List<ProductCategoryResponse>>>(
                $"api/v1/productcategory/merchant/{merchantId}", 
                ct);

            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting my categories");
            return null;
        }
    }

    /// <summary>
    /// Standart kategorileri getir
    /// </summary>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Standart kategoriler</returns>
    public async Task<List<ProductCategoryResponse>?> GetStandardCategoriesAsync(CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<List<ProductCategoryResponse>>>("api/v1/productcategory/standard", ct);

            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting standard categories");
            return null;
        }
    }

    /// <summary>
    /// Kategori detaylarını getir
    /// </summary>
    /// <param name="categoryId">Kategori ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Kategori detayları</returns>
    public async Task<ProductCategoryResponse?> GetCategoryByIdAsync(Guid categoryId, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.GetAsync<ApiResponse<ProductCategoryResponse>>($"api/v1/productcategory/{categoryId}", ct);

            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting category {CategoryId}", categoryId);
            return null;
        }
    }

    /// <summary>
    /// Kategori oluştur
    /// </summary>
    /// <param name="request">Kategori oluşturma isteği</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Oluşturulan kategori</returns>
    public async Task<ProductCategoryResponse?> CreateCategoryAsync(CreateCategoryRequest request, CancellationToken ct = default)
    {
        try
        {
            // Get merchantId from session
            var merchantId = GetMerchantIdFromContext();
            var response = await _apiClient.PostAsync<ApiResponse<ProductCategoryResponse>>(
                $"api/v1/productcategory/merchant/{merchantId}", 
                request, 
                ct);
            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating category");
            return null;
        }
    }

    /// <summary>
    /// Kategoriyi güncelle
    /// </summary>
    /// <param name="categoryId">Kategori ID</param>
    /// <param name="request">Kategori güncelleme isteği</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Güncellenen kategori</returns>
    public async Task<ProductCategoryResponse?> UpdateCategoryAsync(Guid categoryId, UpdateCategoryRequest request, CancellationToken ct = default)
    {
        try
        {
            var response = await _apiClient.PutAsync<ApiResponse<ProductCategoryResponse>>($"api/v1/productcategory/{categoryId}", request, ct);

            return response?.Data;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating category {CategoryId}", categoryId);
            return null;
        }
    }

    /// <summary>
    /// Kategoriyi sil
    /// </summary>
    /// <param name="categoryId">Kategori ID</param>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>İşlem başarı durumu</returns>
    public async Task<bool> DeleteCategoryAsync(Guid categoryId, CancellationToken ct = default)
    {
        try
        {
            return await _apiClient.DeleteAsync($"api/v1/productcategory/{categoryId}", ct);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting category {CategoryId}", categoryId);
            return false;
        }
    }

    /// <summary>
    /// Kategori ağacını getir
    /// </summary>
    /// <param name="ct">İptal token'ı</param>
    /// <returns>Kategori ağacı</returns>
    public async Task<List<CategoryTreeNode>?> GetCategoryTreeAsync(CancellationToken ct = default)
    {
        try
        {
            var categories = await GetMyCategoriesAsync(ct);
            if (categories == null) return null;

            return BuildCategoryTree(categories);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error building category tree");
            return null;
        }
    }

    /// <summary>
    /// Kategori ağacını oluştur
    /// </summary>
    /// <param name="categories">Kategori listesi</param>
    /// <returns>Kategori ağacı</returns>
    private List<CategoryTreeNode> BuildCategoryTree(List<ProductCategoryResponse> categories)
    {
        // Build hierarchical tree structure
        var categoryDict = categories.ToDictionary(c => c.Id, c => new CategoryTreeNode
        {
            Category = c,
            Children = new List<CategoryTreeNode>()
        });

        var rootNodes = new List<CategoryTreeNode>();

        foreach (var node in categoryDict.Values)
        {
            if (node.Category.ParentCategoryId.HasValue &&
                categoryDict.TryGetValue(node.Category.ParentCategoryId.Value, out var parentNode))
            {
                parentNode.Children.Add(node);
            }
            else
            {
                rootNodes.Add(node);
            }
        }

        return rootNodes;
    }
}

