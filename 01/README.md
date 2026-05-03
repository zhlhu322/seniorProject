# 01 專案設定說明

## 第一步：建立 Secrets.xcconfig

`Secrets.xcconfig` 包含個人敏感資訊，**不會被 git 追蹤**，clone 下來後需要自己建立。

在 `01/` 資料夾下（與 `01.xcodeproj` 同層）建立 `Secrets.xcconfig`，內容如下：

```
GEMINI_API_KEY = 在Line記事本
DEVELOPMENT_TEAM = 你的_Apple_Developer_Team_ID
APP_BUNDLE_ID = com.你的名字.01
```

---

## 第二步：確認 Xcode 有讀到 xcconfig

1. 打開 `01.xcodeproj`
2. 左側點選最上層的 **01 project**（藍色圖示）
3. 選 **Info** → **Configurations**
4. 確認 Debug 和 Release 都有指向 `Secrets.xcconfig`

---

## 常見問題

### 發不出 API 請求

**可能原因 1：沒有建立 `Secrets.xcconfig`**

沒有這個檔案的話，`GEMINI_API_KEY` 和 `APP_BUNDLE_ID` 都是空值，導致：
- App bundle 沒有有效的 `CFBundleIdentifier`，系統拒絕安裝
- 即使裝上去，API key 是空的，所有請求都會失敗

解法：照上方第一步建立檔案。

---

**可能原因 2：xcconfig 沒有接上 Xcode project**

檔案建立了，但 Xcode 沒有讀到，變數仍然是空的。

解法：照上方第二步確認 Configurations 設定。
