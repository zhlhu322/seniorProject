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
    case weeklyChart
    case workoutAnalysis(AnalysisTab)
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
        .background(Color("MyMint").opacity(0.5))
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
    @ObservedObject var historyManager = WorkoutHistoryManager.shared
    @Binding var selectedTab: AppTab
    @Binding var path: [UserRoute]

    @State private var showImagePicker = false
    @State private var pickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage? = nil
    @State private var isUploadingAvatar = false

    func handleImagePickerDismiss() {
        if let img = selectedImage {
            authVM.avatarImage = img   // 立即更新畫面
            isUploadingAvatar = true
            authVM.uploadAvatar(img) { _ in
                isUploadingAvatar = false
            }
            selectedImage = nil
        }
    }

    // 格式化運動時間（秒 -> 小時分鐘）
    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)小時\(minutes)分"
        } else {
            return "\(minutes)分鐘"
        }
    }

    var body: some View {
        VStack(spacing:0) {
                ZStack(alignment: .bottom) {
                    Color(.darkBackground)
                        .ignoresSafeArea(edges: .top)
                    VStack(alignment: .center){
                        Menu {
                            Button {
                                pickerSourceType = .photoLibrary
                                showImagePicker = true
                            } label: {
                                Label("從相簿選擇", systemImage: "photo.on.rectangle")
                            }
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                Button {
                                    pickerSourceType = .camera
                                    showImagePicker = true
                                } label: {
                                    Label("拍照", systemImage: "camera")
                                }
                            }
                        } label: {
                            ZStack(alignment: .bottomTrailing) {
                                Group {
                                    if let img = authVM.avatarImage {
                                        Image(uiImage: img)
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .clipShape(Circle())
                                    } else {
                                        Image("avatar")
                                            .resizable()
                                            .clipShape(Circle())
                                    }
                                }
                                .frame(width: 80, height: 80)
                                if isUploadingAvatar {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .background(Color.black.opacity(0.4).clipShape(Circle()))
                                        .frame(width: 80, height: 80)
                                }
                                if authVM.isLoggedIn {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .padding(5)
                                        .background(Color(.darkBackground))
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color(.background), lineWidth: 1.5))
                                }
                            }
                        }
                        .disabled(!authVM.isLoggedIn)

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
                    Button {
                        if authVM.isLoggedIn {
                            path.append(.workoutAnalysis(.monthlyHours))
                        }
                    } label: {
                        StatsCardView(
                            iconName: "timer",
                            value: authVM.isLoggedIn ? formatDuration(historyManager.getMonthlyWorkoutTime()) : "0分鐘",
                            label: "運動時數"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button {
                        if authVM.isLoggedIn {
                            path.append(.workoutAnalysis(.consecutive))
                        }
                    } label: {
                        StatsCardView(
                            iconName: "flame",
                            value: authVM.isLoggedIn ? "\(historyManager.getConsecutiveDays())天" : "0天",
                            label: "連續紀錄"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button {
                        if authVM.isLoggedIn {
                            path.append(.workoutAnalysis(.weeklyCount))
                        }
                    } label: {
                        StatsCardView(
                            iconName: "dumbbell",
                            value: authVM.isLoggedIn ? "\(historyManager.getMonthlyWorkoutCount())次" : "0次",
                            label: "完成訓練"
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal,15)
                .padding(.vertical,40)
                .onAppear {
                    if authVM.isLoggedIn {
                        // 載入運動統計資料
                        historyManager.loadRecentWorkouts(limit: 30)
                        let components = Calendar.current.dateComponents([.year, .month], from: Date())
                        if let year = components.year, let month = components.month {
                            historyManager.loadMonthlyWorkouts(year: year, month: month)
                        }
                    }
                }
                
                VStack(spacing:20){
                    MenuRowButton(iconName: "calendar", title: "本月運動") {
                        if authVM.isLoggedIn {
                            path.append(.monthlySports)
                        }else{
                            //提示需要登入
                        }
                    }
                    MenuRowButton(iconName: "chart.xyaxis.line", title: "體態紀錄") {
                        if authVM.isLoggedIn {
                            path.append(.bodyRecord)
                        }
                    }
                    MenuRowButton(iconName: "rectangle.portrait.and.arrow.right", title: "登出") {
                        authVM.signOut()
                        // ✅ 登出後會自動切換到主頁 tab（由 MainTabView 的 onChange 處理）
                    }
                }
                Spacer()
            }
            .background(Color(.background).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            // 相簿：用 sheet
            .sheet(isPresented: Binding(
                get: { showImagePicker && pickerSourceType == .photoLibrary },
                set: { if !$0 { showImagePicker = false } }
            ), onDismiss: handleImagePickerDismiss) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            // 相機：必須用 fullScreenCover，否則 iOS 會 crash
            .fullScreenCover(isPresented: Binding(
                get: { showImagePicker && pickerSourceType == .camera },
                set: { if !$0 { showImagePicker = false } }
            ), onDismiss: handleImagePickerDismiss) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
                    .ignoresSafeArea()
            }
    }
}

#Preview("已登入狀態") {
    UserView(selectedTab: .constant(.user), path: .constant([]))
        .onAppear {
            AuthenticationViewModel.shared.loginAsMockUser()
            WorkoutHistoryManager.shared.loadMockData()
        }
}

#Preview("未登入狀態") {
    UserView(selectedTab:.constant(.user), path: .constant([]))
        .onAppear {
            let vm = AuthenticationViewModel.shared
            vm.isLoggedIn = false
            vm.currentUserName = ""
            vm.currentUserEmail = ""
        }
}
