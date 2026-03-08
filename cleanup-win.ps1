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
Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Program Files (x86)\Microsoft\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Users\ChingNok\AppData\Roaming\Microsoft\Windows\Templates\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# ---------------- Prefetch ----------------
Write-Host "清理 Prefetch..."
Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue

# ---------------- Windows Update Cache ----------------
Write-Host "清理 Windows Update 快取..."
net stop wuauserv | Out-Null
net stop bits | Out-Null
Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
net start wuauserv | Out-Null
net start bits | Out-Null

# ---------------- Delivery Optimization ----------------
Write-Host "清理 Delivery Optimization..."
Remove-Item "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue

# ---------------- 清 DirectX Shader ----------------
Write-Host "清理 GPU Shader Cache..."
Remove-Item "$env:LOCALAPPDATA\D3DSCache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\NVIDIA\DXCache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\NVIDIA\GLCache\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:LOCALAPPDATA\AMD\DxCache\*" -Recurse -Force -ErrorAction SilentlyContinue

# ---------------- 暫停搜尋索引（減IO） ----------------
Write-Host "暫停搜尋索引..."
net stop WSearch | Out-Null

# ---------------- Microsoft Store ----------------
Write-Host "重置 Microsoft Store Cache..."
wsreset.exe | Out-Null

# ---------------- 瀏覽器 ----------------
Write-Host "清理瀏覽器快取..."

# Edge
Remove-Item "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue

# Chrome
Remove-Item "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue

# Brave
Remove-Item "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue

# Firefox
Remove-Item "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*\cache2\entries\*" -Recurse -Force -ErrorAction SilentlyContinue

# Opera
Remove-Item "$env:LOCALAPPDATA\Opera Software\Opera Stable\Cache\*" -Recurse -Force -ErrorAction SilentlyContinue

# ---------------- DNS ----------------
Write-Host "刷新 DNS..."
ipconfig /flushdns | Out-Null

# ---------------- Thumbnail ----------------
Write-Host "清理縮圖快取..."
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*" -Force -ErrorAction SilentlyContinue

# ---------------- Windows 官方磁碟清理 (背景) ----------------
Write-Host "啟動系統磁碟清理..."
Start-Process cleanmgr.exe -ArgumentList "/sagerun:1 /d c /verylowdisk /autoclean" -WindowStyle Hidden -Wait

# ---------------- 清 RAM (Standby + Modified) ----------------
Write-Host "釋放可回收記憶體..."
$WMCPath = "$WMC_PATH"

if (Test-Path $WMCPath) {
   & $WMCPath /CombinedPageList /ModifiedFileCache /ModifiedPageList /RegistryCache /StandbyListLowPriority /SystemFileCache /WorkingSet
} else {
    Write-Host "錯誤：Windows Memory Cleaner 未喺路徑見到！"
    winget install IgorMundstein.WinMemoryCleaner
}

Write-Host "==== 清理完成 ====" -ForegroundColor Green
Try {
    Import-Module BurntToast -ErrorAction SilentlyContinue

    if (Get-Module -ListAvailable -Name BurntToast) {
        New-BurntToastNotification -Text "System Cleanup 完成", "所有指定 Cache 已清理完成。"
        Log "Windows notification sent."
    } else {
        Log "BurntToast module not available — skip notification."
    }
} Catch {
    Log "Notification error: $_"
}
