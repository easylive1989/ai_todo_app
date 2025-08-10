# AI Todo App - GitHub Project 監聽器

這是一個監聽 GitHub Project 新增項目的 Python 應用程式，專門用於追蹤 `easylive1989/ai_todo_app` 專案的 Project #5。

## 功能特色

- 🔍 持續監聽指定的 GitHub Project
- 🆕 即時偵測新增的 Project Items
- 📊 支援 Issues、Pull Requests 和 Draft Issues
- 🏷️ 顯示自定義字段資訊
- ⏰ 可設定檢查間隔

## 環境需求

- Python 3.7+
- GitHub Personal Access Token

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
```
GITHUB_TOKEN=your_github_token_here
```

## 使用方法

執行監聽器：
```bash
python github_project_monitor.py
```

程式會每 60 秒檢查一次是否有新的 Project Items，按 `Ctrl+C` 可停止監聽。

## 設定說明

程式預設監聽以下設定：
- Repository: `easylive1989/ai_todo_app`
- Project: #5
- 檢查間隔: 60 秒

如需修改設定，請編輯 `github_project_monitor.py` 中的 `main()` 函數。

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
```