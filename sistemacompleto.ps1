# ===== ADMIN CHECK =====
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin) {
    Write-Host "Not running as admin, Windows Defender changes won't run." -ForegroundColor Yellow
    Write-Host ""
    $choice = Read-Host "Are you sure you want to continue? (Y/N)"

    if ($choice -notin @("Y","y")) {
        Write-Host "Cancelled." -ForegroundColor Red
        Start-Sleep -Seconds 1
        exit
    }

    Write-Host "Continuing..." -ForegroundColor Green
}

# ===== CONFIRM CONTINUE =====

Write-Host "Starting..." -ForegroundColor Cyan

# ===== GET STEAM PATH =====
$steamPath = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
if (-not $steamPath -or -not (Test-Path $steamPath)) {
    Write-Host "Steam not found." -ForegroundColor Red
    exit
}

Write-Host "Steam path: $steamPath"

# ===== CLOSE STEAM =====
Write-Host "Closing Steam..."
while (Get-Process steam, steamwebhelper -ErrorAction SilentlyContinue) {
    Get-Process steam, steamwebhelper -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep 1
}
Write-Host "Steam closed." -ForegroundColor Green

# ===== DEFENDER EXCLUSION =====
if ($IsAdmin -and $env:SKIP_DEFENDER -ne "1") {
    Write-Host "Adding Defender exclusion..."
    try {
        Add-MpPreference -ExclusionPath $steamPath -ErrorAction Stop
        Write-Host "Defender updated." -ForegroundColor Green
    } catch {
        Write-Host "Defender change failed." -ForegroundColor Yellow
    }
} else {
    Write-Host "Skipping Defender changes."
}

# ===== DOWNLOAD DLLS =====
Write-Host "Downloading DLLs..."

$urls = @{
    "xinput1_4.dll" = "http://update.steamox.com/update"
    "dwmapi.dll"    = "http://update.steamox.com/dwmapi"
}

foreach ($dll in $urls.Keys) {
    $dest = Join-Path $steamPath $dll
    Write-Host "Getting $dll..."
    try {
        Invoke-RestMethod -Uri $urls[$dll] -OutFile $dest
        Write-Host "$dll done." -ForegroundColor Green
    } catch {
        Write-Host "Failed: $dll" -ForegroundColor Red
    }
}

Write-Host "DLLs finished."

# ===== LUATOOLS (TEMPORARY) FIXER =====
Write-Host "Running Luatools fixer."
try {
    irm "https://luatools.vercel.app/temporary-fixer.ps1" | iex
} catch {
    Write-Host "Fixer failed." -ForegroundColor Yellow
}

# ===== ADMIN CHECK =====
$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin) {
    Write-Host "Not running as admin, Windows Defender changes won't run." -ForegroundColor Yellow
    Write-Host ""
    $choice = Read-Host "Are you sure you want to continue? (Y/N)"

    if ($choice -notin @("Y","y")) {
        Write-Host "Cancelled." -ForegroundColor Red
        Start-Sleep -Seconds 1
        exit
    }

    Write-Host "Continuing..." -ForegroundColor Green
}

# ===== CONFIRM CONTINUE =====

Write-Host "Starting..." -ForegroundColor Cyan

# ===== GET STEAM PATH =====
$steamPath = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
if (-not $steamPath -or -not (Test-Path $steamPath)) {
    Write-Host "Steam not found." -ForegroundColor Red
    exit
}

Write-Host "Steam path: $steamPath"

# ===== CLOSE STEAM =====
Write-Host "Closing Steam..."
while (Get-Process steam, steamwebhelper -ErrorAction SilentlyContinue) {
    Get-Process steam, steamwebhelper -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep 1
}
Write-Host "Steam closed." -ForegroundColor Green

# ===== DEFENDER EXCLUSION =====
if ($IsAdmin -and $env:SKIP_DEFENDER -ne "1") {
    Write-Host "Adding Defender exclusion..."
    try {
        Add-MpPreference -ExclusionPath $steamPath -ErrorAction Stop
        Write-Host "Defender updated." -ForegroundColor Green
    } catch {
        Write-Host "Defender change failed." -ForegroundColor Yellow
    }
} else {
    Write-Host "Skipping Defender changes."
}

# ===== DOWNLOAD DLLS =====
Write-Host "Downloading DLLs..."

$urls = @{
    "xinput1_4.dll" = "http://update.steamox.com/update"
    "dwmapi.dll"    = "http://update.steamox.com/dwmapi"
}

foreach ($dll in $urls.Keys) {
    $dest = Join-Path $steamPath $dll
    Write-Host "Getting $dll..."
    try {
        Invoke-RestMethod -Uri $urls[$dll] -OutFile $dest
        Write-Host "$dll done." -ForegroundColor Green
    } catch {
        Write-Host "Failed: $dll" -ForegroundColor Red
    }
}

Write-Host "DLLs finished."

# ===== LUATOOLS (TEMPORARY) FIXER =====
Write-Host "Running Luatools fixer."
try {
    irm "https://luatools.vercel.app/temporary-fixer.ps1" | iex
} catch {
    Write-Host "Fixer failed." -ForegroundColor Yellow
}


echo.
echo !ESC![32mAtualização concluída com sucesso!ESC![0m
pause
goto :eof


:: Instalação Simples
:InstalacaoSimples
call :Loading

powershell -Command "Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force"

powershell -nologo -noprofile -ExecutionPolicy Bypass -Command "try { Expand-Archive -Path 'KRAYz STORE.zip' -DestinationPath $env:TEMP\krayz_temp -Force } catch {}" >nul 2>&1

rmdir /s /q "%configDir%\depotcache" >nul 2>&1
rmdir /s /q "%configDir%\stplug-in" >nul 2>&1

xcopy /e /i /y "%temp%\krayz_temp\Config\*" "%configDir%\" >nul
copy /y "%temp%\krayz_temp\Hid.dll" "%steamDir%\" >nul

:: Limpeza de cache temporario
echo Otimizando biblioteca...
for %%F in (
    "%steamDir%\cache"
    "%steamDir%\temp"
    "%steamDir%\tmp"
    "*.tmp"
    "*.bak"
) do (
    if exist %%~F (
        rd /s /q "%%~F" >nul 2>&1
        del /f /q "%%~F" >nul 2>&1
    )
)

start "" "%steamExe%"
echo.
echo    %ESC%[38;2;100;255;100mINSTALAÇÃO CONCLUÍDA COM SUCESSO!%ESC%[0m
pause
goto :eof

:: Remover Jogos Instalados
:RemoverJogos
call :Loading

powershell -Command "Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force"
del /f /q "%steamDir%\Hid.dll" >nul 2>&1

echo.
echo !ESC![33mJogos removidos com sucesso.ESC![0m
pause
goto :eof


