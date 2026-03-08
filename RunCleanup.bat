@echo off
REM =============================================
REM RunCleanup.bat - 啟動 PowerShell 系統清理腳本
REM =============================================

rem 讀取 .env
for /f "usebackq tokens=1,* delims== eol=#" %%A in ("%~dp0.env") do (
    if not "%%A"=="" (
        set "%%A=%%B"
    )
)
# 檢查可用 RAM <= %RAM_THRESHOLD_PERCENT% 才執行
powershell -Command " $totalRAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory;$freeRAM = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory * 1KB;$freePercent = [math]::Round(($freeRAM / $totalRAM) * 100,2); if ($freePercent -le $env:RAM_THRESHOLD_PERCENT) {  Write-Host '可用 RAM' $freePercent ' <= ' $env:RAM_THRESHOLD_PERCENT '執行清理腳本' ; PowerShell.exe -Verb RunAs -NoProfile -ExecutionPolicy Bypass -File $env:Script_PATH\cleanup-win.ps1;}   else { Write-Host '可用 RAM '$freePercent ' >' $env:RAM_THRESHOLD_PERCENT  '不執行清理'; }"

