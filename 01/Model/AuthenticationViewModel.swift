//
//  AuthenticationViewModel.swift
//  01
//
//  Created by 李恩亞 on 2025/7/27.
//

import SwiftUI
import Foundation
import Firebase
import FirebaseCore
import FirebaseAuth
import FirebaseStorage

enum AuthErrorCodeFriendly: Equatable {
    case emailAlreadyInUse
    case invalidEmail
    case weakPassword
    case unknown(String)
}

class AuthenticationViewModel: ObservableObject {
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUserName: String = ""
    @Published var currentUserEmail: String = ""
    @Published var avatarImage: UIImage? = nil
    static let shared = AuthenticationViewModel()
    
    static var isRunningForPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
        
    private init() {
        // 只有在不是 Preview 的時候，才執行 Firebase 的連線和資料讀取
        if !AuthenticationViewModel.isRunningForPreview {
            self.isLoggedIn = Auth.auth().currentUser != nil
            if isLoggedIn {
                loadUserData()
                WorkoutHistoryManager.shared.preloadCurrentMonth()
            }
        }
    }

    func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ 無法取得使用者 UID")
            return
        }

        // 先從本地快取載入頭像，讓 UI 立即顯示
        if let cached = loadCachedAvatar(uid: uid) {
            DispatchQueue.main.async { self.avatarImage = cached }
        }

        // 直接讀 Firestore，Firebase SDK 自動管理 token，不需要手動 force refresh
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let error = error {
                let nsError = error as NSError
                print("❌ 載入使用者資料失敗，錯誤碼: \(nsError.code)，\(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data() else {
                print("⚠️ 文件存在但無資料，UID: \(uid)")
                return
            }
            DispatchQueue.main.async {
                self.currentUserName = data["name"] as? String ?? ""
                self.currentUserEmail = data["email"] as? String ?? ""
                print("✅ 使用者資料載入成功: \(self.currentUserName)")
            }
            // 頭像：只在 URL 有變動時才重新下載
            if let avatarURL = data["avatarURL"] as? String, let url = URL(string: avatarURL) {
                let cachedKey = "avatarURL_\(uid)"
                let lastURL = UserDefaults.standard.string(forKey: cachedKey)
                if lastURL != avatarURL {
                    // URL 有變動才下載
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data, let image = UIImage(data: data) {
                            self.saveAvatarToCache(uid: uid, data: data)
                            UserDefaults.standard.set(avatarURL, forKey: cachedKey)
                            DispatchQueue.main.async { self.avatarImage = image }
                        }
                    }.resume()
                }
            }
        }
    }

    // MARK: - 頭像本地快取
    private func avatarCacheURL(uid: String) -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("avatar_\(uid).jpg")
    }

    private func loadCachedAvatar(uid: String) -> UIImage? {
        let url = avatarCacheURL(uid: uid)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private func saveAvatarToCache(uid: String, data: Data) {
        let url = avatarCacheURL(uid: uid)
        try? data.write(to: url, options: .atomic)
    }

    //建立使用者,改成回傳 (friendlyCode, message)
    func createUser(name: String, email: String, password: String, completion: @escaping (AuthErrorCodeFriendly?, String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                // 先判斷是否為 Auth 錯誤
                if let authCode = AuthErrorCode(rawValue: error.code) {
                    switch authCode {
                    case .emailAlreadyInUse:
                        completion(.emailAlreadyInUse, "信箱已被使用，請改用登入或使用其他信箱。")
                        return
                    case .invalidEmail:
                        completion(.invalidEmail, "無效的電子郵件格式")
                        return
                    case .weakPassword:
                        completion(.weakPassword, "密碼強度不足（至少 6 字元）")
                        return
                    default:
                        completion(.unknown(error.localizedDescription), "註冊失敗：\(error.localizedDescription)")
                        return
                    }
                } else {
                    completion(.unknown(error.localizedDescription), "註冊失敗：\(error.localizedDescription)")
                    return
                }
            }
            guard let user = result?.user else {
                completion(.unknown("no_user"), "無法取得使用者資訊")
                return
            }
            
            // 內部函式：寫入 user document，遇到 permission related error 時可重試
            func writeUserDoc(attemptsLeft: Int) {
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "uid": user.uid,
                    "name": name,
                    "email": email,
                    "createdAt": Timestamp()
                ]) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            let msg = error.localizedDescription
                            // 顯示 NSError 詳細資訊，方便排查 permission vs network 等
                            if let ns = error as NSError? {
                                print("❌ Firestore write NSError: domain=\(ns.domain) code=\(ns.code) userInfo=\(ns.userInfo) (attemptsLeft=\(attemptsLeft))")
                            }
                            print("❌ Firestore write error: \(msg) (attemptsLeft=\(attemptsLeft))")
                            
                            // 如果錯誤訊息包含 permission 關鍵字，嘗試刷新 token 並重試（最多 3 次）
                            let lower = msg.lowercased()
                            if attemptsLeft > 0 && (lower.contains("permission") || lower.contains("permission denied") || lower.contains("insufficient")) {
                                print("🔁 檢測到 permission error，嘗試刷新 ID token 並重試...")
                                Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { idToken, tokenError in
                                    if let tokenError = tokenError {
                                        print("⚠️ token refresh failed during retry: \(tokenError.localizedDescription)")
                                    } else {
                                        print("✅ token refreshed (retry) for user: \(user.uid)")
                                    }
                                    // 短延遲後重試，避免 race condition
                                    DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                                        writeUserDoc(attemptsLeft: attemptsLeft - 1)
                                    }
                                }
                            } else {
                                completion(.unknown(msg), "註冊失敗：\(msg)")
                            }
                        } else {
                            // ✅ 建立 MyChicken 子 collection
                            let chickenRef = db.collection("users").document(user.uid).collection("MyChicken").document()
                            
                            let chickenData: [String: Any] = [
                                                            "AminoCoin": 0,
                                                            "Endurance": 0,
                                                            "Flexibility": 0,
                                                            "XP": 0,
                                                            "Strength": 0,
                                                            "Flavoring": [
                                                                "currently" : "original",
                                                                "original": 1,
                                                                "vanilla" : 0,
                                                                "spicy" : 0
                                                            ],
                                                            "Style": [
                                                                "currently" : "idle",
                                                                "idle": 1,
                                                                "banana": 0,
                                                                "roast": 0
                                                            ]
                                                        ]
                            
                            chickenRef.setData(chickenData) { chickenError in
                                DispatchQueue.main.async {
                                    if let chickenError = chickenError {
                                        print("⚠️ 建立小雞資料失敗：\(chickenError.localizedDescription)")
                                        // 小雞建立失敗不影響註冊流程
                                    } else {
                                        print("🐔 小雞資料已建立，ID：\(chickenRef.documentID)")
                                    }
                                    
                                    self.isLoggedIn = true
                                    completion(nil, nil)
                                    print("🎉 使用者已註冊並登入 UID：\(user.uid)")
                                }
                            }
                        }
                    }
                }
            }
            
            // 首次在寫入前嘗試刷新 token（增加成功率）
            Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { idToken, tokenError in
                if let tokenError = tokenError {
                    print("⚠️ ID token refresh error: \(tokenError.localizedDescription) - 仍會嘗試寫入 Firestore，若被拒則回傳錯誤。")
                } else {
                    print("✅ ID token refreshed for user: \(user.uid)")
                }
                // 開始寫入，最多嘗試 3 次
                writeUserDoc(attemptsLeft: 3)
            }
        }
    }
    
    //選擇角色
    func updateUserRole(roleID: Int) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ 無法取得使用者 UID")
            return
        }
        
        // 同理：在進行 update 前可以刷新 token（選擇性）
        Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { idToken, tokenError in
            if let tokenError = tokenError {
                print("⚠️ ID token refresh error before updateUserRole: \(tokenError.localizedDescription)")
            }
            
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(uid)
            
            userRef.updateData([
                "roleID": roleID
            ]) { error in
                if let error = error {
                    if let ns = error as NSError? {
                        print("❌ updateUserRole NSError: domain=\(ns.domain) code=\(ns.code) userInfo=\(ns.userInfo)")
                    }
                    print("❌ 儲存角色失敗：\(error.localizedDescription)")
                } else {
                    print("✅ 角色儲存成功！選擇角色 ID：\(roleID)")
                }
            }
        }
    }

    func updateInitialChickenSelection(roleID: Int, stage: String, completion: @escaping (String?) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion("無法取得使用者 UID")
            return
        }

        Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { _, tokenError in
            if let tokenError = tokenError {
                print("⚠️ ID token refresh error before updateInitialChickenSelection: \(tokenError.localizedDescription)")
            }

            let db = Firestore.firestore()
            let userRef = db.collection("users").document(uid)
            let chickenRef = userRef.collection("MyChicken")

            userRef.updateData([
                "roleID": roleID
            ]) { userError in
                if let userError = userError {
                    if let ns = userError as NSError? {
                        print("❌ updateInitialChickenSelection user NSError: domain=\(ns.domain) code=\(ns.code) userInfo=\(ns.userInfo)")
                    }
                    DispatchQueue.main.async {
                        completion("儲存角色失敗：\(userError.localizedDescription)")
                    }
                    return
                }

                chickenRef.getDocuments { snapshot, chickenFetchError in
                    if let chickenFetchError = chickenFetchError {
                        DispatchQueue.main.async {
                            completion("讀取小雞資料失敗：\(chickenFetchError.localizedDescription)")
                        }
                        return
                    }

                    guard let document = snapshot?.documents.first else {
                        DispatchQueue.main.async {
                            completion("找不到小雞資料")
                        }
                        return
                    }

                    chickenRef.document(document.documentID).updateData([
                        "Stage": stage
                    ]) { stageError in
                        DispatchQueue.main.async {
                            if let stageError = stageError {
                                if let ns = stageError as NSError? {
                                    print("❌ updateInitialChickenSelection stage NSError: domain=\(ns.domain) code=\(ns.code) userInfo=\(ns.userInfo)")
                                }
                                completion("儲存小雞階段失敗：\(stageError.localizedDescription)")
                            } else {
                                MyChickenManager.shared.Stage = stage
                                print("✅ 初始小雞選擇已儲存，roleID：\(roleID), stage：\(stage)")
                                completion(nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 登入
    func signIn(email: String, password: String, completion: @escaping (AuthErrorCodeFriendly?, String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error as NSError? {
                if let authCode = AuthErrorCode(rawValue: error.code) {
                    switch authCode {
                    case .userNotFound:
                        completion(.unknown("user_not_found"), "使用者不存在，請先註冊。")
                        return
                    case .wrongPassword:
                        completion(.unknown("wrong_password"), "密碼錯誤，請重新輸入或使用忘記密碼。")
                        return
                    case .invalidEmail:
                        completion(.invalidEmail, "無效的電子郵件格式")
                        return
                    default:
                        completion(.unknown(error.localizedDescription), "登入失敗：\(error.localizedDescription)")
                        return
                    }
                } else {
                    completion(.unknown(error.localizedDescription), "登入失敗：\(error.localizedDescription)")
                    return
                }
            }
            // 登入成功
            DispatchQueue.main.async {
                self.isLoggedIn = true
                self.loadUserData()
                WorkoutHistoryManager.shared.preloadCurrentMonth()
                completion(nil, nil)
            }
        }
    }
    
    func uploadAvatar(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ 頭像上傳失敗：無法取得使用者 UID")
            completion(false)
            return
        }
        let resized = Self.resizeImage(image, maxDimension: 512)
        guard let data = resized.jpegData(compressionQuality: 0.7) else {
            print("❌ 頭像上傳失敗：圖片編碼失敗")
            completion(false)
            return
        }
        print("📸 [Avatar] 上傳大小: \(data.count / 1024) KB (原始: \(Int(image.size.width))x\(Int(image.size.height)) → \(Int(resized.size.width))x\(Int(resized.size.height)))")
        let ref = Storage.storage().reference().child("avatars/\(uid).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        ref.putData(data, metadata: metadata) { _, error in
            if let error = error {
                print("❌ 頭像上傳失敗：\(error.localizedDescription)")
                completion(false)
                return
            }
            ref.downloadURL { url, error in
                guard let url = url else {
                    print("❌ 取得頭像 URL 失敗：\(error?.localizedDescription ?? "")")
                    completion(false)
                    return
                }
                let db = Firestore.firestore()
                db.collection("users").document(uid).updateData(["avatarURL": url.absoluteString]) { error in
                    DispatchQueue.main.async {
                        if let error = error {
                            print("❌ 儲存頭像 URL 失敗：\(error.localizedDescription)")
                            completion(false)
                        } else {
                            // 上傳成功後同步更新本地快取和 URL 記錄
                            self.saveAvatarToCache(uid: uid, data: data)
                            UserDefaults.standard.set(url.absoluteString, forKey: "avatarURL_\(uid)")
                            print("✅ 頭像已上傳並儲存")
                            completion(true)
                        }
                    }
                }
            }
        }
    }

    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        guard width > maxDimension || height > maxDimension else { return image }
        let scale = width > height ? maxDimension / width : maxDimension / height
        let newSize = CGSize(width: width * scale, height: height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func signOut() {
        if let uid = Auth.auth().currentUser?.uid {
            UserDefaults.standard.removeObject(forKey: "avatarURL_\(uid)")
        }
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isLoggedIn = false
                self.currentUserName = ""
                self.currentUserEmail = ""
                self.avatarImage = nil
            }
            print("✅ 登出成功")
        } catch let signOutError as NSError {
            print("❌ 登出失敗: \(signOutError.localizedDescription)")
        }
    }
}
