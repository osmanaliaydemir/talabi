namespace Talabi.Core.Options;

/// <summary>
/// Cache configuration options
/// </summary>
public class CacheOptions
{
    /// <summary>
    /// Cache key prefix for categories
    /// </summary>
    public string CategoriesKeyPrefix { get; init; } = "categories";

    /// <summary>
    /// Cache TTL for categories in minutes (default: 60 minutes / 1 hour)
    /// </summary>
    public int CategoriesCacheTTLMinutes { get; init; } = 60;

    /// <summary>
    /// Cache key prefix for banners
    /// </summary>
    public string BannersKeyPrefix { get; init; } = "banners";

    /// <summary>
    /// Cache TTL for banners in minutes (default: 30 minutes)
    /// </summary>
    public int BannersCacheTTLMinutes { get; init; } = 30;

    /// <summary>
    /// Default cache TTL in minutes for other cached items (default: 15 minutes)
    /// </summary>
    public int DefaultCacheTTLMinutes { get; init; } = 15;

    /// <summary>
    /// Cache key prefix for legal documents
    /// </summary>
    public string LegalDocumentsKeyPrefix { get; init; } = "legal_documents";

    /// <summary>
    /// Cache TTL for legal documents in minutes (default: 1440 minutes / 24 hours)
    /// </summary>
    public int LegalDocumentsCacheTTLMinutes { get; init; } = 1440;

    /// <summary>
    /// Cache key prefix for cities
    /// </summary>
    public string CitiesKeyPrefix { get; init; } = "cities";

    /// <summary>
    /// Cache TTL for cities in minutes (default: 120 minutes / 2 hours)
    /// </summary>
    public int CitiesCacheTTLMinutes { get; init; } = 120;

    /// <summary>
    /// Cache key prefix for popular products
    /// </summary>
    public string PopularProductsKeyPrefix { get; init; } = "popular_products";

    /// <summary>
    /// Cache TTL for popular products in minutes (default: 30 minutes)
    /// </summary>
    public int PopularProductsCacheTTLMinutes { get; init; } = 30;
}

