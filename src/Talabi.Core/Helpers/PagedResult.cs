namespace Talabi.Core.Helpers;

/// <summary>
/// Sayfalanmış sonuç için helper class
/// </summary>
/// <typeparam name="T">Sonuç tipi</typeparam>
public class PagedResult<T>
{
    /// <summary>
    /// Sonuç listesi
    /// </summary>
    public List<T> Items { get; set; } = new();

    /// <summary>
    /// Toplam kayıt sayısı
    /// </summary>
    public int TotalCount { get; set; }

    /// <summary>
    /// Sayfa numarası (1'den başlar)
    /// </summary>
    public int Page { get; set; }

    /// <summary>
    /// Sayfa boyutu
    /// </summary>
    public int PageSize { get; set; }

    /// <summary>
    /// Toplam sayfa sayısı
    /// </summary>
    public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);

    /// <summary>
    /// Önceki sayfa var mı?
    /// </summary>
    public bool HasPreviousPage => Page > 1;

    /// <summary>
    /// Sonraki sayfa var mı?
    /// </summary>
    public bool HasNextPage => Page < TotalPages;

    /// <summary>
    /// PagedResult constructor
    /// </summary>
    public PagedResult()
    {
    }

    /// <summary>
    /// PagedResult constructor
    /// </summary>
    /// <param name="items">Sonuç listesi</param>
    /// <param name="totalCount">Toplam kayıt sayısı</param>
    /// <param name="page">Sayfa numarası</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    public PagedResult(List<T> items, int totalCount, int page, int pageSize)
    {
        Items = items;
        TotalCount = totalCount;
        Page = page;
        PageSize = pageSize;
    }
}

