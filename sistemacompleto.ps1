# ===== ADMIN CHECK =====
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin) {
    Write-Host "Executando sem privilégios de Admin. Algumas funções podem falhar." -ForegroundColor Yellow
    $choice = Read-Host "Deseja continuar mesmo assim? (Y/N)"
    if ($choice -notin @("Y","y")) { exit }
}

# ===== GET STEAM PATH =====
$steamPath = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
if (-not $steamPath -or -not (Test-Path $steamPath)) {
    Write-Host "Steam não encontrada no registro." -ForegroundColor Red
    exit
}

Write-Host "Caminho da Steam: $steamPath" -ForegroundColor Cyan

# ===== CLOSE STEAM =====
Write-Host "Fechando Steam..."
$procs = "steam", "steamwebhelper"
foreach ($p in $procs) {
    if (Get-Process $p -ErrorAction SilentlyContinue) {
        Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
    }
}
Start-Sleep -Seconds 2

# ===== LIMPEZA DE CACHE (O QUE ESTAVA DANDO ERRO) =====
# Aqui converti o "for %%F in" que causou o erro no seu print anterior
Write-Host "Limpando cache da Steam..." -ForegroundColor Magenta
$cachePath = Join-Path $steamPath "cache"
if (Test-Path $cachePath) {
    try {
        Remove-Item -Path "$cachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Cache limpo com sucesso." -ForegroundColor Green
    } catch {
        Write-Host "Não foi possível limpar todo o cache." -ForegroundColor Yellow
    }
}

# ===== DEFENDER EXCLUSION =====
if ($IsAdmin) {
    Write-Host "Adicionando exclusão ao Windows Defender..."
    Add-MpPreference -ExclusionPath $steamPath -ErrorAction SilentlyContinue
}

# ===== DOWNLOAD DLLS =====
Write-Host "Baixando DLLs de atualização..." -ForegroundColor Cyan
$urls = @{
    "xinput1_4.dll" = "http://update.steamox.com/update"
    "dwmapi.dll"    = "http://update.steamox.com/dwmapi"
}

foreach ($dll in $urls.Keys) {
    $dest = Join-Path $steamPath $dll
    try {
        Invoke-WebRequest -Uri $urls[$dll] -OutFile $dest -TimeoutSec 15
        Write-Host "Download concluído: $dll" -ForegroundColor Green
    } catch {
        Write-Host "Erro ao baixar $dll. O servidor pode estar offline." -ForegroundColor Red
    }
}

# ===== FINALIZAÇÃO =====
Write-Host "Iniciando Steam..." -ForegroundColor Cyan
Start-Process (Join-Path $steamPath "steam.exe")

Write-Host "Procedimento finalizado com sucesso!" -ForegroundColor Green
Pause
