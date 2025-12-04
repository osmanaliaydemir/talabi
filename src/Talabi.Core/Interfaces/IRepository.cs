using System.Linq.Expressions;
using Talabi.Core.Entities;

namespace Talabi.Core.Interfaces;

/// <summary>
/// Veri erişim işlemleri için generic repository interface'i
/// </summary>
/// <typeparam name="T">BaseEntity'den türeyen entity tipi</typeparam>
public interface IRepository<T> where T : BaseEntity
{
    /// <summary>
    /// ID'ye göre bir entity getirir
    /// </summary>
    /// <param name="id">Entity ID'si</param>
    /// <param name="cancellationToken">İptal token'ı</param>
    /// <returns>Bulunan entity veya null</returns>
    Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// Tüm entity'leri getirir
    /// </summary>
    /// <param name="cancellationToken">İptal token'ı</param>
    /// <returns>Entity koleksiyonu</returns>
    Task<IEnumerable<T>> GetAllAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Predicate ile eşleşen entity'leri bulur
    /// </summary>
    /// <param name="predicate">Filtreleme koşulu</param>
    /// <param name="cancellationToken">İptal token'ı</param>
    /// <returns>Eşleşen entity koleksiyonu</returns>
    Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default);

    /// <summary>
    /// Predicate ile eşleşen ilk entity'yi getirir veya null döner
    /// </summary>
    /// <param name="predicate">Filtreleme koşulu</param>
    /// <param name="cancellationToken">İptal token'ı</param>
    /// <returns>Bulunan entity veya null</returns>
    Task<T?> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default);

    /// <summary>
    /// Kompleks sorgular (include, join vb.) için queryable döner
    /// </summary>
    /// <returns>IQueryable instance</returns>
    IQueryable<T> Query();

    /// <summary>
    /// Yeni bir entity ekler
    /// </summary>
    /// <param name="entity">Eklenecek entity</param>
    /// <param name="cancellationToken">İptal token'ı</param>
    /// <returns>Eklenen entity</returns>
    Task<T> AddAsync(T entity, CancellationToken cancellationToken = default);

    /// <summary>
    /// Mevcut bir entity'yi günceller
    /// </summary>
    /// <param name="entity">Güncellenecek entity</param>
    void Update(T entity);

    /// <summary>
    /// Bir entity'yi siler
    /// </summary>
    /// <param name="entity">Silinecek entity</param>
    void Remove(T entity);

    /// <summary>
    /// Birden fazla entity'yi siler
    /// </summary>
    /// <param name="entities">Silinecek entity koleksiyonu</param>
    void RemoveRange(IEnumerable<T> entities);

    /// <summary>
    /// Predicate ile eşleşen entity sayısını döner (predicate null ise tüm entity'leri sayar)
    /// </summary>
    /// <param name="predicate">Filtreleme koşulu (opsiyonel)</param>
    /// <param name="cancellationToken">İptal token'ı</param>
    /// <returns>Entity sayısı</returns>
    Task<int> CountAsync(Expression<Func<T, bool>>? predicate = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// Predicate ile eşleşen herhangi bir entity olup olmadığını kontrol eder
    /// </summary>
    /// <param name="predicate">Filtreleme koşulu</param>
    /// <param name="cancellationToken">İptal token'ı</param>
    /// <returns>Eşleşme varsa true, yoksa false</returns>
    Task<bool> ExistsAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default);
}

