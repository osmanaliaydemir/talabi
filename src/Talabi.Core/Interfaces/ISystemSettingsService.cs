using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Talabi.Core.Entities;

namespace Talabi.Core.Interfaces;

public interface ISystemSettingsService
{
    Task<string?> GetSettingAsync(string key, CancellationToken ct = default);
    Task<Dictionary<string, string>> GetAllSettingsAsync(CancellationToken ct = default);
    Task UpdateSettingAsync(string key, string value, CancellationToken ct = default);
    Task<SystemSetting> SaveSettingAsync(SystemSetting setting, CancellationToken ct = default);
    Task DeleteSettingAsync(Guid id, CancellationToken ct = default);
    Task<List<SystemSetting>> GetSettingsListAsync(CancellationToken ct = default);
}
