# ===== CONFIGURAÇÃO DE AMBIENTE E CODIFICAÇÃO =====
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "Game Over - Gestão de Biblioteca v3.0"
Clear-Host

# Ativar suporte a cores ANSI no console para evitar letras bugadas
if ($host.Name -eq 'ConsoleHost') {
    $mode = Get-ItemProperty -Path "HKCU:\Console" -Name "VirtualTerminalLevel" -ErrorAction SilentlyContinue
    if (-not $mode) {
        New-ItemProperty -Path "HKCU:\Console" -Name "VirtualTerminalLevel" -PropertyType DWord -Value 1 -Force | Out-Null
    }
}

# ===== SISTEMA DE ACESSO (SENHA) =====
$tentativas = 0
$senhaCorreta = "1234"

while ($tentativas -lt 3) {
    Write-Host "----------------------------------------" -ForegroundColor Magenta
    $inputSenha = Read-Host " DIGITE A SENHA DE ACESSO "
    Write-Host "----------------------------------------" -ForegroundColor Magenta
    
    if ($inputSenha -eq $senhaCorreta) {
        Write-Host "Acesso autorizado!" -ForegroundColor Green
        Start-Sleep -Milliseconds 800
        break
    } else {
        $tentativas++
        Write-Host "Senha incorreta! ($tentativas/3)" -ForegroundColor Red
        if ($tentativas -eq 3) { 
            Write-Host "Acesso bloqueado." -ForegroundColor DarkRed
            Start-Sleep -Seconds 2
            exit 
        }
    }
}

# ===== DETECÇÃO DE CAMINHO DA STEAM =====
$steamReg = Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue
$steamExe = $steamReg.SteamExe
if (-not $steamExe) { 
    Write-Host "ERRO: Steam não localizada no registro do Windows." -ForegroundColor Red
    Pause; exit 
}
$steamDir = [System.IO.Path]::GetDirectoryName($steamExe)
$configDir = Join-Path $steamDir "config"

# ===== INTERFACE VISUAL (BANNER) =====
function Show-Header {
    Clear-Host
    Write-Host "  ____    _    __  __  _____    ___  __     _____  ____  " -ForegroundColor Magenta
    Write-Host " / ___|  / \  |  \/  || ____|  / _ \ \ \   / /| ____||  _ \ " -ForegroundColor Cyan
    Write-Host "| |  _  / _ \ | |\/| ||  _|   | | | | \ \ / / |  _|  | |_) |" -ForegroundColor Magenta
    Write-Host "| |_| |/ ___ \| |  | || |___  | |_| |  \ V /  | |___ |  _ < " -ForegroundColor Cyan
    Write-Host " \____/_/   \_\_|  |_||_____|  \___/    \_/   |_____||_| \_\" -ForegroundColor Magenta
    Write-Host " ------------------------------------------------------------ " -ForegroundColor White
}

# ===== FUNÇÕES DE OPERAÇÃO =====

function Stop-Steam {
    Write-Host "Fechando processos da Steam para evitar erros..." -ForegroundColor Yellow
    Get-Process steam, steamwebhelper -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
}

function Executar-Instalacao {
    param ($Modo)
    Show-Header
    
    # --- DOWNLOAD DO ZIP DO DISCORD ---
    if (-not (Test-Path "KRAYz_STORE.zip")) {
        Write-Host "Baixando arquivos da biblioteca (KRAYz STORE)..." -ForegroundColor Cyan
        $urlDoZip = "https://cdn.discordapp.com/attachments/1500928090619121826/1500928160022401084/KRAYz_STORE.zip?ex=69fa37c7&is=69f8e647&hm=cb13a7ecf606e6dc2f4e63cf9745f9493b191bbf029e441e58026cd3546e7490&" 
        
        try {
            Invoke-WebRequest -Uri $urlDoZip -OutFile "KRAYz_STORE.zip" -ErrorAction Stop
            Write-Host "Download concluído com sucesso!" -ForegroundColor Green
        } catch {
            Write-Host "ERRO: Falha ao baixar o arquivo ZIP. O link pode ter expirado." -ForegroundColor Red
            Pause; return
        }
    }

    Stop-Steam
    
    # Downloads das DLLs do Servidor SteamOx
    Write-Host "Sincronizando DLLs de sistema..." -ForegroundColor Cyan
    $dlls = @{ 
        "xinput1_4.dll" = "http://update.steamox.com/update"
        "dwmapi.dll"    = "http://update.steamox.com/dwmapi" 
    }
    foreach ($name in $dlls.Keys) {
        try {
            Invoke-WebRequest -Uri $dlls[$name] -OutFile (Join-Path $steamDir $name) -ErrorAction SilentlyContinue
        } catch {}
    }

    # Extração e Configuração (Lógica do antigo .bat)
    Write-Host "Extraindo e aplicando configurações..." -ForegroundColor Cyan
    $tmp = "$env:TEMP\krayz_install_tmp"
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    
    try {
        Expand-Archive -Path "KRAYz_STORE.zip" -DestinationPath $tmp -Force
        
        # Limpeza de pastas de config (conforme o rmdir /s /q)
        $limpar = @("$configDir\depotcache", "$configDir\stplug-in")
        foreach ($l in $limpar) { if (Test-Path $l) { Remove-Item $l -Recurse -Force -ErrorAction SilentlyContinue } }

        # Cópia dos arquivos (conforme o xcopy)
        if (Test-Path "$tmp\Config") {
            Copy-Item -Path "$tmp\Config\*" -Destination "$configDir\" -Recurse -Force
        }
        if (Test-Path "$tmp\Hid.dll") {
            Copy-Item -Path "$tmp\Hid.dll" -Destination "$steamDir\" -Force
        }
        
        # Limpeza de caches se for Instalação Completa
        if ($Modo -eq "Full") {
            Write-Host "Otimizando caches da Steam..." -ForegroundColor Yellow
            $folders = @("cache", "temp", "tmp")
            foreach ($f in $folders) { 
                $p = Join-Path $steamDir $f
                if (Test-Path $p) { Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue }
            }
        }
        Write-Host "`nPROCESSO FINALIZADO COM SUCESSO!" -ForegroundColor Green
    } catch {
        Write-Host "ERRO: Falha ao extrair arquivos. O ZIP pode estar corrompido." -ForegroundColor Red
    }
}

# ===== MENU DE OPÇÕES =====
Show-Header
Write-Host " 1. Atualizar Biblioteca & DLLs" -ForegroundColor White
Write-Host " 2. Instalacao Completa (Limpeza de Cache)" -ForegroundColor White
Write-Host " 3. Desinstalar / Limpar Sistema" -ForegroundColor White
Write-Host " 4. Sair" -ForegroundColor White
Write-Host " ------------------------------------------------------------ "

$opt = Read-Host "Escolha uma opcao"

switch ($opt) {
    "1" { Executar-Instalacao "Normal" }
    "2" { Executar-Instalacao "Full" }
    "3" { 
        Stop-Steam
        $apagar = @("Hid.dll", "xinput1_4.dll", "dwmapi.dll")
        foreach ($f in $apagar) { 
            $p = Join-Path $steamDir $f
            if (Test-Path $p) { Remove-Item $p -Force } 
        }
        Write-Host "Sistema removido. Steam limpa." -ForegroundColor Yellow
    }
    Default { exit }
}

Write-Host "`nReiniciando Steam..." -ForegroundColor Cyan
Start-Process $steamExe
Start-Sleep -Seconds 2
