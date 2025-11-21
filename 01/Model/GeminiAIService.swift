//
//  GeminiAIService.swift
//  01
//
//  Created on 2025/11/12.
//

import Foundation
import UIKit

// MARK: - AI 服務錯誤
enum AIServiceError: Error {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case imageEncodingFailed
    case apiError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidAPIKey:
            return "API Key 無效"
        case .networkError(let error):
            return "網路錯誤：\(error.localizedDescription)"
        case .invalidResponse:
            return "無效的 API 回應"
        case .imageEncodingFailed:
            return "圖片編碼失敗"
        case .apiError(let message):
            return "API 錯誤：\(message)"
        }
    }
}

// MARK: - Gemini AI 服務
class GeminiAIService {
    
    // MARK: - 運動知識庫常量
    static let availableExercises = [
        "手臂彎舉","肩推","手臂伸展","胸推","坐姿划船",
        "超人","太空椅深蹲","側躺抬腿","棒式","側棒式" ]
    
    static let workoutPlans = [ "上肢訓練","下肢訓練","核心訓練","全身訓練" ]
    
    // API 配置
    private let apiKey: String
    private let modelName = "gemini-2.5-flash"
    private var baseURL: String {
        return "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent"
    }
    
    init(apiKey: String = "YOUR_GEMINI_API_KEY") {
        self.apiKey = apiKey
    }
    
    // MARK: - 體態分析（圖片 + Vision 報告）
    func analyzePosture(image: UIImage, analysisReport: String) async throws -> String {
        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY" else {
            throw AIServiceError.invalidAPIKey
        }
        
        // 將圖片轉換為 Base64
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw AIServiceError.imageEncodingFailed
        }
        let base64Image = imageData.base64EncodedString()
        
        // 構建 Prompt
        let prompt = buildPostureAnalysisPrompt(analysisReport: analysisReport)
        
        // 構建請求體
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": prompt
                        ],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 4096
            ],
            "safetySettings": [
                [
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ],
                [
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_MEDIUM_AND_ABOVE"
                ]
            ]
        ]
        
        // 發送請求
        let rawResponse = try await sendRequest(body: requestBody)
        
        // 清理和格式化回應
        return cleanAndFormatResponse(rawResponse)
    }
    
    // MARK: - 文字問答
    func generateTextResponse(question: String) async throws -> String {
        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY" else {
            throw AIServiceError.invalidAPIKey
        }
        
        // 構建 Prompt
        let prompt = buildTextResponsePrompt(question: question)
        
        // 構建請求體
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": prompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1024
            ]
        ]
        
        // 發送請求
        return try await sendRequest(body: requestBody)
    }
    
    // MARK: - 私有方法
    
    /// 構建體態分析 Prompt
    private func buildPostureAnalysisPrompt(analysisReport: String) -> String {
        let exercisesList = GeminiAIService.availableExercises.joined(separator: "、")
        let plansList = GeminiAIService.workoutPlans.joined(separator: "、")
        
        return """
        你是「智能寶寶肌胸 🐥」，一個專業、友善且鼓舞人心的健身助手。
        
        ## 你的知識庫
        
        **可推薦的訓練組合（4個）：**
        \(plansList)
        
        **可推薦的單一動作（10個）：**
        \(exercisesList)
        
        ## 你的任務
        
        根據以下 Vision 系統的體態分析報告和圖片，生成一份詳細的中文體態分析報告。
        
        **Vision 分析報告：**
        \(analysisReport)
        
        ## 你的回覆要求
        
        請用清晰、專業且鼓舞人心的口吻，包含以下內容：
        
        1. **體態評估總結**
           - 用 2-3 句話簡要總結整體體態狀況
           - 強調優點和需要改善的地方
        
        2. **主要問題分析**（如果有檢測到問題）
           - 詳細說明每個檢測到的體態問題
           - 解釋可能的成因和影響
           - 如果沒有問題，簡單鼓勵繼續保持
        
        3. **🎯 推薦訓練組合**（必須包含）
           - 從 [\(plansList)] 中**精確選擇一個**最適合的訓練組合
           - 必須使用完全相同的名稱
           - 用 1-2 句話解釋為什麼推薦這個組合
           - 格式：「🎯 推薦訓練組合：[組合名稱]」
        
        4. **💪 建議自訂動作**（必須包含）
           - 從 [\(exercisesList)] 中**精確選擇 3 個**最適合的動作
           - 必須使用完全相同的動作名稱
           - 每個動作用 1 句話說明其幫助
           - 格式：
             「💪 建議自訂動作：
             1. [動作名稱] - [說明]
             2. [動作名稱] - [說明]
             3. [動作名稱] - [說明]」
        
        5. **💡 日常建議**
           - 提供 2-3 個實用的日常姿勢建議
           - 給予鼓勵和激勵
        
        ## 格式規範（重要）
        
        - 使用簡單的純文字格式，不要使用複雜的 Markdown 語法
        - 使用 emoji 作為標題符號（如 🎯 💪 💡）
        - 不要使用 ### 或 ** 等 Markdown 標記
        - 使用空行分隔段落
        - 確保推薦的組合和動作名稱與知識庫完全一致
        - 確保回覆完整，不要截斷
        - 語氣專業但親切，充滿正能量
        
        請開始你的完整分析（確保包含所有 5 個部分）：
        """
    }
    
    /// 構建文字問答 Prompt
    private func buildTextResponsePrompt(question: String) -> String {
        let exercisesList = GeminiAIService.availableExercises.joined(separator: "、")
        let plansList = GeminiAIService.workoutPlans.joined(separator: "、")
        
        return """
        你是「智能寶寶肌胸 🐥」，一個專業、友善且鼓舞人心的健身助手。
        
        ## 你的知識庫
        
        **App 提供的訓練組合：**
        \(plansList)
        
        **App 提供的單一動作：**
        \(exercisesList)
        
        ## 使用者問題
        
        \(question)
        
        ## 回覆要求
        
        - 用專業但親切的口吻回答
        - 如果問題與健身、體態、運動相關，提供專業建議
        - 如果適合，可以推薦使用 App 的功能（如上傳照片分析體態）
        - 如果推薦動作或訓練，優先推薦知識庫中的內容
        - 使用適當的 emoji 讓回覆更生動
        - 保持簡潔但資訊豐富
        
        請回答：
        """
    }
    
    /// 發送 HTTP 請求到 Gemini API
    private func sendRequest(body: [String: Any]) async throws -> String {
        // 構建 URL
        guard var urlComponents = URLComponents(string: baseURL) else {
            print("❌ [GeminiAI] 無法解析 baseURL: \(baseURL)")
            throw AIServiceError.invalidResponse
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        
        guard let url = urlComponents.url else {
            print("❌ [GeminiAI] 無法構建完整 URL")
            throw AIServiceError.invalidResponse
        }
        
        print("🌐 [GeminiAI] 請求 URL: \(url.absoluteString.replacingOccurrences(of: apiKey, with: "***API_KEY***"))")
        
        // 構建請求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30 // 30 秒超時
        
        // 序列化 JSON
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("📤 [GeminiAI] 請求體大小: \(request.httpBody?.count ?? 0) bytes")
        } catch {
            print("❌ [GeminiAI] JSON 序列化失敗: \(error)")
            throw AIServiceError.networkError(error)
        }
        
        // 發送請求
        print("⏳ [GeminiAI] 正在發送請求...")
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
            print("✅ [GeminiAI] 收到回應，數據大小: \(data.count) bytes")
        } catch {
            print("❌ [GeminiAI] 網路請求失敗: \(error)")
            print("   錯誤類型: \(type(of: error))")
            print("   錯誤描述: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("   URLError code: \(urlError.code.rawValue)")
                print("   URLError 描述: \(urlError.localizedDescription)")
            }
            throw AIServiceError.networkError(error)
        }
        
        // 檢查 HTTP 狀態碼
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ [GeminiAI] 無法解析 HTTP 回應")
            throw AIServiceError.invalidResponse
        }
        
        print("📊 [GeminiAI] HTTP 狀態碼: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            // 嘗試解析錯誤訊息
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ [GeminiAI] API 錯誤回應: \(responseString)")
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("❌ [GeminiAI] API 錯誤訊息: \(message)")
                throw AIServiceError.apiError(message)
            }
            throw AIServiceError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        // 解析回應
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ [GeminiAI] 無法解析 JSON 回應")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   原始回應: \(responseString.prefix(500))")
            }
            throw AIServiceError.invalidResponse
        }
        
        print("✅ [GeminiAI] JSON 解析成功")
        
        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            print("❌ [GeminiAI] 無法提取文字內容")
            print("   JSON 結構: \(json)")
            throw AIServiceError.invalidResponse
        }
        
        print("✅ [GeminiAI] 成功提取 AI 回應，長度: \(text.count) 字元")
        return text
    }
    
    /// 清理和格式化 AI 輸出
    private func cleanAndFormatResponse(_ text: String) -> String {
        var cleaned = text
        
        // 移除多餘的空行（保留最多 2 個連續換行）
        while cleaned.contains("\n\n\n") {
            cleaned = cleaned.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        // 清理錯誤的 Markdown 格式
        cleaned = cleaned.replacingOccurrences(of: "##＃", with: "")
        cleaned = cleaned.replacingOccurrences(of: "###", with: "")
        cleaned = cleaned.replacingOccurrences(of: "**", with: "")
        
        // 清理開頭的分隔線
        cleaned = cleaned.replacingOccurrences(of: "---\n", with: "")
        
        // 移除開頭和結尾的空白
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 確保沒有被截斷（檢查是否有結束語）
        if !cleaned.contains("💡") && !cleaned.contains("日常建議") && !cleaned.contains("保持") {
            print("⚠️ [GeminiAI] 回應可能不完整，長度: \(cleaned.count)")
        }
        
        return cleaned
    }
}

// MARK: - PostureAnalyzer 擴展：生成結構化報告
extension PostureAnalyzer {
    
    /// 生成結構化的中文體態分析報告（供 AI 使用）
    static func analyze(keypoints: PoseKeypoints) -> String {
        var report = "=== Vision 體態分析報告 ===\n\n"
        
        // 基本資訊
        report += "檢測品質：\n"
        report += "- 置信度：\(Int(keypoints.confidence * 100))%\n"
        report += "- 檢測到的關鍵點：\(keypoints.detectedPointsCount)/5 個\n\n"
        
        // 關鍵點座標
        report += "關鍵點座標（正規化，0-1）：\n"
        if let neck = keypoints.neck {
            report += "- 頸部：(\(String(format: "%.3f", neck.x)), \(String(format: "%.3f", neck.y)))\n"
        } else {
            report += "- 頸部：未檢測到\n"
        }
        if let leftShoulder = keypoints.leftShoulder {
            report += "- 左肩：(\(String(format: "%.3f", leftShoulder.x)), \(String(format: "%.3f", leftShoulder.y)))\n"
        } else {
            report += "- 左肩：未檢測到\n"
        }
        if let rightShoulder = keypoints.rightShoulder {
            report += "- 右肩：(\(String(format: "%.3f", rightShoulder.x)), \(String(format: "%.3f", rightShoulder.y)))\n"
        } else {
            report += "- 右肩：未檢測到\n"
        }
        if let leftHip = keypoints.leftHip {
            report += "- 左髖：(\(String(format: "%.3f", leftHip.x)), \(String(format: "%.3f", leftHip.y)))\n"
        } else {
            report += "- 左髖：未檢測到\n"
        }
        if let rightHip = keypoints.rightHip {
            report += "- 右髖：(\(String(format: "%.3f", rightHip.x)), \(String(format: "%.3f", rightHip.y)))\n"
        } else {
            report += "- 右髖：未檢測到\n"
        }
        report += "\n"
        
        // 檢測到的問題
        let issues = PostureAnalyzer.detectIssues(from: keypoints)
        if issues.isEmpty {
            report += "檢測結果：未發現明顯的體態問題\n"
        } else {
            report += "檢測到的體態問題：\n"
            for issue in issues {
                report += "- \(issue.description)\n"
                
                // 添加具體數據
                switch issue {
                case .shoulderImbalance:
                    if let left = keypoints.leftShoulder, let right = keypoints.rightShoulder {
                        let diff = abs(left.y - right.y)
                        report += "  高度差異：\(String(format: "%.1f", diff * 100))%\n"
                    }
                case .pelvicTilt:
                    if let left = keypoints.leftHip, let right = keypoints.rightHip {
                        let diff = abs(left.y - right.y)
                        report += "  高度差異：\(String(format: "%.1f", diff * 100))%\n"
                    }
                case .roundedShoulders:
                    report += "  肩膀相對頸部位置偏前\n"
                case .forwardHead:
                    report += "  頭部相對肩膀位置偏前\n"
                }
            }
        }
        
        report += "\n=== 報告結束 ===\n"
        
        return report
    }
}
