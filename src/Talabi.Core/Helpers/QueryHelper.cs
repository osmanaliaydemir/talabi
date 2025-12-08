using Microsoft.EntityFrameworkCore;
using System.Linq.Expressions;

namespace Talabi.Core.Helpers;

/// <summary>
/// Query işlemleri için yardımcı metodlar
/// </summary>
public static class QueryHelper
{
    /// <summary>
    /// Query'yi sayfalar ve sonucu döner
    /// </summary>
    /// <typeparam name="T">Entity tipi</typeparam>
    /// <param name="query">Query source</param>
    /// <param name="page">Sayfa numarası (1'den başlar)</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    /// <param name="cancellationToken">İptal token'ı</param>
    /// <returns>Sayfalanmış sonuç</returns>
    public static async Task<PagedResult<T>> ToPagedResultAsync<T>(this IQueryable<T> query, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;

        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<T>(items, totalCount, page, pageSize);
    }

    /// <summary>
    /// Query'yi sayfalar ve sonucu döner (DTO mapping ile)
    /// </summary>
    /// <typeparam name="TEntity">Entity tipi</typeparam>
    /// <typeparam name="TDto">DTO tipi</typeparam>
    /// <param name="query">Query source</param>
    /// <param name="mapper">Entity'den DTO'ya mapping fonksiyonu</param>
    /// <param name="page">Sayfa numarası (1'den başlar)</param>
    /// <param name="pageSize">Sayfa boyutu</param>
    /// <param name="cancellationToken">İptal token'ı</param>
    /// <returns>Sayfalanmış sonuç</returns>
    public static async Task<PagedResult<TDto>> ToPagedResultAsync<TEntity, TDto>(this IQueryable<TEntity> query,
        Expression<Func<TEntity, TDto>> mapper, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;

        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(mapper)
            .ToListAsync(cancellationToken);

        return new PagedResult<TDto>(items, totalCount, page, pageSize);
    }

    /// <summary>
    /// Query'yi belirtilen property'ye göre dinamik olarak sıralar
    /// </summary>
    /// <typeparam name="T">Entity tipi</typeparam>
    /// <param name="query">Query source</param>
    /// <param name="propertyName">Sıralama property adı</param>
    /// <param name="ascending">Artandan azalana (true) veya azalandan artana (false)</param>
    /// <returns>Sıralanmış query</returns>
    public static IOrderedQueryable<T> OrderByDynamic<T>(this IQueryable<T> query, string propertyName, bool ascending = true)
    {
        var parameter = Expression.Parameter(typeof(T), "x");
        var property = Expression.Property(parameter, propertyName);
        var lambda = Expression.Lambda(property, parameter);

        var methodName = ascending ? "OrderBy" : "OrderByDescending";
        var resultExpression = Expression.Call(
            typeof(Queryable),
            methodName,
            new[] { typeof(T), property.Type },
            query.Expression,
            Expression.Quote(lambda));

        return (IOrderedQueryable<T>)query.Provider.CreateQuery<T>(resultExpression);
    }

    /// <summary>
    /// Query'yi belirtilen property'ye göre dinamik olarak sıralar (ThenBy için)
    /// </summary>
    /// <typeparam name="T">Entity tipi</typeparam>
    /// <param name="query">Ordered query source</param>
    /// <param name="propertyName">Sıralama property adı</param>
    /// <param name="ascending">Artandan azalana (true) veya azalandan artana (false)</param>
    /// <returns>Sıralanmış query</returns>
    public static IOrderedQueryable<T> ThenByDynamic<T>(this IOrderedQueryable<T> query, string propertyName, bool ascending = true)
    {
        var parameter = Expression.Parameter(typeof(T), "x");
        var property = Expression.Property(parameter, propertyName);
        var lambda = Expression.Lambda(property, parameter);

        var methodName = ascending ? "ThenBy" : "ThenByDescending";
        var resultExpression = Expression.Call(
            typeof(Queryable),
            methodName,
            new[] { typeof(T), property.Type },
            query.Expression,
            Expression.Quote(lambda));

        return (IOrderedQueryable<T>)query.Provider.CreateQuery<T>(resultExpression);
    }
}

