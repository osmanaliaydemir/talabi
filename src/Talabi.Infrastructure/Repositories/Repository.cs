using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;

namespace Talabi.Infrastructure.Repositories;

/// <summary>
/// Generic repository implementation - Tüm entity'ler için ortak CRUD işlemlerini sağlar
/// </summary>
/// <typeparam name="T">BaseEntity'den türeyen entity tipi</typeparam>
public class Repository<T> : IRepository<T> where T : BaseEntity
{
    protected readonly TalabiDbContext _context;
    protected readonly DbSet<T> _dbSet;

    /// <summary>
    /// Repository constructor
    /// </summary>
    /// <param name="context">DbContext instance</param>
    public Repository(TalabiDbContext context)
    {
        _context = context ?? throw new ArgumentNullException(nameof(context));
        _dbSet = _context.Set<T>();
    }

    /// <summary>
    /// ID'ye göre bir entity getirir
    /// </summary>
    public virtual async Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _dbSet.FindAsync(new object[] { id }, cancellationToken);
    }

    /// <summary>
    /// Tüm entity'leri getirir
    /// </summary>
    public virtual async Task<IEnumerable<T>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _dbSet.ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Predicate ile eşleşen entity'leri bulur
    /// </summary>
    public virtual async Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default)
    {
        return await _dbSet.Where(predicate).ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Predicate ile eşleşen ilk entity'yi getirir veya null döner
    /// </summary>
    public virtual async Task<T?> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default)
    {
        return await _dbSet.FirstOrDefaultAsync(predicate, cancellationToken);
    }

    /// <summary>
    /// Kompleks sorgular (include, join vb.) için queryable döner
    /// </summary>
    public virtual IQueryable<T> Query()
    {
        return _dbSet;
    }

    /// <summary>
    /// Yeni bir entity ekler
    /// </summary>
    public virtual async Task<T> AddAsync(T entity, CancellationToken cancellationToken = default)
    {
        if (entity == null)
            throw new ArgumentNullException(nameof(entity));

        await _dbSet.AddAsync(entity, cancellationToken);
        return entity;
    }

    /// <summary>
    /// Birden fazla entity ekler
    /// </summary>
    public virtual async Task AddRangeAsync(IEnumerable<T> entities, CancellationToken cancellationToken = default)
    {
        if (entities == null)
            throw new ArgumentNullException(nameof(entities));

        await _dbSet.AddRangeAsync(entities, cancellationToken);
    }

    /// <summary>
    /// Mevcut bir entity'yi günceller
    /// </summary>
    public virtual void Update(T entity)
    {
        if (entity == null)
            throw new ArgumentNullException(nameof(entity));

        _dbSet.Update(entity);
    }

    /// <summary>
    /// Bir entity'yi siler
    /// </summary>
    public virtual void Remove(T entity)
    {
        if (entity == null)
            throw new ArgumentNullException(nameof(entity));

        _dbSet.Remove(entity);
    }

    /// <summary>
    /// Birden fazla entity'yi siler
    /// </summary>
    public virtual void RemoveRange(IEnumerable<T> entities)
    {
        if (entities == null)
            throw new ArgumentNullException(nameof(entities));

        _dbSet.RemoveRange(entities);
    }

    /// <summary>
    /// Predicate ile eşleşen entity sayısını döner (predicate null ise tüm entity'leri sayar)
    /// </summary>
    public virtual async Task<int> CountAsync(Expression<Func<T, bool>>? predicate = null, CancellationToken cancellationToken = default)
    {
        if (predicate == null)
            return await _dbSet.CountAsync(cancellationToken);

        return await _dbSet.CountAsync(predicate, cancellationToken);
    }

    /// <summary>
    /// Predicate ile eşleşen herhangi bir entity olup olmadığını kontrol eder
    /// </summary>
    public virtual async Task<bool> ExistsAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default)
    {
        if (predicate == null)
            throw new ArgumentNullException(nameof(predicate));

        return await _dbSet.AnyAsync(predicate, cancellationToken);
    }
    /// <summary>
    /// Predicate ile eşleşen entity'leri doğrudan veritabanından siler (Bulk Delete)
    /// </summary>
    public virtual async Task<int> ExecuteDeleteAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default)
    {
        if (predicate == null)
            throw new ArgumentNullException(nameof(predicate));

        return await _dbSet.Where(predicate).ExecuteDeleteAsync(cancellationToken);
    }
}

