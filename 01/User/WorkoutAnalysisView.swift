//
//  WorkoutAnalysisView.swift
//  01
//
//  Created by 李恩亞 on 2026/04/12.
//  運動分析主頁面，以 Segmented Picker 切換三個圖表 tab

import SwiftUI

enum AnalysisTab: String, CaseIterable, Hashable {
    case monthlyHours = "本月時數"
    case consecutive  = "連續紀錄"
    case weeklyCount  = "每週訓練"
}

struct WorkoutAnalysisView: View {
    let initialTab: AnalysisTab
    @State private var selectedTab: AnalysisTab
    @StateObject private var historyManager = WorkoutHistoryManager.shared

    init(initialTab: AnalysisTab = .monthlyHours) {
        self.initialTab = initialTab
        self._selectedTab = State(initialValue: initialTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(AnalysisTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(.background))

            TabView(selection: $selectedTab) {
                // Tab 1：本月時數折線圖
                MonthlyHoursTab()
                    .tag(AnalysisTab.monthlyHours)

                // Tab 2：連續天數日曆
                ConsecutiveDaysTab()
                    .tag(AnalysisTab.consecutive)

                // Tab 3：每週訓練次數長條圖（使用原本的 WeeklyWorkoutChartView）
                WeeklyWorkoutChartView()
                    .tag(AnalysisTab.weeklyCount)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.2), value: selectedTab)
        }
        .background(Color(.background))
        .navigationTitle("運動分析")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let components = Calendar.current.dateComponents([.year, .month], from: Date())
            if let year = components.year, let month = components.month {
                historyManager.loadMonthlyWorkouts(year: year, month: month)
            }
            historyManager.loadRecentWorkouts(limit: 30)
            historyManager.loadLastMonthWorkouts()
            applyNavBarStyle()
        }
    }

    private func applyNavBarStyle() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "DarkBackgroundColor")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    NavigationStack {
        WorkoutAnalysisView(initialTab: .monthlyHours)
            .onAppear {
                WorkoutHistoryManager.shared.loadMockData()
                AuthenticationViewModel.shared.loginAsMockUser()
            }
    }
}
