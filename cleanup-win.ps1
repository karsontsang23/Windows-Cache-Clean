Write-Host "==== Windows 深度清理開始 ====" -ForegroundColor Cyan

# 管理員檢查
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    { if ($MyInvocation.UnboundArguments.Count -gt 0) {
        $argList += $MyInvocation.UnboundArguments}
        Start-Process -FilePath powershell.exe  -Verb RunAs  -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $PSCommandPath $argList "
        exit
        }
        
# ===== 新增：讀取 .env =====
$envFile = Join-Path $PSScriptRoot ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+?)\s*=\s*(.+)\s*$') {
            [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
        }
    }
}

# ===== 新增：從環境變數讀取設定 =====
$WMC_PATH = $env:WinMemoryCleaner_PATH

# ---------------- 回收桶 ----------------
Write-Host "清空回收桶..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# ---------------- TEMP ----------------
Write-Host "清理 TEMP..."
$p = [System.IO.Path]::GetTempPath()
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { [System.IO.File]::Delete($f) }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { [System.IO.Directory]::Delete($d, 1) }
$p = "C:\Program Files (x86)\Microsoft\Temp"
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }
$p = "C:\Users\ChingNok\AppData\Roaming\Microsoft\Windows\Templates"
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }
$p = "C:\Windows\Temp"
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }

# ---------------- Prefetch ----------------
Write-Host "清理 Prefetch..."
$p = "C:\Windows\Prefetch"
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }

# ---------------- Windows Update Cache ----------------
Write-Host "清理 Windows Update 快取..."
[System.ServiceProcess.ServiceController]::New('wuauserv').Stop()
[System.ServiceProcess.ServiceController]::New('bits').Stop()
$p = "C:\Windows\SoftwareDistribution\Download"                                                                                         
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }      
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }
[System.ServiceProcess.ServiceController]::New('wuauserv').Start()
[System.ServiceProcess.ServiceController]::New('bits').Start()

# ---------------- Delivery Optimization ----------------
Write-Host "清理 Delivery Optimization..."
$p = "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\"                                                                    
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }      
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }

# ---------------- 清 DirectX Shader ----------------
Write-Host "清理 GPU Shader Cache..."
$p = "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\"       
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }      
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }
$p = "$env:LOCALAPPDATA\D3DSCache"
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }
$p = "$env:LOCALAPPDATA\NVIDIA\DXCache"
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }
$p = "$env:LOCALAPPDATA\NVIDIA\GLCache"
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }
$p = "$env:LOCALAPPDATA\AMD\DxCache"
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }

# ---------------- 暫停搜尋索引（減IO） ----------------
Write-Host "暫停搜尋索引..."
[System.ServiceProcess.ServiceController]::New('WSearch').Stop()

# ---------------- Microsoft Store ----------------
Write-Host "重置 Microsoft Store Cache..."
wsreset.exe | Out-Null

# ---------------- 瀏覽器 ----------------
Write-Host "清理瀏覽器快取..."

# Edge
$p = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }

# Chrome
$p = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }

# Brave
$p = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache"
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }

# Firefox
foreach($p in [System.IO.Directory]::GetDirectories("$env:LOCALAPPDATA\Mozilla\Firefox\Profiles")){
    $e="$p\cache2\entries";if([System.IO.Directory]::Exists($e)){
        foreach($f in [System.IO.Directory]::GetFiles($e,'*',1)){try{[System.IO.File]::Delete($f)}catch{}}
        foreach($d in [System.IO.Directory]::GetDirectories($e)){try{[System.IO.Directory]::Delete($d,1)}catch{}}
    }
}

# Opera
$p = "$env:LOCALAPPDATA\Opera Software\Opera Stable\Cache"
foreach ($f in [System.IO.Directory]::GetFiles($p, '*', 1)) { try { [System.IO.File]::Delete($f) } catch {} }
foreach ($d in [System.IO.Directory]::GetDirectories($p)) { try { [System.IO.Directory]::Delete($d, 1) } catch {} }

# ---------------- DNS ----------------
Write-Host "刷新 DNS..."
ipconfig /flushdns | Out-Null

# ---------------- Thumbnail ----------------
Write-Host "清理縮圖快取..."
$p = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
foreach ($f in [System.IO.Directory]::GetFiles($p, 'thumbcache_*')) { try { [System.IO.File]::Delete($f) } catch {} }

# ---------------- Windows 官方磁碟清理 (背景) ----------------
Write-Host "啟動系統磁碟清理..."
Start-Process cleanmgr.exe -ArgumentList "/sagerun:1 /d c /verylowdisk /autoclean" -WindowStyle Hidden -Wait

# ---------------- 清 RAM (Standby + Modified) ----------------
Write-Host "釋放可回收記憶體..."

if (Test-Path $WMC_PATH) {
   & $WMC_PATH /CombinedPageList /ModifiedFileCache /ModifiedPageList /RegistryCache /StandbyListLowPriority /SystemFileCache /WorkingSet
} else {
    Write-Host "錯誤：Windows Memory Cleaner 未喺路徑見到！"
    winget install IgorMundstein.WinMemoryCleaner
}

Write-Host "==== 清理完成 ====" -ForegroundColor Green
Try {
    Install-Module -Name BurntToast -Scope CurrentUser -Force -ErrorAction SilentlyContinue

    if (Get-Module -ListAvailable -Name BurntToast) {
        New-BurntToastNotification -Text "所有指定 Cache 已清理完成。"
        Log "Windows notification sent."
    } else {
        Log "BurntToast module not available — skip notification."
    }
} Catch {
    Log "Notification error: $_"
}
