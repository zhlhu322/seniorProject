//
//  UserView.swift
//  01
//
//  Created by 李恩亞 on 2025/10/20.
//

import SwiftUI

enum UserRoute: Hashable {
    case monthlySports
    case bodyRecord
    case userWorkoutsHistory
}

struct MenuRowButton: View {
    let iconName: String
    let title: String
    let action: () -> Void // 按下按鈕時要執行的動作
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: iconName)
                    .foregroundStyle(Color(.black).opacity(0.5))
                    .frame(width: 20)
                Text(title)
                Spacer()
            }
        }
        .padding()
        .frame(width: 350, height: 64)
        .background(Color(.myMint).opacity(0.5))
        .cornerRadius(16)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.black), style: StrokeStyle(lineWidth: 1))
        }
        .foregroundColor(.black)
    }
}

struct UserView: View {
    @ObservedObject var authVM = AuthenticationViewModel.shared
    @State private var path: [UserRoute] = []
    @Binding var selectedTab: AppTab  // ✅ 接收來自 MainTabView 的 selectedTab binding
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing:0) {
                ZStack(alignment: .bottom) {
                    Color(.darkBackground)
                        .ignoresSafeArea(edges: .top)
                    VStack(alignment: .center){
                        Image("avatar")
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: 80, height: 80)
                        Text(authVM.isLoggedIn ? authVM.currentUserName : "未登入")
                            .font(.title3)
                            .foregroundColor(.background)
                        if authVM.isLoggedIn {
                            Text(authVM.currentUserEmail)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.bottom,20)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                
                
                HStack(spacing:15){
                    StatsCardView(iconName: "timer", value: "5小時24分", label:    "運動時數")
                    StatsCardView(iconName: "flame", value: "12天", label: "連續紀錄")
                    StatsCardView(iconName: "dumbbell", value: "30次", label:    "完成訓練")
                }
                .padding(.horizontal,15)
                .padding(.vertical,40)
                
                VStack(spacing:20){
                    MenuRowButton(iconName: "calendar", title: "本月運動") {
                        if authVM.isLoggedIn {
                            path.append(.monthlySports)
                        }else{
                            //提示需要登入
                        }
                    }
                    MenuRowButton(iconName: "chart.xyaxis.line", title: "體態紀錄") {
                        //體態紀錄
                    }
                    MenuRowButton(iconName: "rectangle.portrait.and.arrow.right", title: "登出") {
                        authVM.signOut()
                        // ✅ 登出後會自動切換到主頁 tab（由 MainTabView 的 onChange 處理）
                    }
                }
                Spacer()
            }
            .background(Color(.background).ignoresSafeArea())
            .navigationDestination(for: UserRoute.self) { route in
                switch route {
                case .monthlySports:
                    MonthlySportsView()
                case .bodyRecord:
                    Text("體態紀錄頁面")
                case .userWorkoutsHistory:
                    Text("運動歷史頁面")
                }
            }
        }
    }
}

//#Preview("已登入狀態") {
//    UserView()
//        .onAppear {
//            // 在 View 出現時，設定 ViewModel 的假資料
//            let vm = AuthenticationViewModel.shared
//            vm.isLoggedIn = true
//            vm.currentUserName = "測試使用者"
//            vm.currentUserEmail = "preview-user@example.com"
//        }
//}
//
//#Preview("未登入狀態") {
//    UserView()
//        .onAppear {
//            // 在 View 出現時，將 ViewModel 恢復為登出狀態
//            let vm = AuthenticationViewModel.shared
//            vm.isLoggedIn = false
//            vm.currentUserName = ""
//            vm.currentUserEmail = ""
//        }
//}
