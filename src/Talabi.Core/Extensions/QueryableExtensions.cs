using System.Linq.Expressions;

namespace Talabi.Core.Extensions;

/// <summary>
/// IQueryable için extension metodlar - Query işlemleri için yardımcı metodlar
/// Not: Include ve ThenInclude metodları zaten EF Core'da mevcut, burada sadece ek yardımcı metodlar bulunur
/// </summary>
public static class QueryableExtensions
{

    /// <summary>
    /// Sayfalama için skip ve take uygular
    /// </summary>
    /// <typeparam name="T">Entity tipi</typeparam>
    /// <param name="source">Query source</param>
    /// <param name="page">Sayfa numarası (1'den başlar)</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    /// <returns>Sayfalanmış query</returns>
    public static IQueryable<T> Paginate<T>(this IQueryable<T> source, int page, int pageSize)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;

        return source.Skip((page - 1) * pageSize).Take(pageSize);
    }

    /// <summary>
    /// Query'yi belirtilen property'ye göre sıralar (ascending)
    /// </summary>
    /// <typeparam name="T">Entity tipi</typeparam>
    /// <typeparam name="TKey">Sıralama key tipi</typeparam>
    /// <param name="source">Query source</param>
    /// <param name="keySelector">Sıralama key selector</param>
    /// <returns>Sıralanmış query</returns>
    public static IOrderedQueryable<T> OrderByProperty<T, TKey>(
        this IQueryable<T> source,
        Expression<Func<T, TKey>> keySelector)
    {
        return source.OrderBy(keySelector);
    }

    /// <summary>
    /// Query'yi belirtilen property'ye göre ters sıralar (descending)
    /// </summary>
    /// <typeparam name="T">Entity tipi</typeparam>
    /// <typeparam name="TKey">Sıralama key tipi</typeparam>
    /// <param name="source">Query source</param>
    /// <param name="keySelector">Sıralama key selector</param>
    /// <returns>Sıralanmış query</returns>
    public static IOrderedQueryable<T> OrderByPropertyDescending<T, TKey>(
        this IQueryable<T> source,
        Expression<Func<T, TKey>> keySelector)
    {
        return source.OrderByDescending(keySelector);
    }

    /// <summary>
    /// String property için case-insensitive contains kontrolü yapar
    /// </summary>
    /// <typeparam name="T">Entity tipi</typeparam>
    /// <param name="source">Query source</param>
    /// <param name="propertySelector">String property selector</param>
    /// <param name="searchTerm">Arama terimi</param>
    /// <returns>Filtrelenmiş query</returns>
    public static IQueryable<T> WhereContainsIgnoreCase<T>(
        this IQueryable<T> source,
        Expression<Func<T, string?>> propertySelector,
        string searchTerm)
    {
        if (string.IsNullOrWhiteSpace(searchTerm))
            return source;

        // Expression.Invoke yerine doğrudan property access kullan
        var parameter = propertySelector.Parameters[0];
        var property = propertySelector.Body;
        
        // Null check ekle
        var nullCheck = Expression.NotEqual(property, Expression.Constant(null, typeof(string)));
        
        // ToLower ve Contains
        var toLowerMethod = typeof(string).GetMethod("ToLower", Type.EmptyTypes)!;
        var containsMethod = typeof(string).GetMethod("Contains", new[] { typeof(string) })!;
        
        var toLower = Expression.Call(property, toLowerMethod);
        var constant = Expression.Constant(searchTerm.ToLower());
        var contains = Expression.Call(toLower, containsMethod, constant);
        
        // Null check ve contains birleştir
        var condition = Expression.AndAlso(nullCheck, contains);
        var lambda = Expression.Lambda<Func<T, bool>>(condition, parameter);

        return source.Where(lambda);
    }

    /// <summary>
    /// Tarih aralığı filtresi uygular
    /// </summary>
    /// <typeparam name="T">Entity tipi</typeparam>
    /// <param name="source">Query source</param>
    /// <param name="datePropertySelector">Tarih property selector</param>
    /// <param name="startDate">Başlangıç tarihi (opsiyonel)</param>
    /// <param name="endDate">Bitiş tarihi (opsiyonel)</param>
    /// <returns>Filtrelenmiş query</returns>
    public static IQueryable<T> WhereDateRange<T>(
        this IQueryable<T> source,
        Expression<Func<T, DateTime?>> datePropertySelector,
        DateTime? startDate = null,
        DateTime? endDate = null)
    {
        if (startDate.HasValue)
        {
            var parameter = datePropertySelector.Parameters[0];
            var property = datePropertySelector.Body;
            var constant = Expression.Constant(startDate.Value.Date, typeof(DateTime?));
            var greaterThanOrEqual = Expression.GreaterThanOrEqual(property, constant);
            var lambda = Expression.Lambda<Func<T, bool>>(greaterThanOrEqual, parameter);
            source = source.Where(lambda);
        }

        if (endDate.HasValue)
        {
            var parameter = datePropertySelector.Parameters[0];
            var property = datePropertySelector.Body;
            var constant = Expression.Constant(endDate.Value.Date.AddDays(1), typeof(DateTime?));
            var lessThan = Expression.LessThan(property, constant);
            var lambda = Expression.Lambda<Func<T, bool>>(lessThan, parameter);
            source = source.Where(lambda);
        }

        return source;
    }

    /// <summary>
    /// Nullable property için null kontrolü yapar
    /// </summary>
    /// <typeparam name="T">Entity tipi</typeparam>
    /// <typeparam name="TProperty">Property tipi</typeparam>
    /// <param name="source">Query source</param>
    /// <param name="propertySelector">Property selector</param>
    /// <param name="includeNull">Null değerleri dahil et (true) veya hariç tut (false)</param>
    /// <returns>Filtrelenmiş query</returns>
    public static IQueryable<T> WhereNull<T, TProperty>(
        this IQueryable<T> source,
        Expression<Func<T, TProperty?>> propertySelector,
        bool includeNull = false) where TProperty : struct
    {
        var parameter = propertySelector.Parameters[0];
        var property = propertySelector.Body;
        var hasValue = Expression.Property(property, "HasValue");
        Expression condition = includeNull ? Expression.Not(hasValue) : (Expression)hasValue;
        var lambda = Expression.Lambda<Func<T, bool>>(condition, parameter);

        return source.Where(lambda);
    }
}

