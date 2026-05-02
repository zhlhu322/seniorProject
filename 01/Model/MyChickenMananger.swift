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
    @Published var Stage: String = ""
    
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
                self?.Stage = data["Stage"] as? String ?? ""
                
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
                "Style": self.style,
                "Stage": self.Stage
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

    func deductAminoCoin(amount: Int, completion: @escaping (Error?) -> Void) {
        guard amount > 0 else {
            completion(nil)
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "MyChicken", code: -1, userInfo: [NSLocalizedDescriptionKey: "使用者未登入"]))
            return
        }

        let chickenRef = db.collection("users").document(userId).collection("MyChicken")

        chickenRef.getDocuments { [weak self] snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(error)
                }
                return
            }

            guard let self, let document = snapshot?.documents.first else {
                DispatchQueue.main.async {
                    completion(NSError(domain: "MyChicken", code: -2, userInfo: [NSLocalizedDescriptionKey: "找不到小雞資料"]))
                }
                return
            }

            let documentRef = chickenRef.document(document.documentID)
            var updatedCoin = 0

            self.db.runTransaction({ transaction, errorPointer in
                do {
                    let snapshot = try transaction.getDocument(documentRef)
                    let currentCoin = snapshot.data()?["AminoCoin"] as? Int ?? 0

                    guard currentCoin >= amount else {
                        errorPointer?.pointee = NSError(
                            domain: "MyChicken",
                            code: -3,
                            userInfo: [NSLocalizedDescriptionKey: "AminoCoin 不足"]
                        )
                        return nil
                    }

                    updatedCoin = currentCoin - amount
                    transaction.updateData(["AminoCoin": updatedCoin], forDocument: documentRef)
                    return nil
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
            }) { _, error in
                DispatchQueue.main.async {
                    if let error {
                        completion(error)
                    } else {
                        self.aminoCoin = updatedCoin
                        completion(nil)
                    }
                }
            }
        }
    }

    func purchaseItem(amount: Int, category: StoreItemCategory, itemKey: String, completion: @escaping (Error?) -> Void) {
        guard amount > 0 else {
            completion(nil)
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "MyChicken", code: -1, userInfo: [NSLocalizedDescriptionKey: "使用者未登入"]))
            return
        }

        let chickenRef = db.collection("users").document(userId).collection("MyChicken")

        chickenRef.getDocuments { [weak self] snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(error)
                }
                return
            }

            guard let self, let document = snapshot?.documents.first else {
                DispatchQueue.main.async {
                    completion(NSError(domain: "MyChicken", code: -2, userInfo: [NSLocalizedDescriptionKey: "找不到小雞資料"]))
                }
                return
            }

            let documentRef = chickenRef.document(document.documentID)
            var updatedCoin = 0
            var updatedFlavoring = self.flavoring
            var updatedStyle = self.style

            self.db.runTransaction({ transaction, errorPointer in
                do {
                    let snapshot = try transaction.getDocument(documentRef)
                    let data = snapshot.data() ?? [:]
                    let currentCoin = data["AminoCoin"] as? Int ?? 0

                    guard currentCoin >= amount else {
                        errorPointer?.pointee = NSError(
                            domain: "MyChicken",
                            code: -3,
                            userInfo: [NSLocalizedDescriptionKey: "AminoCoin 不足"]
                        )
                        return nil
                    }

                    updatedCoin = currentCoin - amount

                    var updateData: [String: Any] = [
                        "AminoCoin": updatedCoin
                    ]

                    switch category {
                    case .flavoring:
                        let flavoringMap = data["Flavoring"] as? [String: Int] ?? [:]
                        let newCount = (flavoringMap[itemKey] ?? 0) + 1
                        updatedFlavoring = flavoringMap
                        updatedFlavoring[itemKey] = newCount
                        updateData["Flavoring.\(itemKey)"] = newCount
                    case .style:
                        let styleMap = data["Style"] as? [String: Any] ?? [:]
                        let currentCount = styleMap[itemKey] as? Int ?? 0
                        let newCount = currentCount + 1
                        updatedStyle = styleMap
                        updatedStyle[itemKey] = newCount
                        updateData["Style.\(itemKey)"] = newCount
                    }

                    transaction.updateData(updateData, forDocument: documentRef)
                    return nil
                } catch let error as NSError {
                    errorPointer?.pointee = error
                    return nil
                }
            }) { _, error in
                DispatchQueue.main.async {
                    if let error {
                        completion(error)
                    } else {
                        self.aminoCoin = updatedCoin
                        self.flavoring = updatedFlavoring
                        self.style = updatedStyle
                        completion(nil)
                    }
                }
            }
        }
    }

    func updateCurrentStyle(_ newStyle: Style, completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "MyChicken", code: -1, userInfo: [NSLocalizedDescriptionKey: "使用者未登入"]))
            return
        }

        if newStyle != .idle {
            let ownedCount = style[newStyle.rawValue] as? Int ?? 0
            guard ownedCount > 0 else {
                completion(NSError(domain: "MyChicken", code: -4, userInfo: [NSLocalizedDescriptionKey: "尚未擁有這個造型"]))
                return
            }
        }

        let chickenRef = db.collection("users").document(userId).collection("MyChicken")

        chickenRef.getDocuments { [weak self] snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(error)
                }
                return
            }

            guard let self, let document = snapshot?.documents.first else {
                DispatchQueue.main.async {
                    completion(NSError(domain: "MyChicken", code: -2, userInfo: [NSLocalizedDescriptionKey: "找不到小雞資料"]))
                }
                return
            }

            let documentRef = chickenRef.document(document.documentID)

            documentRef.updateData(["Style.currently": newStyle.rawValue]) { error in
                DispatchQueue.main.async {
                    if let error {
                        completion(error)
                    } else {
                        self.style["currently"] = newStyle.rawValue
                        completion(nil)
                    }
                }
            }
        }
    }
}

enum StoreItemCategory {
    case flavoring
    case style
}

enum Stage: String {
    case baby
    case healthy
}

enum Style: String {
    case idle
    case banana
    case roast
    case spicy
}

final class AnimationManager {
    static let shared = AnimationManager()

    private init() {}

    private let animationURLMap: [String: String] = [
        "baby_idle": "https://firebasestorage.googleapis.com/v0/b/countbuddy-app.firebasestorage.app/o/Stage%2Fbaby_idle.json?alt=media&token=2636bbab-0463-45e4-9a8b-c5e6eff87570",
        "baby_banana": "https://firebasestorage.googleapis.com/v0/b/countbuddy-app.firebasestorage.app/o/Stage%2Fbaby_banana.json?alt=media&token=845cbf33-2797-44cc-bc5e-90060d1a19ef",
        "baby_roast": "https://firebasestorage.googleapis.com/v0/b/countbuddy-app.firebasestorage.app/o/Stage%2Fbaby_roast.json?alt=media&token=21c111b9-82ec-4d38-a5b4-3888ad6279da",
        "baby_spicy":"https://firebasestorage.googleapis.com/v0/b/countbuddy-app.firebasestorage.app/o/Stage%2Fbaby_spicy.json?alt=media&token=642ee7fe-e5e5-44c2-9bfb-dd1f0180c74f",
        "baby_vanilla": "",
        "healthy_idle": "https://firebasestorage.googleapis.com/v0/b/countbuddy-app.firebasestorage.app/o/Stage%2Fhealthy_idle.json?alt=media&token=ca12cdff-f480-46f4-b333-7916b2882aeb",
        "healthy_banana":"https://firebasestorage.googleapis.com/v0/b/countbuddy-app.firebasestorage.app/o/Stage%2Fhealthy_banana.json?alt=media&token=b116b84a-63c4-4507-be05-2aeabf3d8b53",
        "healthy_roast": "https://firebasestorage.googleapis.com/v0/b/countbuddy-app.firebasestorage.app/o/Stage%2Fhealthy_roast.json?alt=media&token=833f50a8-33aa-4721-8a39-e6b78b831fd0",
        "healthy_spicy": "",
        "healthy_vanilla":""
    ]

    private func getStage(xp: Int) -> Stage {
        xp < 10 ? .baby : .healthy
    }

    func getAnimationURL(xp: Int, style: Style) -> String? {
        let stage = getStage(xp: xp)
        let key = "\(stage.rawValue)_\(style.rawValue)"

        if let url = animationURLMap[key] {
            return url
        }

        let fallbackKey = "\(stage.rawValue)_\(Style.idle.rawValue)"
        return animationURLMap[fallbackKey]
    }
}
