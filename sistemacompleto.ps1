# =====================================================================
# GAME OVER GOD - TESTE DE AUTO-DELEÇÃO INDEPENDENTE (1 MINUTO)
# CEO: Marcos - Game Over
# =====================================================================

# --- ELEVAÇÃO DE PRIVILÉGIOS (ADMIN) ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "GameOverGod - TESTE DE REMOÇÃO EM 1 MINUTO"
Clear-Host

# --- CONFIGURAÇÃO DO SERVIDOR ---
$urlDasKeys = "https://raw.githubusercontent.com/master18032008/Sistemacompleto/refs/heads/main/keys.txt"
$pathTrava = "$env:APPDATA\gog_teste_v7.dat"

# --- LOGIN E VALIDAÇÃO ---
Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
Write-Host "                SISTEMA DE ACESSO GAME OVER                 " -ForegroundColor Cyan
Write-Host "------------------------------------------------------------" -ForegroundColor Magenta
$keyCliente = (Read-Host " DIGITE UMA KEY PARA TESTE ").Trim()

try {
    $listaKeys = iwr -useb $urlDasKeys -ErrorAction Stop
    if ($listaKeys -notmatch $keyCliente) {
        Write-Host "ERRO: Key inválida ou não encontrada!" -ForegroundColor Red
        Pause; exit
    }
} catch {
    Write-Host "ERRO: Falha ao conectar com o servidor." -ForegroundColor Red
    Pause; exit
}

# --- LÓGICA DE AUTO-DELEÇÃO EM 1 MINUTO ---
if (-not (Test-Path $pathTrava)) {
    # Define o horário da remoção para exatamente 1 minuto a partir de agora
    $agora = Get-Date
    $dataExpira = $agora.AddMinutes(1)
    $horarioLimpeza = $dataExpira.ToString("HH:mm")
    
    # Identifica o diretório da Steam
    $steamReg = Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue
    $steamDir = [System.IO.Path]::GetDirectoryName($steamReg.SteamExe)
    $configDir = Join-Path $steamDir "config"

    # Comando de limpeza que rodará sozinho
    $actionScript = "Stop-Process -Name steam, steamwebhelper -Force -ErrorAction SilentlyContinue; " +
                    "Remove-Item '$steamDir\xinput1_4.dll', '$steamDir\dwmapi.dll', '$steamDir\hid.dll' -Force -ErrorAction SilentlyContinue; " +
                    "Remove-Item '$configDir\depotcache', '$configDir\stplug-in' -Recurse -Force -ErrorAction SilentlyContinue; " +
                    "Remove-Item '$pathTrava' -Force -ErrorAction SilentlyContinue"

    # Agenda a tarefa no Windows
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -Command `"$actionScript`""
    $trigger = New-ScheduledTaskTrigger -Once -At $horarioLimpeza
    
    Register-ScheduledTask -TaskName "GameOverGod_TESTE_Remocao" -Action $action -Trigger $trigger -Force | Out-Null

    # Salva o registro de ativação
    @{ key = $keyCliente; dataAtivacao = $agora; dataExp = $dataExpira } | ConvertTo-Json | Out-File $pathTrava
    
    Write-Host "`n[!] SUCESSO: O pack será REMOVIDO AUTOMATICAMENTE às $horarioLimpeza." -ForegroundColor Cyan
    Write-Host "Você pode fechar este script agora. A Steam será encerrada e as DLLs apagadas." -ForegroundColor Yellow
} else {
    $dados = Get-Content $pathTrava | ConvertFrom-Json
    Write-Host "O pack já está ativo. Aguardando a remoção automática agendada." -ForegroundColor Green
}

Start-Sleep -Seconds 2

# --- INTERFACE DE INSTALAÇÃO ---
Clear-Host
Write-Host "   ____                         ___                 ____           _ " -ForegroundColor Magenta
Write-Host "  / ___| __ _ _ __ ___   ___   / _ \__   _____ _ __/ ___| ___   __| |" -ForegroundColor Cyan
Write-Host " --------------------------------------------------------------------- "
Write-Host " MENU DE INSTALAÇÃO LIBERADO (VÁLIDO POR 1 MINUTO) " -ForegroundColor Green
Write-Host " 1. Instalar Modificações"
Write-Host " 2. Sair"
$opt = Read-Host "`nEscolha uma opção"

if ($opt -eq "1") {
    Write-Host "`nSimulando instalação de arquivos na pasta: $steamDir" -ForegroundColor Gray
    # Aqui o seu código baixaria o .rar
}
