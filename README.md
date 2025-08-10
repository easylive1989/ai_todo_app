# AI Todo App - GitHub Project 自動化監聽器

這是一個監聽 GitHub Project 新增項目的 Python 應用程式，專門用於追蹤 `easylive1989/ai_todo_app` 專案的 Project #5。當偵測到新的 Item 時，會自動啟動 Claude Code CLI 執行任務內容，並由 Claude Code AI 負責 commit 與 push 變更。

## 功能特色

- 🔍 持續監聽指定的 GitHub Project
- 🆕 即時偵測新增的 Project Items
- 📊 支援 Issues、Pull Requests 和 Draft Issues
- 🏷️ 顯示自定義字段資訊
- ⏰ 可設定檢查間隔
- 🤖 自動啟動 Claude Code CLI 執行任務
- 💾 由 Claude Code AI 負責 commit 和 push 變更

## 環境需求

- Python 3.7+
- GitHub Personal Access Token
- Claude Code CLI (需要先安裝並設定)
- Git (用於自動 commit 和 push)

## 安裝與設定

1. 安裝相依套件：
```bash
pip install -r requirements.txt
```

2. 設定環境變數：
複製 `.env.example` 為 `.env` 並填入你的 GitHub token：
```bash
cp .env.example .env
```

3. 編輯 `.env` 檔案：
```bash
# 必要設定
GITHUB_TOKEN=your_github_token_here

# 選擇性設定 (可使用預設值)
CLAUDE_CLI_PATH=claude                    # Claude CLI 路徑
PROJECT_DIR=/path/to/your/project         # 專案目錄
REQUEST_COMMIT=true                       # 是否要求 Claude Code 自動 commit/push
```

4. 確保 Claude Code CLI 已安裝並可使用：
```bash
# 測試 Claude CLI 是否正常運作
claude --version
```

5. 確保專案目錄已初始化 Git 且設定好遠端倉庫：
```bash
git status
git remote -v
```

## 使用方法

執行監聽器：
```bash
python github_project_monitor.py
```

程式會每 60 秒檢查一次是否有新的 Project Items：
- 偵測到新 Item 時，會自動提取任務內容
- 啟動 Claude Code CLI 執行任務
- 在提示詞中要求 Claude Code AI 執行完成後自動 commit 和 push
- 按 `Ctrl+C` 可停止監聽

## 設定說明

程式預設監聽以下設定：
- Repository: `easylive1989/ai_todo_app`
- Project: #5
- 檢查間隔: 60 秒

如需修改設定，請編輯 `github_project_monitor.py` 中的 `main()` 函數。

## 工作流程

1. **監聽階段**: 持續監聽指定的 GitHub Project
2. **偵測階段**: 發現新的 Project Item
3. **提取階段**: 提取 Item 的標題和內容作為任務描述
4. **執行階段**: 啟動 Claude Code CLI 執行任務
5. **同步階段**: Claude Code AI 自動 commit 和 push 變更

## 輸出範例

```
🔍 GitHub Project 監聽器
📂 Repository: easylive1989/ai_todo_app
📋 Project: #5
⏱️  檢查間隔: 60 秒
==================================================

🆕 發現 1 個新的 Item!
==================================================

📌 新 Issue: 實作使用者註冊功能
   🔢 編號: #123
   📈 狀態: open
   🔗 URL: https://github.com/easylive1989/ai_todo_app/issues/123
   📅 創建時間: 2024-01-15T10:30:00Z

🚀 開始執行任務...
🤖 啟動 Claude Code CLI...
   📝 執行內容: 實作使用者註冊功能...
✅ Claude Code 執行成功
🎉 任務執行完成
```

## 注意事項

- 確保 Claude Code CLI 有足夠權限執行任務和 Git 操作
- 建議在測試環境先試用，避免對生產環境造成影響
- Claude Code AI 需要有 Git 倉庫的 commit 和 push 權限
- 任務執行時間限制為 10 分鐘，超時會自動停止
- 如果設定 `REQUEST_COMMIT=true`，會在任務提示詞中加入 commit/push 要求
- 所有 Git 操作由 Claude Code AI 負責，不在監聽腳本中執行