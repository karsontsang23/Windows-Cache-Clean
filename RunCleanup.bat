@echo off
REM =============================================
REM RunUltimateCleanup.bat - 啟動 PowerShell 系統清理腳本
REM =============================================

SET ScriptDir=D:\windows\AppFiles\clean-win
SET PowerShellScript=%ScriptDir%\cleanup-win.ps1

REM 以 PowerShell 執行清理腳本
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%PowerShellScript%"