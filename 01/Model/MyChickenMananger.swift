//
//  MyChickenMananger.swift
//  01
//
//  Created by 李橋亞 on 2025/5/2.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class MyChickenManager: ObservableObject {
    static let shared = MyChickenManager()
    
    @Published var aminoCoin: Int = 0
    @Published var endurance: Int = 0
    @Published var flexibility: Int = 0
    @Published var xp: Int = 0
    @Published var strength: Int = 0
    @Published var flavoring: [String: Int] = [:]
    @Published var style: [String: Any] = [:]
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - 載入小雞資料
    func loadChickenData(completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "MyChicken", code: -1, userInfo: [NSLocalizedDescriptionKey: "使用者未登入"]))
            return
        }
        
        let chickenRef = db.collection("users").document(userId).collection("MyChicken")
        
        chickenRef.getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ 載入小雞資料失敗: \(error.localizedDescription)")
                    completion(error)
                    return
                }
                
                guard let documents = snapshot?.documents, let document = documents.first else {
                    print("⚠️ 找不到小雞資料")
                    completion(NSError(domain: "MyChicken", code: -2, userInfo: [NSLocalizedDescriptionKey: "找不到小雞資料"]))
                    return
                }
                
                let data = document.data()
                self?.aminoCoin = data["AminoCoin"] as? Int ?? 0
                self?.endurance = data["Endurance"] as? Int ?? 0
                self?.flexibility = data["Flexibility"] as? Int ?? 0
                self?.xp = data["XP"] as? Int ?? 0
                self?.strength = data["Strength"] as? Int ?? 0
                self?.flavoring = data["Flavoring"] as? [String: Int] ?? [:]
                self?.style = data["Style"] as? [String: Any] ?? [:]
                
                print("✅ 小雞資料已載入")
                completion(nil)
            }
        }
    }
    
    // MARK: - 更新小雞資料
    func updateChickenData(completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "MyChicken", code: -1, userInfo: [NSLocalizedDescriptionKey: "使用者未登入"]))
            return
        }
        
        let chickenRef = db.collection("users").document(userId).collection("MyChicken")
        
        chickenRef.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(error)
                return
            }
            
            guard let documents = snapshot?.documents, let documentId = documents.first?.documentID else {
                completion(NSError(domain: "MyChicken", code: -2, userInfo: [NSLocalizedDescriptionKey: "找不到小雞資料"]))
                return
            }
            
            let updateData: [String: Any] = [
                "AminoCoin": self.aminoCoin,
                "Endurance": self.endurance,
                "Flexibility": self.flexibility,
                "XP": self.xp,
                "Strength": self.strength,
                "Flavoring": self.flavoring,
                "Style": self.style
            ]
            
            chickenRef.document(documentId).updateData(updateData) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ 更新小雞資料失敗: \(error.localizedDescription)")
                        completion(error)
                    } else {
                        print("✅ 小雞資料已更新")
                        completion(nil)
                    }
                }
            }
        }
    }
}

