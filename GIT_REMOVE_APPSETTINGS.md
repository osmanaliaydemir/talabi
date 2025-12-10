# Git'ten appsettings.json Kaldırma - Alternatif Yöntemler

Git komutu PowerShell'de tanınmıyorsa, aşağıdaki yöntemlerden birini kullanabilirsiniz:

## Yöntem 1: Git Bash Kullan (Önerilen)

1. Git Bash'i açın (Windows'ta Git yüklüyse genellikle sağ tık menüsünde "Git Bash Here" seçeneği vardır)
2. Proje dizinine gidin:
   ```bash
   cd /c/Users/osmanali.aydemir/Desktop/projects/talabi
   ```
3. Komutu çalıştırın:
   ```bash
   git rm --cached src/Talabi.Api/appsettings.json
   git commit -m "Remove appsettings.json from git tracking"
   ```

## Yöntem 2: Visual Studio'dan

1. Visual Studio'da projeyi açın
2. **Team Explorer** veya **Git Changes** penceresini açın
3. `src/Talabi.Api/appsettings.json` dosyasını bulun
4. Sağ tıklayın → **Exclude from Project** veya **Remove from Source Control**
5. Değişiklikleri commit edin

## Yöntem 3: VS Code'dan

1. VS Code'da projeyi açın
2. **Source Control** panelini açın (Ctrl+Shift+G)
3. `src/Talabi.Api/appsettings.json` dosyasını bulun
4. Sağ tıklayın → **Stage for Removal** veya **Discard Changes**
5. Commit edin

## Yöntem 4: Git'in Tam Yolunu Kullan

Git yüklüyse ama PATH'te değilse, tam yolunu kullanabilirsiniz:

```powershell
# Git'in yaygın yükleme konumları:
& "C:\Program Files\Git\bin\git.exe" rm --cached src/Talabi.Api/appsettings.json
& "C:\Program Files (x86)\Git\bin\git.exe" rm --cached src/Talabi.Api/appsettings.json
& "$env:LOCALAPPDATA\Programs\Git\bin\git.exe" rm --cached src/Talabi.Api/appsettings.json
```

## Yöntem 5: Git Yükleme Kontrolü

Git'in yüklü olup olmadığını kontrol edin:

```powershell
# Git'in yaygın konumlarını kontrol et
Test-Path "C:\Program Files\Git\bin\git.exe"
Test-Path "C:\Program Files (x86)\Git\bin\git.exe"
Test-Path "$env:LOCALAPPDATA\Programs\Git\bin\git.exe"
Test-Path "$env:ProgramFiles\Git\bin\git.exe"
```

Eğer hiçbiri `True` dönmüyorsa, Git yüklü değildir. [Git'i indirip yükleyin](https://git-scm.com/download/win).

## Yöntem 6: Manuel Olarak .gitignore Kontrolü

Eğer git kullanamıyorsanız, en azından `.gitignore` dosyasının doğru yapılandırıldığından emin olun:

1. `.gitignore` dosyasını açın
2. Şu satırın olduğundan emin olun:
   ```
   **/appsettings.json
   ```

Bu sayede gelecekteki commit'lerde dosya takip edilmeyecektir.

## Önemli Not

Eğer `appsettings.json` dosyası daha önce commit edildiyse ve git history'de varsa, sadece `git rm --cached` yeterli olmayabilir. Git history'den tamamen kaldırmak için:

```bash
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch src/Talabi.Api/appsettings.json" --prune-empty --tag-name-filter cat -- --all
```

**DİKKAT:** Bu komut git history'yi değiştirir. Eğer repository paylaşılıyorsa, tüm takım üyelerinin repository'yi yeniden clone etmesi gerekebilir.

## Sonraki Adımlar

1. `appsettings.json` git tracking'den kaldırıldıktan sonra
2. User Secrets kullanarak hassas bilgileri yapılandırın (detaylar için `src/Talabi.Api/SECURITY_SETUP.md`)
3. Production'da Environment Variables kullanın

