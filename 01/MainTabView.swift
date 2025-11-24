//
//  MainTabView.swift
//  01
//
//  Created by 李恩亞 on 2025/10/20.
//
import SwiftUI

enum AppTab {
    case home, user, shop
}

struct MainTabView: View {
    @State private var selectedTab: AppTab = .home
    @State private var planPath: [PlanRoute] = []
    @State private var userPath: [UserRoute] = []
    @ObservedObject var authVM = AuthenticationViewModel.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 商店 tab
            NavigationStack {
                MyChickenMeatView()
                    .toolbar(.visible, for: .tabBar) // 商店 root 固定顯示
            }
            .tabItem {
                Label {
                    Text("我的肌胸肉")
                } icon: {
                    Image(selectedTab == .shop ? "MyChicken" : "MyChicken_unselected")
                        .renderingMode(.original)
                }
            }
            .tag(AppTab.shop)
            
            // 主頁 tab - 根據登入狀態顯示 IntroView 或 HomeView
            NavigationStack(path: $planPath) {
                Group {
                    if authVM.isLoggedIn {
                        HomeView(path: $planPath)
                    } else {
                        IntroView(path: $planPath)
                    }
                }
                .navigationDestination(for: PlanRoute.self) { route in
                    print("🧭 導航到: \(route)")
                    return destinationView(for: route)
                }
            }
            // 將 tab bar 可見性附加在 NavigationStack 層級，立即生效
            .toolbar(planPath.isEmpty ? .visible : .hidden, for: .tabBar)
            .animation(.easeInOut(duration: 0.1), value: planPath.isEmpty)
            .tabItem {
                Label("主頁", systemImage: "house.fill")
            }
            .tag(AppTab.home)
            .onChange(of: authVM.isLoggedIn) { oldValue, newValue in
                print("🔄 登入狀態改變: \(oldValue) -> \(newValue)")
                planPath = []
            }
            .onChange(of: planPath) { oldValue, newValue in
                if !newValue.isEmpty {
                    print("   最新路由: \(newValue.last!)")
                }
            }
            
             // 使用者 tab
             NavigationStack(path: $userPath) {
                UserView(selectedTab: $selectedTab, path: $userPath)
                    .navigationDestination(for: UserRoute.self) { route in
                        switch route {
                        case .monthlySports:
                            MonthlySportsView()
                        case .bodyRecord:
                            PostureRecordView()
                        case .userWorkoutsHistory:
                            UserWorkoutsHistoryView()
                        }
                    }
             }
             // 將 tab bar 可見性附加在 NavigationStack 層級，立即生效
             .toolbar(userPath.isEmpty ? .visible : .hidden, for: .tabBar)
             .animation(.easeInOut(duration: 0.2), value: userPath.isEmpty)
             .tabItem {
                 Label("使用者", systemImage: "person.fill")
             }
             .tag(AppTab.user)
        }
        // 移除 TabView 層級的全域 toolbar 設定，改為由各 NavigationStack / root view 控制
         .onChange(of: authVM.isLoggedIn) { oldValue, newValue in
             // ✅ 登出時自動切換到主頁 tab（顯示 IntroView）
             if !newValue {
                 selectedTab = .home
                 planPath = []
             }
         }
    }
    
    // 根據路由決定顯示的 View
    @ViewBuilder
    private func destinationView(for route: PlanRoute) -> some View {
        switch route {
        case .signUp:
            signUpView(path: $planPath)
        case .signUp2:
            signUpView2(path: $planPath)
        case .signIn:
            signInView(path: $planPath)
        case .home:
            HomeView(path: $planPath)
        case .choosePlan:
            workoutPlanTypeView(path: $planPath)
        case .recPlan:
            recPlanView(path: $planPath)
        case .cusPlan:
            cusPlanView(path: $planPath)
        case .cusPlan_edit(let selectedExerciseIDs):
            cusPlan_edit(path: $planPath, selectedExerciseIDs: selectedExerciseIDs)
        case .planInfo(let plan):
            planInfoView(plan: plan, path: $planPath)
        case .blePairing(let plan):
            blePairingView(path: $planPath, plan: plan)
                .environmentObject(BluetoothManager())
        case .workout(let plan, let exerciseIndex, let setIndex):
            workoutView(path: $planPath, plan: plan, exerciseIndex: exerciseIndex, setIndex: setIndex)
                .environmentObject(BluetoothManager())
        case .workoutTiming(let plan, let exerciseIndex, let setIndex):
            workoutTimingView(path: $planPath, plan: plan, exerciseIndex: exerciseIndex, setIndex: setIndex)
                .environmentObject(BluetoothManager())
        case .rest(let plan, let exerciseIndex, let setIndex):
            restView(path: $planPath, plan: plan, exerciseIndex: exerciseIndex, setIndex: setIndex)
                .environmentObject(BluetoothManager())
        case .workoutComplete(let plan):
            WorkoutCompleteView(path: $planPath, plan: plan)
        case .levelup(let plan):
            LevelUpView(path: $planPath, plan: plan)
        case .exerciseDetail(let exercise):
            exerciseDetailView(detail: exercise)
        }
    }
}
