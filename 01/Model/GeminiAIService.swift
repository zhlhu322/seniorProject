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
    
    /// 初始化 - 優先使用傳入的 apiKey；若未提供，從 Info.plist 的 GEMINI_API_KEY 讀取；找不到時會設為空字串（會導致呼叫時拋出錯誤）
    init(apiKey: String? = nil) {
            let finalKey = apiKey ?? AppEnvironment.geminiAPIKey

            if finalKey.isEmpty {
                print("⚠️ 警告：Gemini API Key 為空，請求將會失敗")
            }
            self.apiKey = finalKey
    }
    
    // MARK: - 體態分析（圖片 + Vision 報告）
    func analyzePosture(image: UIImage, analysisReport: String) async throws -> String {
        return try await analyzePostureWithQuestion(image: image, analysisReport: analysisReport, userQuestion: nil)
    }
    
    // MARK: - 體態分析（圖片 + Vision 報告 + 使用者自訂問題）
    func analyzePostureWithQuestion(image: UIImage, analysisReport: String, userQuestion: String?) async throws -> String {
        guard !apiKey.isEmpty && apiKey != "YOUR_GEMINI_API_KEY" else {
            throw AIServiceError.invalidAPIKey
        }
        
        // 縮小圖片並轉換為 Base64
        let resizedImage = Self.resizeImageIfNeeded(image, maxDimension: 1024)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.6) else {
            throw AIServiceError.imageEncodingFailed
        }
        print("📸 [GeminiAI] 圖片大小: \(imageData.count / 1024) KB (原始: \(Int(image.size.width))x\(Int(image.size.height)) → \(Int(resizedImage.size.width))x\(Int(resizedImage.size.height)))")
        let base64Image = imageData.base64EncodedString()
        
        // 構建 Prompt（包含使用者問題）
        let prompt = buildPostureAnalysisPrompt(analysisReport: analysisReport, userQuestion: userQuestion)
        
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
                "maxOutputTokens": 8192
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
                "maxOutputTokens": 4096
            ]
        ]
        
        // 發送請求
        return try await sendRequest(body: requestBody)
    }
    
    // MARK: - 私有方法
    
    /// 構建體態分析 Prompt
    private func buildPostureAnalysisPrompt(analysisReport: String, userQuestion: String?) -> String {
        let exercisesList = GeminiAIService.availableExercises.joined(separator: "、")
        let plansList = GeminiAIService.workoutPlans.joined(separator: "、")
        
        var prompt = """
        你是「智能寶寶肌胸 🐥」，一個專業且友善的健身助手。

        可推薦的訓練組合：\(plansList)
        可推薦的動作：\(exercisesList)

        請仔細觀察使用者提供的圖片，分析以下體態細節：
        - 頭部位置：是否有前傾
        - 肩膀：是否高低不一、圓肩、聳肩
        - 脊椎：是否有駝背、側彎跡象
        - 骨盆：是否前傾或後傾
        - 整體對稱性：左右是否平衡

        以下為裝置端 Vision 輔助數據，供交叉參考（以你對圖片的觀察為主）：
        \(analysisReport)

        請用繁體中文回覆，總字數需小於 150 字，包含以下內容：

        1. 🧍 體態總結（1~2句，描述你從圖片中觀察到的整體姿勢狀況）
        2. 🔎 問題分析（針對每個發現的問題，說明觀察到什麼、可能的成因，各 1～2 句；無明顯問題則說明體態良好）
        3. 🎯 推薦訓練組合：從 [\(plansList)] 精確選一個，並簡述原因
        4. 💪 建議動作：從 [\(exercisesList)] 精確選 2 個，格式：
           1. [名稱] - [針對什麼問題、為什麼推薦]
           2. [名稱] - [針對什麼問題、為什麼推薦]
        5. 💡 日常建議（1～2 句簡短的姿勢改善提醒）

        不要使用 Markdown 標記（###、**），用 emoji 當標題，語氣親切正向。
        列點請用bullet項目符號呈現並且所有的回覆中不要提到“vision報告“
        """
        
        // 如果有使用者問題，添加到 Prompt 中
        if let question = userQuestion, !question.isEmpty {
            prompt += "\n\n## 使用者問題\n\n\(question)\n"
        }
        
        return prompt
    }
    
    /// 構建文字問答 Prompt
    private func buildTextResponsePrompt(question: String) -> String {
        let exercisesList = GeminiAIService.availableExercises.joined(separator: "、")
        let plansList = GeminiAIService.workoutPlans.joined(separator: "、")
        
        return """
        你是「智能寶寶肌胸 🐥」，一個專業且友善的健身助手。
        App 提供的訓練組合：\(plansList)
        App 提供的動作：\(exercisesList)

        使用者問題：\(question)

        請用繁體中文回答，200 字以內，語氣親切，適時使用 emoji。
        不要使用 Markdown 標記（###、**），用 emoji 當標題，語氣親切正向。
        若推薦動作或訓練，請使用知識庫中的名稱。
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
        if !cleaned.contains("💡") && !cleaned.contains("💪") && !cleaned.contains("🎯") {
            print("⚠️ [GeminiAI] 回應可能不完整，長度: \(cleaned.count)")
        }
        
        return cleaned
    }

    /// 將圖片縮小到指定最大邊長，保持比例
    private static func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let width = image.size.width
        let height = image.size.height

        guard width > maxDimension || height > maxDimension else {
            return image
        }

        let scale: CGFloat
        if width > height {
            scale = maxDimension / width
        } else {
            scale = maxDimension / height
        }

        let newSize = CGSize(width: width * scale, height: height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
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
