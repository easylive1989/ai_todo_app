# GitHub Project Monitor Workflow 設定說明

本專案已將原本的 `github_project_monitor.py` 本地監聽器改為 GitHub Actions workflow，可以自動化處理 GitHub Project 的新任務。

## 架構說明

### 新增檔案
1. **`.github/workflows/project_monitor.yml`** - 主要的 workflow 檔案
2. **`scripts/process_project_items.py`** - 處理 Project items 的 Python script
3. **`scripts/requirements.txt`** - Python 依賴套件
4. **`scripts/processed_items.json`** - 狀態儲存檔案（初始為空）

### Workflow 執行流程
1. **定時觸發**: 每 1 分鐘檢查一次 GitHub Project
2. **檢查新任務**: 尋找狀態為 "Backlog" 的新 items
3. **狀態管理**: 使用 GitHub Actions artifacts 儲存已處理的 items
4. **Claude 處理**: 自動呼叫 Claude Code 執行任務
5. **狀態更新**: 完成處理後將 items 狀態更新為 "Review"
6. **Discord 通知**: 發送處理結果通知

## 必要的 GitHub Secrets 設定

請在 GitHub repository 的 Settings > Secrets and variables > Actions 中設定以下 secrets：

### 1. DISCORD_WEBHOOK_URL
- **用途**: 發送 Discord 通知
- **取得方式**: 
  1. 在 Discord 伺服器中建立 webhook
  2. 複製 webhook URL
  3. 設定為 secret

### 2. CLAUDE_CODE_OAUTH_TOKEN
- **用途**: Claude Code Action 認證
- **取得方式**:
  1. 前往 [Claude Code 設定頁面](https://claude.ai/code)
  2. 產生 OAuth token
  3. 設定為 secret
- **注意**: 此 secret 可能已經存在（檢查現有的 claude.yml workflow）

### 3. GITHUB_TOKEN
- **用途**: 存取 GitHub API 和 Project
- **設定**: 這個 token 會自動由 GitHub Actions 提供，無需手動設定
- **權限**: workflow 已設定必要的權限（contents, issues, pull-requests, actions, id-token）

## 環境變數說明

以下環境變數會自動在 workflow 中設定：

- `GITHUB_TOKEN`: GitHub Actions 自動提供
- `DISCORD_WEBHOOK_URL`: 從 secrets 讀取
- `GITHUB_OUTPUT`: GitHub Actions 自動設定用於步驟間傳遞資料

## 功能特色

### 1. 智慧狀態管理
- 使用 artifacts 儲存已處理的 items，避免重複處理
- 自動清理 30 天前的記錄
- 支援初次執行和中斷後恢復

### 2. 只處理 Backlog 任務
- 只會處理狀態為 "Backlog" 的新 items
- 處理完成後自動更新狀態為 "Review"
- 忽略其他狀態的 items

### 3. Discord 整合
- 發現新任務時立即通知
- 處理完成後發送結果通知
- 包含任務詳情和執行狀態

### 4. Claude Code 整合
- 自動將任務內容傳遞給 Claude
- 支援常用的開發指令（Flutter、Git、Python 等）
- 自動 commit 和 push 變更

### 5. 手動觸發支援
- 支援透過 GitHub Actions UI 手動執行
- 可設定強制執行模式

## 測試方式

1. **建立測試任務**:
   - 在 GitHub Project #5 中建立新的 Issue 或 Draft Issue
   - 確保狀態設定為 "Backlog"

2. **檢查 workflow**:
   - 前往 Actions 頁面查看 "GitHub Project Monitor" workflow
   - 確認是否自動執行並成功處理任務

3. **驗證結果**:
   - 確認任務狀態已更新為 "Review"
   - 檢查是否收到 Discord 通知
   - 確認 Claude 是否正確執行任務並 commit 變更

## 故障排除

### 1. Workflow 不執行
- 檢查 repository 是否為 private（private repo 的 cron 可能有限制）
- 確認 workflow 檔案語法正確
- 檢查是否有足夠的 GitHub Actions 分鐘數

### 2. Python script 錯誤
- 檢查 GITHUB_TOKEN 權限
- 確認 Project 編號和 repository 設定正確
- 查看 Actions logs 中的詳細錯誤訊息

### 3. Claude Code 執行失敗
- 檢查 CLAUDE_CODE_OAUTH_TOKEN 是否正確
- 確認 allowed_tools 設定是否包含需要的指令
- 查看 Claude Code 相關的錯誤訊息

### 4. Discord 通知失敗
- 檢查 DISCORD_WEBHOOK_URL 是否正確
- 確認 Discord webhook 是否仍然有效
- 查看相關錯誤日誌

## 相較於原本監聽器的優勢

1. **無需本地執行**: 完全在雲端執行，不需要維護本地程序
2. **更可靠**: GitHub Actions 提供穩定的執行環境
3. **更好的監控**: 可透過 GitHub Actions UI 查看執行歷史和錯誤
4. **自動復原**: 中斷後可自動恢復，不會丟失處理狀態
5. **更好的安全性**: 使用 GitHub Secrets 管理敏感資訊

## 停用原本的監聽器

設定完成並確認 workflow 正常運作後，可以停止原本的 `github_project_monitor.py` 本地監聽程序。