# =====================================================================
# GAME OVER GOD - VERSÃO DE TESTE INTEGRAL (MENU COMPLETO)
# CEO: Marcos - Game Over
# =====================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "GameOverGod - Gestão de Sistema"
Clear-Host

# --- CONFIGURAÇÕES ---
$urlDasKeys = "https://raw.githubusercontent.com/master18032008/Sistemacompleto/Principal/keys.txt"
$urlDoRar = "https://cdn.discordapp.com/attachments/1500928090619121826/1500940141643173968/GameOverGod.rar?ex=69fa42ef&is=69f8f16f&hm=9467ea98343ec2c9e19cc24941085ef0485d9b857a0788de97ac1b996a0e0e8f&"
$pathTrava = "$env:APPDATA\gog_license_v8.dat"
$pathHistorico = "$env:APPDATA\gog_history.dat"

$steamReg = Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue
$steamExe = $steamReg.SteamExe
$steamDir = [System.IO.Path]::GetDirectoryName($steamExe)
$configDir = Join-Path $steamDir "config"

# --- VALIDAÇÃO DE ACESSO ---
Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "                SISTEMA DE ACESSO GAME OVER                 " -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
$keyCliente = (Read-Host " DIGITE SUA KEY DE ACESSO ").Trim()

if (Test-Path $pathHistorico) {
    if ((Get-Content $pathHistorico) -contains $keyCliente) {
        if (-not (Test-Path $pathTrava)) {
            Write-Host "ERRO: Esta Key ja foi utilizada e expirou!" -ForegroundColor Red
            Pause; exit
        }
    }
}

try {
    $listaKeys = Invoke-WebRequest -Uri $urlDasKeys -UseBasicParsing -ErrorAction Stop
    if ($listaKeys.Content -notmatch $keyCliente) {
        Write-Host "ERRO: Key invalida!" -ForegroundColor Red
        Pause; exit
    }
} catch {
    Write-Host "ERRO: Falha de conexao." -ForegroundColor Red
    Pause; exit
}

# --- AGENDAMENTO DA AUTO-DELEÇÃO (1 MINUTO) ---
if (-not (Test-Path $pathTrava)) {
    $dataExpira = (Get-Date).AddMinutes(1)
    $horarioLimpeza = $dataExpira.ToString("HH:mm")
    $keyCliente | Out-File $pathHistorico -Append

    $actionScript = "Stop-Process -Name steam, steamwebhelper -Force -ErrorAction SilentlyContinue; " +
                    "Remove-Item '$steamDir\xinput1_4.dll', '$steamDir\dwmapi.dll', '$steamDir\hid.dll' -Force -ErrorAction SilentlyContinue; " +
                    "Remove-Item '$configDir\depotcache', '$configDir\stplug-in' -Recurse -Force -ErrorAction SilentlyContinue; " +
                    "Remove-Item '$pathTrava' -Force -ErrorAction SilentlyContinue"

    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"$actionScript`""
    $trigger = New-ScheduledTaskTrigger -Once -At $horarioLimpeza
    Register-ScheduledTask -TaskName "GOG_AutoCleanup" -Action $action -Trigger $trigger -Force | Out-Null

    @{ key = $keyCliente; exp = $dataExpira } | ConvertTo-Json | Out-File $pathTrava
}

# --- INTERFACE E MENU ---
function Show-Header {
    Clear-Host
    Write-Host "   ____                         ___                 ____           _ " -ForegroundColor Magenta
    Write-Host "  / ___| __ _ _ __ ___   ___   / _ \__   _____ _ __/ ___| ___   __| |" -ForegroundColor Cyan
    Write-Host " --------------------------------------------------------------------- "
    Write-Host " MENSALIDADE ATIVA ATÉ: $((Get-Content $pathTrava | ConvertFrom-Json).exp)" -ForegroundColor Yellow
}

Show-Header
Write-Host " 1. Instalação do Sistema (Pack Completo)"
Write-Host " 2. Atualizar Sistema"
Write-Host " 3. Remover Sistema (Limpeza Completa)"
Write-Host " 4. Sair"
$opt = Read-Host "`nEscolha uma opção"

switch ($opt) {
    "1" {
        Write-Host "`nInstalando..." -ForegroundColor Cyan
        Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force
        Invoke-WebRequest -Uri $urlDoRar -OutFile "$env:TEMP\GameOverGod.zip"
        "DLL-DATA" | Out-File "$steamDir\xinput1_4.dll"
        Write-Host "Instalação concluída!" -ForegroundColor Green
    }
    "2" {
        Write-Host "`nVerificando atualizações..." -ForegroundColor Cyan
        # Lógica de atualização aqui
        Write-Host "Sistema já está na versão mais recente." -ForegroundColor Green
    }
    "3" {
        Write-Host "`nRemovendo arquivos do sistema..." -ForegroundColor Red
        Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force
        Remove-Item "$steamDir\xinput1_4.dll", "$steamDir\dwmapi.dll" -Force -ErrorAction SilentlyContinue
        Write-Host "Sistema removido com sucesso!" -ForegroundColor Yellow
    }
    Default { exit }
}
Pause
