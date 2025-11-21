//
//  PostureRecordView.swift
//  01
//
//  Created by 李恩亞 on 2025/11/8.
//

import SwiftUI
import FirebaseFirestore

// MARK: - 訊息模型
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let content: String
    let image: UIImage?
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, image: UIImage? = nil, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.image = image
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// MARK: - 體態紀錄聊天視圖
struct PostureRecordView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var showPicker = false
    @State private var pickedImage: UIImage?
    @FocusState private var isInputFocused: Bool
    @State private var isAnalyzing = false
    @State private var isLoading = false
    @State private var isLoadingHistory = true
    
    // 姿勢分析+AI服務
    private let analyzer = PostureAnalyzer()
    private let aiService = GeminiAIService(apiKey: "AIzaSyAlk0JM6RVK_pR3KtrtQhlm7HZ589IBg1I")
    private let chatHistoryManager = ChatHistoryManager.shared

    var body: some View {
        ZStack {
            // 背景可點擊以收起鍵盤（放在最底層）
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isInputFocused = false
                    print("PostureRecordView: background tapped -> isInputFocused=false")
                    }
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 載入指示器
                if isLoadingHistory {
                    HStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("載入歷史記錄...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                }
                
                if isLoading {
                    HStack {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("AI 分析中...")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(.myMint).opacity(0.3))
                }
                
                // 聊天記錄區域
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .onTapGesture {
                            isInputFocused = false }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .simultaneousGesture(TapGesture().onEnded {
                        isInputFocused = false
                        print("PostureRecordView: scrollView tapped -> isInputFocused=false")
                    })
                    .onChange(of: messages) { _ , newMessages in
                        // 當 messages 陣列改變時捲動到底部
                        if let lastMessage = newMessages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color(.background))
                
                Divider()
                
                // 使用者輸入區域
                HStack(spacing: 12) {
                    // 相簿按鈕
                    Button {
                        showPicker = true
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                            .foregroundColor(Color(.darkBackground))
                            .frame(width: 40, height: 40)
                    }
                    
                    TextField("輸入訊息或上傳照片...", text: $inputText)
                        .textFieldStyle(.plain)
                        .padding(20)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(inputText.isEmpty ? .gray : Color(.accent))
                    }
                    .disabled(inputText.isEmpty)
                }
                .padding()
                .background(Color(.myMint))
            }
        }
        .navigationTitle("體態紀錄")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPicker) {
            ImagePicker(image: $pickedImage, sourceType: .photoLibrary)
        }
        .onChange(of: showPicker) { oldValue, newValue in
            if newValue {
                isInputFocused = false }
        }
        .onChange(of: pickedImage) { oldImage, newImage in
            if let image = newImage {
                print("PostureRecordView: pickedImage changed -> handling image")
                sendImageMessage(image)
                pickedImage = nil // 清掉後續處理
            }
        }
        .onAppear {
            loadChatHistory()
        }
    }
    
    // MARK: - 載入聊天記錄
    private func loadChatHistory() {
        print("📥 [PostureRecord] 開始載入聊天記錄...")
        isLoadingHistory = true
        
        chatHistoryManager.loadMessages { loadedMessages in
            DispatchQueue.main.async {
                if loadedMessages.isEmpty {
                    // 如果沒有歷史記錄，顯示歡迎訊息
                    let welcomeMessage = ChatMessage(
                        content: "你好！我是智能寶寶肌胸 🐥\n\n你可以：\n• 上傳照片讓我分析你的體態\n• 詢問體態相關的問題\n• 獲得改善建議",
                        isUser: false
                    )
                    messages = [welcomeMessage]
                    // 儲存歡迎訊息
                    chatHistoryManager.saveMessage(welcomeMessage)
                    print("✅ [PostureRecord] 已顯示歡迎訊息")
                } else {
                    messages = loadedMessages
                    print("✅ [PostureRecord] 載入了 \(loadedMessages.count) 筆歷史記錄")
                }
                isLoadingHistory = false
            }
        }
    }
    
    // MARK: - 發送文字訊息
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: inputText, isUser: true)
        messages.append(userMessage)
        // 儲存使用者訊息到 Firestore
        chatHistoryManager.saveMessage(userMessage)

        let userQuestion = inputText
        inputText = ""
        
        // 顯示載入狀態
        isLoading = true
        
        // 使用 Gemini AI 生成回覆
        Task {
            do {
                let aiResponse = try await aiService.generateTextResponse(question: userQuestion)
                
                await MainActor.run {
                    let responseMessage = ChatMessage(content: aiResponse, isUser: false)
                    messages.append(responseMessage)
                    // 儲存 AI 回覆到 Firestore
                    chatHistoryManager.saveMessage(responseMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = "😔 抱歉，我現在遇到了一些問題：\(error.localizedDescription)\n\n請稍後再試，或上傳照片讓我分析體態！"
                    let responseMessage = ChatMessage(content: errorMessage, isUser: false)
                    messages.append(responseMessage)
                    // 儲存錯誤訊息到 Firestore
                    chatHistoryManager.saveMessage(responseMessage)
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - 發送圖片訊息
    private func sendImageMessage(_ image: UIImage) {
        let userMessage = ChatMessage(content: "請幫我分析這張照片的體態", image: image, isUser: true)
        messages.append(userMessage)
        // 儲存使用者訊息（含圖片）到 Firestore
        chatHistoryManager.saveMessage(userMessage)
        
        isInputFocused = false
        
        // 顯示分析中訊息
        isLoading = true
        let analyzingMessage = ChatMessage(content: "🔍 正在分析，請稍候...", isUser: false)
        messages.append(analyzingMessage)
        // 儲存分析中訊息
        chatHistoryManager.saveMessage(analyzingMessage)
        
        print("📸 [PostureRecord] 開始分析圖片")
        Task {
            do {
                // 步驟 1: 使用 Vision Framework 提取關鍵點
                print("🔍 [PostureRecord] 步驟 1: 使用 Vision Framework 分析...")
                let keypoints = try await analyzePostureAsync(image: image)
                print("✅ [PostureRecord] Vision 分析完成，檢測到 \(keypoints.detectedPointsCount) 個關鍵點")
                
                // 步驟 2: 生成 Vision 分析報告
                print("📝 [PostureRecord] 步驟 2: 生成分析報告...")
                let visionReport = PostureAnalyzer.analyze(keypoints: keypoints)
                print("✅ [PostureRecord] 報告生成完成，長度: \(visionReport.count) 字元")
                
                // 步驟 3: 使用 Gemini AI 生成詳細分析
                print("🤖 [PostureRecord] 步驟 3: 呼叫 Gemini AI...")
                let aiResponse = try await aiService.analyzePosture(
                    image: image,
                    analysisReport: visionReport
                )
                print("✅ [PostureRecord] AI 分析完成")
                
                // 更新 UI
                await MainActor.run {
                    // 移除「分析中」訊息
                    if let lastMessage = messages.last, lastMessage.content.contains("正在分析") {
                        messages.removeLast()
                        // 也從 Firestore 刪除（可選）
                    }
                    
                    // 顯示 AI 分析結果
                    let responseMessage = ChatMessage(content: aiResponse, isUser: false)
                    messages.append(responseMessage)
                    // 儲存 AI 分析結果到 Firestore
                    chatHistoryManager.saveMessage(responseMessage)
                    
                    isLoading = false
                }
                
            } catch {
                // 處理錯誤
                print("❌ [PostureRecord] 分析失敗: \(error)")
                print("   錯誤類型: \(type(of: error))")
                print("   錯誤描述: \(error.localizedDescription)")
                
                if let aiError = error as? AIServiceError {
                    print("   AIServiceError 詳細: \(aiError)")
                }
                
                await MainActor.run {
                    // 移除「分析中」訊息
                    if let lastMessage = messages.last, lastMessage.content.contains("正在分析") {
                        messages.removeLast()
                    }
                    
                    let errorMessage = formatErrorResponse(error)
                    let errorResponse = ChatMessage(content: errorMessage, isUser: false)
                    messages.append(errorResponse)
                    // 儲存錯誤訊息到 Firestore
                    chatHistoryManager.saveMessage(errorResponse)
                    
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - 異步版本的姿勢分析
    private func analyzePostureAsync(image: UIImage) async throws -> PoseKeypoints {
        return try await withCheckedThrowingContinuation { continuation in
            analyzer.analyzePosture(image: image) { result in
                switch result {
                case .success(let keypoints):
                    continuation.resume(returning: keypoints)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - 格式化錯誤訊息
    private func formatErrorResponse(_ error: Error) -> String {
        var response = "😔 分析遇到問題\n\n"
        
        // 檢查是否是 AI 服務錯誤
        if let aiError = error as? AIServiceError {
            response += "🔍 錯誤類型：AIServiceError\n"
            response += "📋 詳細訊息：\(aiError.localizedDescription)\n\n"
            
            switch aiError {
            case .invalidAPIKey:
                response += "💡 解決方法：\n"
                response += "• API Key 可能無效或過期\n"
                response += "• 請檢查 Google AI Studio 中的 API Key\n"
                response += "• 確認 API Key 已正確配置"
                
            case .networkError(let innerError):
                response += "💡 網路錯誤詳細：\n"
                response += "• 錯誤類型：\(type(of: innerError))\n"
                response += "• 錯誤描述：\(innerError.localizedDescription)\n\n"
                response += "可能的原因：\n"
                response += "• 網路連線不穩定\n"
                response += "• 防火牆或 VPN 阻擋\n"
                response += "• App Transport Security 設定問題\n\n"
                response += "💡 建議：\n"
                response += "• 檢查網路連線\n"
                response += "• 嘗試切換 Wi-Fi/行動網路\n"
                response += "• 關閉 VPN 重試"
                
            case .apiError(let message):
                response += "💡 API 錯誤訊息：\n"
                response += "\(message)\n\n"
                response += "可能的原因：\n"
                response += "• API 端點 URL 不正確\n"
                response += "• API Key 權限不足\n"
                response += "• 請求格式錯誤\n"
                response += "• 超過 API 配額限制"
                
            case .imageEncodingFailed:
                response += "💡 建議：\n"
                response += "• 請嘗試選擇其他照片\n"
                response += "• 確保照片格式正確（JPG/PNG）\n"
                response += "• 照片大小不要超過 5MB"
                
            case .invalidResponse:
                response += "💡 建議：\n"
                response += "• API 回應格式異常\n"
                response += "• 請稍後再試\n"
                response += "• 如果問題持續，請聯繫開發團隊"
            }
            
        } else if let poseError = error as? PoseAnalysisError {
            response += "🔍 錯誤類型：PoseAnalysisError\n"
            response += "📋 詳細訊息：\(poseError.localizedDescription)\n\n"
            
            switch poseError {
            case .noPersonDetected:
                response += "💡 建議：\n"
                response += "• 確保照片中有完整的人體\n"
                response += "• 使用光線充足的環境拍攝\n"
                response += "• 保持適當的拍攝距離\n"
                response += "• 建議站姿為正面或側面全身照"
                
            case .insufficientKeypoints:
                response += "💡 建議：\n"
                response += "• 確保肩膀和髖部清晰可見\n"
                response += "• 避免穿著過於寬鬆的衣物\n"
                response += "• 選擇乾淨的背景"
                
            case .imageConversionFailed:
                response += "💡 建議：\n"
                response += "• 請嘗試重新上傳照片\n"
                response += "• 確保照片格式正確"
                
            case .visionRequestFailed(let innerError):
                response += "💡 Vision Framework 錯誤：\n"
                response += "• \(innerError.localizedDescription)\n"
                response += "• 請稍後再試"
            }
            
        } else {
            // 其他未知錯誤
            response += "🔍 錯誤類型：\(type(of: error))\n"
            response += "📋 錯誤描述：\(error.localizedDescription)\n\n"
            response += "💡 建議：\n"
            response += "• 請查看 Xcode Console 中的詳細日誌\n"
            response += "• 嘗試重啟 App\n"
            response += "• 如果問題持續，請聯繫開發團隊"
        }
        
        response += "\n\n📱 請查看 Xcode Console 獲取更多技術細節"
        
        return response
    }
}

// MARK: - 訊息氣泡
struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
                // 顯示圖片（如果有）
                if let image = message.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: 200, maxHeight: 300)
                        .padding()
                        .background(Color(.myMint).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                
                // 顯示文字
                if !message.content.isEmpty {
                    Text(message.content)
                        .padding(12)
                        .background(message.isUser ? Color(.myMint): Color(.white))
                        .foregroundColor(message.isUser ? .white : .black)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )

                }
                
                // 時間戳記
                Text(formatTime(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !message.isUser { Spacer(minLength: 60) }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        PostureRecordView()
    }
}
