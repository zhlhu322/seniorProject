//
//  _1App.swift
//  01
//
//  Created by 李恩亞 on 2025/4/5.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        FirebaseApp.configure()
        
        // ✅ 控制是否強制登出（僅限開發或除錯用途）
        let shouldForceLogout = false  // ⚠️ 記得上線時改成 false
        
        if shouldForceLogout {
            do {
                try Auth.auth().signOut()
                print("已強制登出 Firebase 使用者")
            } catch let signOutError as NSError {
                print("登出失敗: \(signOutError.localizedDescription)")
            }
        }
        
        return true
    }
}

@main
struct _1App: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
