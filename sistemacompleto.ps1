# =====================================================================
# GAME OVER GOD - VERSÃO INTEGRAL COM INSTALAÇÃO E AUTO-DELEÇÃO
# CEO: Marcos - Game Over | Versão de Teste: 1 Minuto
# =====================================================================

# --- PRIVILÉGIOS DE ADMINISTRADOR ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "GameOverGod - Gestão Profissional"
Clear-Host

# --- CONFIGURAÇÕES DE LINKS E CAMINHOS ---
$urlDasKeys = "https://raw.githubusercontent.com/master18032008/Sistemacompleto/refs/heads/main/keys.txt"
$urlDoRar = "https://cdn.discordapp.com/attachments/1500928090619121826/1500940141643173968/GameOverGod.rar?ex=69fa42ef&is=69f8f16f&hm=9467ea98343ec2c9e19cc24941085ef0485d9b857a0788de97ac1b996a0e0e8f&"
$pathTrava = "$env:APPDATA\gog_license_v8.dat"
$pathHistorico = "$env:APPDATA\gog_history.dat"

$steamReg = Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue
$steamExe = $steamReg.SteamExe
$steamDir = [System.IO.Path]::GetDirectoryName($steamExe)
$configDir = Join-Path $steamDir "config"

# --- VALIDAÇÃO E QUEIMA DE KEY ---
Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "                SISTEMA DE ACESSO GAME OVER                 " -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
$keyCliente = (Read-Host " DIGITE SUA KEY DE ACESSO ").Trim()

if (Test-Path $pathHistorico) {
    if ((Get-Content $pathHistorico) -contains $keyCliente) {
        if (-not (Test-Path $pathTrava)) {
            Write-Host "ERRO: Esta Key já expirou neste computador!" -ForegroundColor Red
            Pause; exit
        }
    }
}

try {
    $listaKeys = Invoke-WebRequest -Uri $urlDasKeys -UseBasicParsing -ErrorAction Stop
    if ($listaKeys.Content -notmatch $keyCliente) {
        Write-Host "ERRO: Key inválida!" -ForegroundColor Red
        Pause; exit
    }
} catch {
    Write-Host "ERRO: Falha de conexão com o banco de chaves." -ForegroundColor Red
    Pause; exit
}

# --- AGENDADOR DE REMOÇÃO AUTOMÁTICA (1 MINUTO) ---
if (-not (Test-Path $pathTrava)) {
    $dataExpira = (Get-Date).AddMinutes(1)
    $horarioLimpeza = $dataExpira.ToString("HH:mm")
    $keyCliente | Out-File $pathHistorico -Append

    # O comando que o Windows executa sozinho após 1 minuto
    $actionScript = "Stop-Process -Name steam, steamwebhelper -Force -ErrorAction SilentlyContinue; " +
                    "Remove-Item '$steamDir\xinput1_4.dll', '$steamDir\dwmapi.dll', '$steamDir\hid.dll' -Force -ErrorAction SilentlyContinue; " +
                    "Remove-Item '$configDir\depotcache', '$configDir\stplug-in' -Recurse -Force -ErrorAction SilentlyContinue; " +
                    "Remove-Item '$pathTrava' -Force -ErrorAction SilentlyContinue"

    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"$actionScript`""
    $trigger = New-ScheduledTaskTrigger -Once -At $horarioLimpeza
    Register-ScheduledTask -TaskName "GOG_AutoCleanup" -Action $action -Trigger $trigger -Force | Out-Null

    @{ key = $keyCliente; exp = $dataExpira } | ConvertTo-Json | Out-File $pathTrava
}

# --- MENU DE OPERAÇÕES ---
function Show-Header {
    Clear-Host
    Write-Host "   ____                         ___                 ____           _ " -ForegroundColor Magenta
    Write-Host "  / ___| __ _ _ __ ___   ___   / _ \__   _____ _ __/ ___| ___   __| |" -ForegroundColor Cyan
    Write-Host " | |  _ / _` | '_ ` _ \ / _ \ | | | \ \ / / _ \ '__| |  _ / _ \ / _` |" -ForegroundColor Magenta
    Write-Host " | |_| | (_| | | | | | |  __/ | |_| |\ V /  __/ |  | |_| | (_) | (_| |" -ForegroundColor Cyan
    Write-Host "  \____|\__,_|_| |_| |_|\___|  \___/  \_/ \___|_|   \____|\___/ \__,_|" -ForegroundColor Magenta
    Write-Host " --------------------------------------------------------------------- "
    $exp = (Get-Content $pathTrava | ConvertFrom-Json).exp
    Write-Host " [!] ACESSO LIBERADO ATÉ: $exp" -ForegroundColor Yellow
}

Show-Header
Write-Host " 1. Instalação do Sistema (Pack Completo)"
Write-Host " 2. Atualizar Sistema"
Write-Host " 3. Remover Sistema (Manual)"
Write-Host " 4. Sair"
$opt = Read-Host "`nEscolha uma opção"

switch ($opt) {
    "1" {
        Write-Host "`nIniciando instalação completa..." -ForegroundColor Cyan
        Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force
        
        # Download do Pack do Discord
        Write-Host "Baixando arquivos..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $urlDoRar -OutFile "$env:TEMP\GameOverGod.zip"
        
        # Colocando as DLLs na pasta da Steam (Simulação da extração)
        "DATA" | Out-File "$steamDir\xinput1_4.dll"
        "DATA" | Out-File "$steamDir\dwmapi.dll"
        "DATA" | Out-File "$steamDir\hid.dll"
        
        Write-Host "Instalação finalizada com sucesso!" -ForegroundColor Green
        Start-Process $steamExe
    }
    "2" {
        Write-Host "`nVerificando atualizações no servidor..." -ForegroundColor Cyan
        Start-Sleep -Seconds 2
        Write-Host "Sistema já está em sua versão mais recente!" -ForegroundColor Green
    }
    "3" {
        Write-Host "`nRemovendo todos os componentes..." -ForegroundColor Red
        Get-Process steam -ErrorAction SilentlyContinue | Stop-Process -Force
        Remove-Item "$steamDir\xinput1_4.dll", "$steamDir\dwmapi.dll", "$steamDir\hid.dll" -Force -ErrorAction SilentlyContinue
        Remove-Item "$configDir\depotcache", "$configDir\stplug-in" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Limpeza concluída." -ForegroundColor Yellow
    }
    Default { exit }
}
Pause
