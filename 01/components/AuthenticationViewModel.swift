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

class AuthenticationViewModel: ObservableObject {
    
    @Published var isLoggedIn: Bool = false
    static let shared = AuthenticationViewModel()
    
        
        private init() {
            self.isLoggedIn = Auth.auth().currentUser != nil
        }
        //建立使用者
        func createUser(name: String, email: String, password: String, completion: @escaping (String?) -> Void) {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    completion("註冊失敗：\(error.localizedDescription)")
                    return
                }
                
                guard let user = result?.user else {
                    completion("無法取得使用者資訊")
                    return
                }
                
                let db = Firestore.firestore()
                db.collection("users").document(user.uid).setData([
                    "uid": user.uid,
                    "name": name,
                    "email": email,
                    "createdAt": Timestamp()
                ]) { error in
                    if let error = error {
                        completion("註冊失敗：\(error.localizedDescription)")
                    } else {
                        self.isLoggedIn = true
                        completion(nil) // nil 表示成功
                        print("🎉 使用者已註冊並登入 UID：\(user.uid)")
                    }
                }
            }
            

        }
    
    //選擇角色
    func updateUserRole(roleID: Int) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("⚠️ 無法取得使用者 UID")
            return
        }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        userRef.updateData([
            "roleID": roleID
        ]) { error in
            if let error = error {
                print("❌ 儲存角色失敗：\(error.localizedDescription)")
            } else {
                print("✅ 角色儲存成功！選擇角色 ID：\(roleID)")
            }
        }
    }
    
}


