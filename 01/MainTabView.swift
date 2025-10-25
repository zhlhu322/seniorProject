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
    @ObservedObject var authVM = AuthenticationViewModel.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 商店 tab
            NavigationStack {
                Text("my muscle")
            }
            .tabItem {
                Label("商店", systemImage: "cart.fill")
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
            .tabItem {
                Label("主頁", systemImage: "house.fill")
            }
            .tag(AppTab.home)
            .onChange(of: authVM.isLoggedIn) { oldValue, newValue in
                print("🔄 登入狀態改變: \(oldValue) -> \(newValue)")
                planPath = []
            }
            .onChange(of: planPath) { oldValue, newValue in
                print("📍 Path 改變: count \(oldValue.count) -> \(newValue.count)")
                if !newValue.isEmpty {
                    print("   最新路由: \(newValue.last!)")
                }
            }
            
            // 使用者 tab
            NavigationStack {
                UserView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("使用者", systemImage: "person.fill")
            }
            .tag(AppTab.user)
        }
        .onChange(of: authVM.isLoggedIn) { oldValue, newValue in
            // ✅ 登出時自動切換到主頁 tab（顯示 IntroView）
            if !newValue {
                selectedTab = .home
                planPath = []
            }
        }
    }
    
    // 根據路由決定顯示的 View 和是否隱藏 tab bar
    @ViewBuilder
    private func destinationView(for route: PlanRoute) -> some View {
        switch route {
        case .signUp:
            signUpView(path: $planPath)
                .toolbar(.hidden, for: .tabBar)
        case .signUp2:
            signUpView2(path: $planPath)
                .toolbar(.hidden, for: .tabBar)
        case .signIn:
            signInView(path: $planPath)
                .toolbar(.hidden, for: .tabBar)
        case .home:
            HomeView(path: $planPath)
        case .choosePlan:
            workoutPlanTypeView(path: $planPath)
                .toolbar(.hidden, for: .tabBar)
        case .recPlan:
            recPlanView(path: $planPath)
                .toolbar(.hidden, for: .tabBar)
        case .cusPlan:
            cusPlanView(path: $planPath)
                .toolbar(.hidden, for: .tabBar)
        case .cusPlan_edit(let selectedExerciseIDs):
            cusPlan_edit(path: $planPath, selectedExerciseIDs: selectedExerciseIDs)
                .toolbar(.hidden, for: .tabBar)
        case .planInfo(let plan):
            planInfoView(plan: plan, path: $planPath)
                .toolbar(.hidden, for: .tabBar)
        case .blePairing(let plan):
            blePairingView(path: $planPath, plan: plan)
                .environmentObject(BluetoothManager())
                .toolbar(.hidden, for: .tabBar)
        case .workout(let plan, let exerciseIndex, let setIndex):
            workoutView(path: $planPath, plan: plan, exerciseIndex: exerciseIndex, setIndex: setIndex)
                .environmentObject(BluetoothManager())
                .toolbar(.hidden, for: .tabBar)
        case .rest(let plan, let exerciseIndex, let setIndex):
            restView(path: $planPath, plan: plan, exerciseIndex: exerciseIndex, setIndex: setIndex)
                .environmentObject(BluetoothManager())
                .toolbar(.hidden, for: .tabBar)
        case .workoutComplete(let plan):
            WorkoutCompleteView(path: $planPath, plan: plan)
                .toolbar(.hidden, for: .tabBar)
        case .levelup:
            LevelUpView(path: $planPath)
                .toolbar(.hidden, for: .tabBar)
        case .exerciseDetail(let exercise):
            exerciseDetailView(detail: exercise)
                .toolbar(.hidden, for: .tabBar)
        }
    }
}
