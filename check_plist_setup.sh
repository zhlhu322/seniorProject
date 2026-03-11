#!/bin/bash

echo "🔍 檢查 Gemini API Key 設定"
echo "================================"
echo ""

# 1. 檢查 Secrets.xcconfig 是否存在
echo "1️⃣ 檢查 Secrets.xcconfig 檔案..."
if [ -f "01/Secrets.xcconfig" ]; then
    echo "   ✅ Secrets.xcconfig 存在"
    echo "   📄 內容預覽："
    grep "GEMINI_API_KEY" 01/Secrets.xcconfig | sed 's/AIzaSy.*/AIzaSy***HIDDEN***/'
else
    echo "   ❌ Secrets.xcconfig 不存在！"
fi
echo ""

# 2. 檢查專案設定中的 INFOPLIST_KEY_GEMINI_API_KEY
echo "2️⃣ 檢查 Build Settings 中的設定..."
if grep -q "INFOPLIST_KEY_GEMINI_API_KEY" 01.xcodeproj/project.pbxproj; then
    echo "   ✅ Build Settings 中已設定 INFOPLIST_KEY_GEMINI_API_KEY"
    grep "INFOPLIST_KEY_GEMINI_API_KEY" 01.xcodeproj/project.pbxproj | head -1
else
    echo "   ❌ Build Settings 中沒有 INFOPLIST_KEY_GEMINI_API_KEY"
fi
echo ""

# 3. 檢查 Configuration File 是否設定
echo "3️⃣ 檢查 Configuration File 設定..."
if grep -q "baseConfigurationReferenceRelativePath = Secrets.xcconfig" 01.xcodeproj/project.pbxproj; then
    echo "   ✅ Configuration File 已設定為 Secrets.xcconfig"
else
    echo "   ❌ Configuration File 未正確設定"
    echo "   請在 Xcode 中設定："
    echo "   Project → Info → Configurations → Debug/Release → 選擇 Secrets"
fi
echo ""

# 4. 檢查編譯後的 App 是否包含 API Key
echo "4️⃣ 檢查編譯後的 App（如果存在）..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "01.app" -type d 2>/dev/null | head -1)
if [ -n "$APP_PATH" ]; then
    echo "   📦 找到 App: $APP_PATH"
    if [ -f "$APP_PATH/Info.plist" ]; then
        echo "   🔍 檢查 Info.plist 中的 keys..."
        /usr/libexec/PlistBuddy -c "Print" "$APP_PATH/Info.plist" 2>/dev/null | grep -i gemini || echo "   ❌ 沒有找到 GEMINI 相關的 key"
    else
        echo "   ❌ Info.plist 不存在"
    fi
else
    echo "   ℹ️  尚未編譯 App，或找不到編譯產物"
    echo "   請先在 Xcode 中編譯並運行一次"
fi
echo ""

echo "================================"
echo "📝 診斷建議："
echo ""
echo "如果上面有 ❌ 標記，請按照以下步驟修正："
echo ""
echo "✅ 步驟 1: 確認 Secrets.xcconfig 內容正確"
echo "   cat 01/Secrets.xcconfig"
echo ""
echo "✅ 步驟 2: 在 Xcode 設定 Configuration File"
echo "   1. 打開 Xcode"
echo "   2. 點擊專案根目錄（藍色圖標）"
echo "   3. 選擇 PROJECT '01'（不是 TARGETS）"
echo "   4. 切換到 Info 標籤"
echo "   5. 在 Configurations 區塊："
echo "      - Debug → 01 → 選擇 'Secrets'"
echo "      - Release → 01 → 選擇 'Secrets'"
echo ""
echo "✅ 步驟 3: Clean Build Folder 並重新編譯"
echo "   Cmd + Shift + K (Clean)"
echo "   Cmd + B (Build)"
echo ""
