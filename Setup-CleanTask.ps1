# Install-InstallTask.ps1
# 目標：建立一個 Task Scheduler 任務，每 24 小時執行 RunUltimateCleanup.bat
# 產生 XML 檔可匯入 Task Scheduler
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
$TASK_NAME = $env:TASK_NAME
$CLEAN_TIME = $env:CLEAN_TIME
$PATH_TARGET = $env:Script_PATH
$RAM_THRESHOLD_PERCENT = $env:RAM_THRESHOLD_PERCENT
$batPath = "$PATH_TARGET\RunCleanup.bat"
$xmlPath = "$PATH_TARGET\Cleanup_Task.xml"

# 管理員檢查
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    { if ($MyInvocation.UnboundArguments.Count -gt 0) {
        $argList += $MyInvocation.UnboundArguments}
        Start-Process -FilePath powershell.exe  -Verb RunAs  -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $PSCommandPath $argList "
        exit
        }
        
if (-not (Test-Path $batPath)) {
New-Item -ItemType File -Path $batPath -Force | Out-Null
}

# ------------------- 觸發器 (Trigger) -------------------
$wrapperScript = @'
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
powershell -Command " $totalRAM = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory;$freeRAM = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory * 1KB;$freePercent = [math]::Round(($freeRAM / $totalRAM) * 100,2); if ($freePercent -le $env:RAM_THRESHOLD_PERCENT) {  Write-Host '可用 RAM' $freePercent ' <= ' $env:RAM_THRESHOLD_PERCENT '執行清理腳本' ; PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File $env:Script_PATH\cleanup-win.ps1;}   else { Write-Host '可用 RAM '$freePercent ' >' $env:RAM_THRESHOLD_PERCENT  '不執行清理'; }"

'@
Set-Content -Path $batPath -Value $wrapperScript -Force

# 每日  執行，24 小時重複
$trigger = New-ScheduledTaskTrigger -At "$CLEAN_TIME" -Daily

# ------------------- 動作 (Action) -------------------
$action = New-ScheduledTaskAction -Execute $batPath -WorkingDirectory $PATH_TARGET 

# ------------------- Principal (SYSTEM) -------------------
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount

# ------------------- 註冊工作 -------------------
if (Get-ScheduledTask -TaskName $TASK_NAME -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TASK_NAME -Confirm:$false
}

Register-ScheduledTask -TaskName $TASK_NAME -Action $action -Trigger $trigger -Principal $principal  -Description "Cleanup Windows Cache" -Force

Write-Host "Task '$TASK_NAME' 已建立"

# ------------------- 匯出 XML -------------------
try {
    Export-ScheduledTask -TaskName $TASK_NAME -TaskPath "\" | Out-File -FilePath $xmlPath -Force
    Write-Host "已產生可匯入 XML 檔: $xmlPath"
} catch {
    Write-Warning "匯出 XML 失敗: $_"
}
Write-Host "Press any key to continue..."
[System.Console]::ReadKey() > $null