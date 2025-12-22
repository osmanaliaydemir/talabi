using Microsoft.EntityFrameworkCore;
using Talabi.Core.Entities;
using Talabi.Core.Interfaces;
using Talabi.Infrastructure.Data;

namespace Talabi.Infrastructure.Services;

public class SystemSettingsService : ISystemSettingsService
{
    private readonly TalabiDbContext _context;

    public SystemSettingsService(TalabiDbContext context)
    {
        _context = context;
    }

    public async Task<string?> GetSettingAsync(string key, CancellationToken ct = default)
    {
        var setting = await _context.SystemSettings
            .FirstOrDefaultAsync(s => s.Key == key, ct);
        return setting?.Value;
    }

    public async Task<Dictionary<string, string>> GetAllSettingsAsync(CancellationToken ct = default)
    {
        return await _context.SystemSettings
            .ToDictionaryAsync(s => s.Key, s => s.Value, ct);
    }

    public async Task<List<SystemSetting>> GetSettingsListAsync(CancellationToken ct = default)
    {
        return await _context.SystemSettings
            .OrderBy(s => s.Group)
            .ThenBy(s => s.Key)
            .ToListAsync(ct);
    }

    public async Task UpdateSettingAsync(string key, string value, CancellationToken ct = default)
    {
        var setting = await _context.SystemSettings
            .FirstOrDefaultAsync(s => s.Key == key, ct);

        if (setting == null)
        {
            setting = new SystemSetting
            {
                Key = key,
                Value = value
            };
            await _context.SystemSettings.AddAsync(setting, ct);
        }
        else
        {
            setting.Value = value;
        }

        await _context.SaveChangesAsync(ct);
    }
    public async Task<SystemSetting> SaveSettingAsync(SystemSetting setting, CancellationToken ct = default)
    {
        if (setting.Id == Guid.Empty)
        {
            await _context.SystemSettings.AddAsync(setting, ct);
        }
        else
        {
            var existing = await _context.SystemSettings.FindAsync(new object[] { setting.Id }, ct);
            if (existing != null)
            {
                existing.Key = setting.Key;
                existing.Value = setting.Value;
                existing.Group = setting.Group;
                existing.Description = setting.Description;
                _context.Entry(existing).State = EntityState.Modified;
            }
        }

        await _context.SaveChangesAsync(ct);
        return setting;
    }

    public async Task DeleteSettingAsync(Guid id, CancellationToken ct = default)
    {
        var setting = await _context.SystemSettings.FindAsync(new object[] { id }, ct);
        if (setting != null)
        {
            _context.SystemSettings.Remove(setting);
            await _context.SaveChangesAsync(ct);
        }
    }
}
