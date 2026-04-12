//
//  config.swift
//  01
//
//  Created by 李恩亞 on 2025/12/14.
//

import Foundation

enum AppEnvironment {
    static var geminiAPIKey: String {
        // 直接從 Target 的 Info 設定中讀取
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
           !apiKey.isEmpty,
           apiKey != "$(GEMINI_API_KEY)" { // 確保 Xcode 已經完成變數替換
            print("✅ [Config] GEMINI_API_KEY 讀取成功")
            return apiKey
        }
        
        // 備用：從 Scheme 環境變數讀取
        if let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"], !apiKey.isEmpty {
            print("✅ [Config] 從環境變數讀取成功")
            return apiKey
        }
        
        print("❌ [Config] 嚴重錯誤：找不到 GEMINI_API_KEY，請檢查 Target Info 或 xcconfig 設定")
        return ""
    }
}
