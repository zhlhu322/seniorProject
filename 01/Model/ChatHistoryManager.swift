//
//  ChatHistoryManager.swift
//  01
//
//  Created by AI Assistant on 2025/11/13.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import UIKit

/// 聊天記錄管理器 - 負責 Firestore 的讀寫
class ChatHistoryManager {
    static let shared = ChatHistoryManager()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Firestore 路徑
    /// 獲取當前使用者的聊天記錄集合路徑
    private func getChatCollectionRef() -> CollectionReference? {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ [ChatHistory] 無法獲取使用者 ID")
            return nil
        }
        return db.collection("users").document(userId).collection("postureChats")
    }
    
    // MARK: - 儲存訊息
    /// 儲存單一聊天訊息到 Firestore
    func saveMessage(_ message: ChatMessage) {
        guard let chatRef = getChatCollectionRef() else { return }
        
        var messageData: [String: Any] = [
            "id": message.id.uuidString,
            "content": message.content,
            "isUser": message.isUser,
            "timestamp": Timestamp(date: message.timestamp)
        ]
        
        // 如果有圖片，轉換為 Base64 儲存
        if let image = message.image,
           let imageData = image.jpegData(compressionQuality: 0.5) {
            let base64String = imageData.base64EncodedString()
            messageData["imageBase64"] = base64String
            print("💾 [ChatHistory] 儲存訊息（含圖片，大小: \(imageData.count) bytes）")
        } else {
            print("💾 [ChatHistory] 儲存訊息（純文字）")
        }
        
        chatRef.document(message.id.uuidString).setData(messageData) { error in
            if let error = error {
                print("❌ [ChatHistory] 儲存失敗: \(error.localizedDescription)")
            } else {
                print("✅ [ChatHistory] 訊息已儲存到 Firestore")
            }
        }
    }
    
    // MARK: - 載入歷史記錄
    /// 載入所有歷史聊天記錄
    func loadMessages(completion: @escaping ([ChatMessage]) -> Void) {
        guard let chatRef = getChatCollectionRef() else {
            completion([])
            return
        }
        
        print("📥 [ChatHistory] 開始載入歷史記錄...")
        
        chatRef
            .order(by: "timestamp", descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ [ChatHistory] 載入失敗: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ [ChatHistory] 沒有歷史記錄")
                    completion([])
                    return
                }
                
                print("📥 [ChatHistory] 找到 \(documents.count) 筆歷史記錄")
                
                var messages: [ChatMessage] = []
                
                for document in documents {
                    let data = document.data()
                    
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let content = data["content"] as? String,
                          let isUser = data["isUser"] as? Bool,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        print("⚠️ [ChatHistory] 跳過無效的訊息資料")
                        continue
                    }
                    
                    // 解碼圖片（如果有）
                    var image: UIImage?
                    if let base64String = data["imageBase64"] as? String,
                       let imageData = Data(base64Encoded: base64String) {
                        image = UIImage(data: imageData)
                        print("🖼️ [ChatHistory] 成功解碼圖片")
                    }
                    
                    let message = ChatMessage(
                        id: id,
                        content: content,
                        image: image,
                        isUser: isUser,
                        timestamp: timestamp.dateValue()
                    )
                    
                    messages.append(message)
                }
                
                print("✅ [ChatHistory] 成功載入 \(messages.count) 筆訊息")
                completion(messages)
            }
    }
    
    // MARK: - 載入最近 N 筆訊息
    /// 載入最近的 N 筆訊息（用於分頁載入）
    func loadRecentMessages(limit: Int = 20, completion: @escaping ([ChatMessage]) -> Void) {
        guard let chatRef = getChatCollectionRef() else {
            completion([])
            return
        }
        
        print("📥 [ChatHistory] 載入最近 \(limit) 筆訊息...")
        
        chatRef
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ [ChatHistory] 載入失敗: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ [ChatHistory] 沒有歷史記錄")
                    completion([])
                    return
                }
                
                print("📥 [ChatHistory] 找到 \(documents.count) 筆最近訊息")
                
                var messages: [ChatMessage] = []
                
                for document in documents {
                    let data = document.data()
                    
                    guard let idString = data["id"] as? String,
                          let id = UUID(uuidString: idString),
                          let content = data["content"] as? String,
                          let isUser = data["isUser"] as? Bool,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        continue
                    }
                    
                    var image: UIImage?
                    if let base64String = data["imageBase64"] as? String,
                       let imageData = Data(base64Encoded: base64String) {
                        image = UIImage(data: imageData)
                    }
                    
                    let message = ChatMessage(
                        id: id,
                        content: content,
                        image: image,
                        isUser: isUser,
                        timestamp: timestamp.dateValue()
                    )
                    
                    messages.append(message)
                }
                
                // 反轉順序（因為我們用 descending 查詢）
                messages.reverse()
                
                print("✅ [ChatHistory] 成功載入 \(messages.count) 筆最近訊息")
                completion(messages)
            }
    }
    
    // MARK: - 刪除所有記錄
    /// 刪除當前使用者的所有聊天記錄（開發用）
    func deleteAllMessages(completion: @escaping (Bool) -> Void) {
        guard let chatRef = getChatCollectionRef() else {
            completion(false)
            return
        }
        
        print("🗑️ [ChatHistory] 開始刪除所有記錄...")
        
        chatRef.getDocuments { snapshot, error in
            if let error = error {
                print("❌ [ChatHistory] 刪除失敗: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(true)
                return
            }
            
            let batch = self.db.batch()
            documents.forEach { batch.deleteDocument($0.reference) }
            
            batch.commit { error in
                if let error = error {
                    print("❌ [ChatHistory] 批次刪除失敗: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ [ChatHistory] 已刪除 \(documents.count) 筆記錄")
                    completion(true)
                }
            }
        }
    }
}
