//
//  PostureRecordView.swift
//  01
//
//  Created by 李恩亞 on 2025/11/8.
//

import SwiftUI

// MARK: - 訊息模型
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let image: UIImage?
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, image: UIImage? = nil, isUser: Bool, timestamp: Date = Date()) {
        self.content = content
        self.image = image
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// MARK: - 體態紀錄聊天視圖
struct PostureRecordView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(
            content: "你好！我是智能寶寶肌胸 🐥\n\n你可以：\n• 上傳照片讓我分析你的體態\n• 詢問體態相關的問題\n• 獲得改善建議",
            isUser: false
        )
    ]
    @State private var inputText = ""
    @State private var showPicker = false
    @State private var pickedImage: UIImage?
    @FocusState private var isInputFocused: Bool
    
    //var analyzer: PostureAnalyzer? //姿勢分析器（未來使用）

    var body: some View {
        ZStack {
            // 背景可點擊以收起鍵盤（放在最底層不會攔截按鈕點擊）
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    // 優先使用 FocusState 失焦（純 SwiftUI）
                    isInputFocused = false
                    print("PostureRecordView: background tapped -> isInputFocused=false")
                    // 不再呼叫 UIApplication 的備援 dismiss，避免 RTI 警告
                }
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
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
                            // 補強：LazyVStack 空白處 tapped（純使用 FocusState）
                            isInputFocused = false
                            print("PostureRecordView: lazyVStack tapped -> isInputFocused=false")
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.immediately)
                    .simultaneousGesture(TapGesture().onEnded {
                        // 當使用者在 ScrollView 空白處點擊時也收鍵盤（純使用 FocusState）
                        isInputFocused = false
                        print("PostureRecordView: scrollView tapped -> isInputFocused=false")
                    })
                    .onChange(of: messages) { oldMessages, newMessages in
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
                
                // 輸入區域
                HStack(spacing: 12) {
                    // 相簿按鈕
                    Button {
                        showPicker = true
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title3)
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                    }
                    
                    TextField("輸入訊息或上傳照片...", text: $inputText)
                        .textFieldStyle(.plain)
                        .padding(10)
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
            // 開啟相簿或關閉相簿時確保鍵盤已收起
            if newValue {
                isInputFocused = false
                print("PostureRecordView: showPicker = true -> isInputFocused=false")
            }
        }
        .onChange(of: pickedImage) { oldImage, newImage in
            if let image = newImage {
                print("PostureRecordView: pickedImage changed -> handling image")
                sendImageMessage(image)
                // 清掉後續處理
                pickedImage = nil
            }
        }
    }
    
    // MARK: - 發送文字訊息
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(content: inputText, isUser: true)
        messages.append(userMessage)
        isInputFocused = false
        
        let userQuestion = inputText
        inputText = ""
        
        // 模擬 AI 回覆（未來替換為真實 API）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let aiResponse = generateMockResponse(for: userQuestion)
            messages.append(aiResponse)
        }
    }
    
    // MARK: - 發送圖片訊息
    private func sendImageMessage(_ image: UIImage) {
        let userMessage = ChatMessage(content: "請幫我分析這張照片的體態", image: image, isUser: true)
        messages.append(userMessage)
        isInputFocused = false
        
        // 模擬 AI 分析回覆（未來替換為真實 API）
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let aiResponse = ChatMessage(
                content: "我收到你的照片了！✨\n\n（AI 分析功能即將推出）\n\n未來我將能夠：\n• 識別你的姿勢和關鍵點\n• 分析體態問題\n• 提供改善建議\n• 推薦適合的運動",
                isUser: false
            )
            messages.append(aiResponse)
        }
    }
    
    // MARK: - 生成模擬回覆
    private func generateMockResponse(for question: String) -> ChatMessage {
        let lowercased = question.lowercased()
        
        var response = ""
        
        if lowercased.contains("體態") || lowercased.contains("姿勢") {
            response = "關於體態問題，建議你可以：\n\n1. 上傳一張照片讓我分析\n2. 保持良好的站姿和坐姿\n3. 定期做伸展運動\n4. 加強核心肌群訓練\n\n你可以上傳照片讓我做更詳細的分析喔！"
        } else if lowercased.contains("運動") || lowercased.contains("訓練") {
            response = "運動建議：\n\n• 每週至少 3 次運動\n• 結合有氧和重訓\n• 注意運動前後的伸展\n• 循序漸進增加強度\n\n想要更個人化的建議嗎？上傳照片讓我分析你的體態！"
        } else if lowercased.contains("照片") || lowercased.contains("上傳") {
            response = "請點擊左下角的照片按鈕 📷 上傳你的照片，我會幫你分析體態並提供建議！"
        } else {
            response = "我收到你的問題了！\n\n目前 AI 功能還在開發中，但你可以：\n• 上傳照片記錄體態變化\n• 詢問體態、運動相關問題\n\n未來我會提供更智能的分析和建議 🤖"
        }
        
        return ChatMessage(content: response, isUser: false)
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
