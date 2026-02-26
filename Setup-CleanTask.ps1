# Install-InstallTask.ps1
# 目標：建立一個 Task Scheduler 任務，每 24 小時執行 RunUltimateCleanup.bat
# 產生 XML 檔可匯入 Task Scheduler

$taskName = "Clean"
$batPath = "D:\windows\AppFiles\clean-win\RunCleanup.bat"
$xmlPath = "D:\windows\AppFiles\clean-win\Cleanup_Task.xml"

# 管理員檢查
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    { if ($MyInvocation.UnboundArguments.Count -gt 0) {
        $argList += $MyInvocation.UnboundArguments}
        Start-Process -FilePath powershell.exe  -Verb RunAs  -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $PSCommandPath $argList "
        exit
        }
        
if (-not (Test-Path $batPath)) {
    Write-Error "找不到 BAT 檔案: $batPath"
    exit 1
}

# ------------------- 動作 (Action) -------------------
$action = New-ScheduledTaskAction -Execute "$batPath"

# ------------------- 觸發器 (Trigger) -------------------
# 每日 03:00 AM 執行，24 小時重複
$trigger = New-ScheduledTaskTrigger -Daily -At "06:00PM"

# ------------------- Principal (SYSTEM) -------------------
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# ------------------- 註冊工作 -------------------
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal 

Write-Host "Task '$taskName' 已建立"

# ------------------- 匯出 XML -------------------
try {
    Export-ScheduledTask -TaskName $taskName -TaskPath "\" -Xml $xmlPath -Force
    Write-Host "已產生可匯入 XML 檔: $xmlPath"
} catch {
    Write-Warning "匯出 XML 失敗: $_"
}