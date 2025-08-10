# Todo App

一個使用 Flutter 開發的功能完整待辦事項管理應用程式。

## 🌟 功能特色

### 核心功能
- ✅ 新增、編輯、刪除待辦事項
- ✅ 標記完成/未完成狀態
- ✅ 本地資料持久化儲存

### 進階功能
- 🏷️ **分類管理**：工作、個人、購物、健康、學習、記帳、其他
- 🎯 **優先級設定**：高、中、低三級優先級
- 📅 **到期日管理**：設定到期時間，過期項目紅色提醒
- 🔍 **搜尋功能**：支援標題和描述搜尋
- 📊 **統計資訊**：顯示總數、完成率等統計

### UI/UX 特色
- 🎨 Material Design 3 設計風格
- 🌙 支援深色模式
- 📱 響應式設計，支援各種螢幕尺寸
- 🎯 直觀的操作體驗

## 🚀 線上體驗

訪問 [GitHub Pages](https://easylive1989.github.io/ai_todo_app/) 體驗線上版本。

## 💻 本地開發

### 環境需求
- Flutter SDK 3.32.4 或更高版本
- Dart SDK 3.8.1 或更高版本

### 安裝步驟

1. 克隆專案
```bash
git clone https://github.com/easylive1989/ai_todo_app.git
cd ai_todo_app/todo_app
```

2. 安裝依賴
```bash
flutter pub get
```

3. 執行應用
```bash
# Web 版本
flutter run -d chrome

# iOS 模擬器
flutter run -d ios

# Android 模擬器
flutter run -d android
```

### 建置發佈版本

```bash
# Web 版本
flutter build web --release

# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

## 📦 使用的套件

- **provider**: 狀態管理
- **shared_preferences**: 本地存儲
- **uuid**: 唯一識別碼生成
- **intl**: 日期格式化

## 🏗️ 專案結構

```
lib/
├── main.dart                 # 應用程式入口
├── models/                   # 資料模型
│   ├── todo.dart            # 待辦事項模型
│   └── category.dart        # 分類模型
├── services/                 # 服務層
│   └── todo_service.dart    # 資料持久化服務
├── providers/                # 狀態管理
│   └── todo_provider.dart   # 待辦事項狀態管理
├── screens/                  # 畫面
│   ├── home_screen.dart     # 主畫面
│   └── add_todo_screen.dart # 新增/編輯畫面
└── widgets/                  # 可重用元件
    ├── todo_item.dart       # 待辦事項項目元件
    ├── category_selector.dart # 分類選擇器
    └── priority_selector.dart # 優先級選擇器
```

## 🚀 部署到 GitHub Pages

本專案已配置 GitHub Actions 自動部署：

1. 確保 GitHub Pages 已啟用
2. 推送程式碼到 main/master 分支
3. GitHub Actions 會自動建置並部署到 GitHub Pages
4. 訪問 `https://easylive1989.github.io/ai_todo_app/` 查看部署結果

## 📝 授權

MIT License

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request！

## 👥 作者

使用 Claude Code AI 協助開發
