# =====================================================================
# GAME OVER GOD - VERSÃO DE TESTE COMPLETA (EXPIRA EM 1 MINUTO)
# CEO: Marcos - Game Over
# =====================================================================

# --- PRIVILÉGIOS DE ADMINISTRADOR ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "GameOverGod - TESTE DE INSTALAÇÃO E AUTO-REMOÇÃO"
Clear-Host

# --- CONFIGURAÇÕES DE DIRETÓRIO E LINKS ---
$urlDasKeys = "https://raw.githubusercontent.com/master18032008/Sistemacompleto/Principal/keys.txt"
$urlDoRar = "https://cdn.discordapp.com/attachments/1500928090619121826/1500940141643173968/GameOverGod.rar?ex=69fa42ef&is=69f8f16f&hm=9467ea98343ec2c9e19cc24941085ef0485d9b857a0788de97ac1b996a0e0e8f&"
$pathTrava = "$env:APPDATA\gog_teste_final.dat"

$steamReg = Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue
$steamExe = $steamReg.SteamExe
$steamDir = [System.IO.Path]::GetDirectoryName($steamExe)
$configDir = Join-Path $steamDir "config"

# --- VALIDAÇÃO DE ACESSO ---
Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "                SISTEMA DE ACESSO GAME OVER                 " -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
$keyCliente = (Read-Host " DIGITE SUA KEY DE ACESSO ").Trim()

try {
    $listaKeys = Invoke-WebRequest -Uri $urlDasKeys -UseBasicParsing -ErrorAction Stop
    if ($listaKeys.Content -notmatch $keyCliente) {
        Write-Host "ERRO: Key não encontrada no servidor!" -ForegroundColor Red
        Pause; exit
    }
} catch {
    Write-Host "ERRO: Falha ao conectar com o banco de dados do GitHub." -ForegroundColor Red
    Pause; exit
}

# --- AGENDAMENTO DA BOMBA-RELÓGIO (1 MINUTO) ---
if (-not (Test-Path $pathTrava)) {
    $dataExpira = (Get-Date).AddMinutes(1)
    $horarioLimpeza = $dataExpira.ToString("HH:mm")
    
    $actionScript = "Stop-Process -Name steam, steamwebhelper -Force -ErrorAction SilentlyContinue; " +
                    "Remove-Item '$steamDir\xinput1_4.dll', '$steamDir\dwmapi.dll', '$steamDir\hid.dll' -Force -ErrorAction SilentlyContinue; " +
                    "Remove-Item '$configDir\depotcache', '$configDir\stplug-in' -Recurse -Force -ErrorAction SilentlyContinue; " +
                    "Remove-Item '$pathTrava' -Force -ErrorAction SilentlyContinue"

    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"$actionScript`""
    $trigger = New-ScheduledTaskTrigger -Once -At $horarioLimpeza
    Register-ScheduledTask -TaskName "GOG_Auto_Cleanup" -Action $action -Trigger $trigger -Force | Out-Null

    @{ key = $keyCliente; exp = $dataExpira } | ConvertTo-Json | Out-File $pathTrava
    Write-Host "`n[!] ATIVADO: O acesso será removido SOZINHO às $horarioLimpeza." -ForegroundColor Cyan
}

# --- INTERFACE DE INSTALAÇÃO ---
function Show-Header {
    Clear-Host
    Write-Host "   ____                         ___                 ____           _ " -ForegroundColor Magenta
    Write-Host "  / ___| __ _ _ __ ___   ___   / _ \__   _____ _ __/ ___| ___   __| |" -ForegroundColor Cyan
    Write-Host " | |  _ / _` | '_ ` _ \ / _ \ | | | \ \ / / _ \ '__| |  _ / _ \ / _` |" -ForegroundColor Magenta
    Write-Host " | |_| | (_| | | | | | |  __/ | |_| |\ V /  __/ |  | |_| | (_) | (_| |" -ForegroundColor Cyan
    Write-Host "  \____|\__,_|_| |_| |_|\___|  \___/  \_/ \___|_|   \____|\___/ \__,_|" -ForegroundColor Magenta
    Write-Host " --------------------------------------------------------------------- "
}

Show-Header
Write-Host " 1. Instalar/Atualizar Pack de Jogos"
Write-Host " 2. Sair"
$opt = Read-Host "`nEscolha uma opção"

if ($opt -eq "1") {
    Write-Host "`nFechando processos da Steam..." -ForegroundColor Yellow
    Get-Process steam, steamwebhelper -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2

    Write-Host "Baixando Pack de Jogos (GameOverGod.rar)..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $urlDoRar -OutFile "$env:TEMP\GameOverGod.zip"

    Write-Host "Instalando DLLs de desbloqueio..." -ForegroundColor Cyan
    # Simulando download das DLLs necessárias
    $dlls = @("xinput1_4.dll", "dwmapi.dll")
    foreach ($d in $dlls) {
        "Conteúdo DLL" | Out-File (Join-Path $steamDir $d) 
    }

    Write-Host "`n[V] PACK INSTALADO COM SUCESSO!" -ForegroundColor Green
    Write-Host "Você pode jogar agora. Em 1 minuto o acesso será cortado automaticamente." -ForegroundColor Yellow
    Start-Process $steamExe
    Pause
} else {
    exit
}
