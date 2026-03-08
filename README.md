# 📌 System Cleanup 自動維護工具

## ⭐ 簡介

呢個工具係一套用 **PowerShell / Batch / Task Scheduler** 組成嘅 Windows 系統清理解決方案，目的係：

* 自動清除垃圾暫存、Cache、回收桶
* 清理 Windows Update Cache、Shader Cache、DNS Cache
* 清理 RAM Standby List、Page List 與系統工作集
* 支援由 Task Scheduler 定時觸發（可條件式按可用 RAM 執行）

透過 `.env` 設定同自動任務排程，令系統清理變得簡單自動。

---

## 📁 內容介紹

| 檔案                  | 說明                      |
| ------------------- | ----------------------- |
| `.env`              | 設定檔（排程時間、RAM 門檻、路徑等）    |
| `clean.ps1`         | 主清理 PowerShell 腳本       |
| `run-clean.bat`     | 一鍵執行批次檔                 |
| `create_task.ps1`   | 產生並匯入 Task Scheduler 任務 |
| `README.md`         | 使用說明（本檔）                |

> ⚠️ 部分清理步驟需第三方工具支援（例如清除 Standby List），需要你自行下載並放置於 `.env` 指定路徑。

---

## ⚙️ 安裝與設定

### 1. 下載Git倉庫

```
git clone https://github.com/karsontsang23/Windows-Cache-Clean.git
```

---

### 2. 編輯 `.env`

打開 `.env`，按你需求修改幾項：

| 參數                       | 說明             | 例子                                             |
| ------------------------ | -------------- | ---------------------------------------------- |
| `TASK_NAME`              | 任務名稱           | `SystemCleanup`                                |
| `CLEAN_TIME`             | 每日開始清理時間（24h）  | `06:00pm`                                        |
| `RAM_THRESHOLD_PERCENT`  | 低於某百分比才執行      | `22.5`                                           |
| `WinMemoryCleaner_PATH`      | WindowsMemoryCleaner 清理工具路徑 | `C:\Tools\system-cleanup\WindowsMemoryCleaner.exe` |
| `Script_PATH`               | Script路徑      | `C:\Tools\system-cleanup\`                             |

---

### 3. 設定 Cleanmgr 項目（可選）

首次要用 cleanmgr 自己設定一次清理項目：

```shell
cleanmgr.exe /sageset:1
```

勾選你想自動清除嘅項目，之後排程會自動用：

```
cleanmgr.exe /sagerun:1
```

---

### 4. 建立 Task Scheduler 任務

以 **系統管理員** 身分執行：

```powershell
Setup-CleanTask.ps1
```

執行後會自動建立每日定時任務。

---

## ▶️ 排程運作方式

1. Task 會喺 `.env` 設定嘅 `CLEAN_TIME` 觸發
3. 每次喺 `RunCleanup.bat` 底下先檢查可用 RAM
4. 只喺 **可用 RAM ≤ 門檻百分比** 時先執行清理

---

## 📌 支援清理項目（榜單）

| 清理範圍                                   | 支援          |
| -------------------------------------- | ----------- |
| 回收桶                                    | ✅           |
| 系統 + 使用者 TEMP & Cache                  | ✅           |
| 瀏覽器 cache                | ✅           |
| Shader Cache (DirectX / AMD / NVIDIA)  | ✅           |
| Windows Update Cache                   | ✅           |
| Delivery Optimization Cache            | ✅           |
| DNS Cache                              | ✅           |
| Thumbnail Cache                        | ✅           |
| Windows Search Index 暫停                | ✅           |
| Standby List / Page List / Working Set | ⚠️ 需第三方 exe |
| Official Disk Cleanup（cleanmgr）        | ✅           |

### 瀏覽器清理支援

工具會自動清除以下瀏覽器嘅 cache：

- Chrome
- Edge 
- Brave
- Firefox  
- Opera  

> Cache 位置基於 Windows AppData 內嘅標準路徑進行清除。若有多個 profile，自動遍歷所有 profile cache。  
---

## 🧠 進階工具補充（非必要）

| 工具                     | 用途                                   |
| ---------------------- | ------------------------------------ |
| `WinMemoryCleaner.exe` | 清除 RAM Standby / Modified / PageList |
如要自動清理 Standby / PageList，請下載放入 `.env` 裡指定位置。

### 清理完成後通知

工具支援顯示 Windows Toast 通知（需安裝 BurntToast PowerShell 模組）：

```powershell
Install-Module -Name BurntToast -Scope CurrentUser -Force
```

## ❗ 注意與建議
✔ **清理 Windows Update Cache 會暫停 update 服務**
✔ **某些服務會被停止再啟動（例如 WSearch）**
✔ **有些 Cache 無法刪除因檔案被鎖定**
