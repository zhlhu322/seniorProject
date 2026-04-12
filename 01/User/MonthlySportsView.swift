//
//  MonthlySportsView.swift
//  01
//
//  Created by 李恩亞 on 2025/10/22.
//

import SwiftUI

struct MonthlySportsView: View {
    @State private var currentDate = Date()
    @State private var workoutDates: Set<Date> = []
    @State private var path: [UserRoute] = []
    @StateObject private var historyManager = WorkoutHistoryManager.shared
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["日", "一", "二", "三", "四", "五", "六"]
    
    var body: some View {
        VStack(spacing: 20) {
            VStack{
                // 標題列：年月 + 左右箭頭
                HStack {
                    Text(monthYearString)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.darkBackground))
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(Color(.darkBackground))
                        }
                        Button(action: nextMonth) {
                            Image(systemName:"chevron.right")
                                .font(.title3)
                                .foregroundColor(Color(.darkBackground))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // 星期標題
                HStack(spacing: 0) {
                    ForEach(daysOfWeek, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(.darkBackground).opacity(0.6))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)

                // 日曆格子
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                    ForEach(daysInMonth, id: \.self) { date in
                        if let date = date {
                            DayCell(
                                date: date,
                                isWorkoutDay: isWorkoutDay(date),
                                isToday: calendar.isDateInToday(date)
                            )
                        } else {
                        // 空白格子（月份開始前的空白）
                            Color.clear
                                .frame(height: 40)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(Color(.white))

            // MARK: - 近期紀錄區域
            VStack(spacing: 12) {
                HStack {
                    Text("近期紀錄")
                        .font(.headline)
                        .foregroundColor(Color(.darkBackground))
                    Spacer()
                    NavigationLink(value: UserRoute.userWorkoutsHistory) {
                        HStack(spacing: 4) {
                            Text("查看全部")
                                .font(.caption)
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                        }
                        .foregroundColor(Color(.primary))
                    }
                }
                .padding(.horizontal, 20)
                
                // 顯示最近3筆運動記錄
                if recentThreeWorkouts.isEmpty {
                    // 空狀態
                    VStack(spacing: 10) {
                        Image(systemName: "figure.walk.circle")
                            .font(.system(size: 40))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("還沒有運動記錄")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(Color(.white))
                    .cornerRadius(16)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.black).opacity(0.1), style: StrokeStyle(lineWidth: 1))
                    }
                    .padding(.horizontal, 15)
                } else {
                    ForEach(recentThreeWorkouts) { workout in
                        NavigationLink(value: UserRoute.userWorkoutsHistory) {
                            RecentWorkoutRow(workout: workout)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.bottom, 10)
            
            Spacer()
        }
        .background(Color(.background))
        .navigationTitle("本月運動")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            #if DEBUG
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("➕ 加入測試資料") {
                        addTestData()
                    }
                    Button("🗑️ 清除測試資料", role: .destructive) {
                        clearTestData()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.white)
                }
            }
            #endif
        }
        .navigationDestination(for: UserRoute.self) { route in
            switch route {
            case .userWorkoutsHistory:
                UserWorkoutsHistoryView()
            case .monthlySports:
                MonthlySportsView()
            case .bodyRecord:
                EmptyView() // 如果有身體記錄頁面，可以在這裡添加
            case .weeklyChart:
                WeeklyWorkoutChartView()
            case .workoutAnalysis(let tab):
                WorkoutAnalysisView(initialTab: tab)
            }
        }
        .onAppear {
            loadWorkoutDates()
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(named: "DarkBackgroundColor")
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
    
    // MARK: - 計算屬性
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentDate)
    }
    
    /// 取得最近3筆運動記錄
    private var recentThreeWorkouts: [WorkoutHistory] {
        return historyManager.recentWorkouts.prefix(3).map { $0 }
    }
    
    /// 取得當月所有日期（包含前面的空白）
    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday else {
            return []
        }
        
        var days: [Date?] = []
        
        // 月份開始前的空白格子
        let emptyDays = (firstWeekday - 1) % 7
        days.append(contentsOf: Array(repeating: nil, count: emptyDays))
        
        // 月份中的所有日期
        var currentDay = monthInterval.start
        while currentDay < monthInterval.end {
            days.append(currentDay)
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDay) else { break }
            currentDay = nextDay
        }
        
        return days
    }
    
    // MARK: - 方法
    
    /// 切換到上一月
    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
            loadWorkoutDates()
        }
    }
    /// 切換到下一月
    private func nextMonth() {
        if let newDate = calendar.date(byAdding: .month, value: 1, to: currentDate) {
            currentDate = newDate
            loadWorkoutDates()
        }
    }
    /// 判斷某日期是否有運動
    private func isWorkoutDay(_ date: Date) -> Bool {
        let startOfDay = calendar.startOfDay(for: date)
        return workoutDates.contains(startOfDay)
    }
    
    /// 載入有運動的日期（從 Firestore）
    private func loadWorkoutDates() {
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        guard let year = components.year, let month = components.month else { return }
        
        // 從 Firestore 載入該月的運動記錄
        historyManager.loadMonthlyWorkouts(year: year, month: month)
        
        // 載入最近3筆運動記錄（用於近期紀錄區域）
        historyManager.loadRecentWorkouts(limit: 3)
        
        // 延遲一下讓資料載入完成後更新 UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.workoutDates = historyManager.getWorkoutDates()
        }
    }
    
    // MARK: - 測試資料方法
    #if DEBUG
    /// 加入測試資料
    private func addTestData() {
        print("🔄 開始加入測試資料...")
        TestDataHelper.shared.addTestWorkoutData { success in
            if success {
                print("✅ 測試資料加入成功！")
                // 重新載入資料
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.loadWorkoutDates()
                }
            } else {
                print("❌ 測試資料加入失敗")
            }
        }
    }
    
    /// 清除測試資料
    private func clearTestData() {
        print("🔄 開始清除測試資料...")
        TestDataHelper.shared.clearAllTestData { success in
            if success {
                print("✅ 測試資料已清除！")
                // 重新載入資料
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.loadWorkoutDates()
                }
            } else {
                print("❌ 清除測試資料失敗")
            }
        }
    }
    #endif
}

// MARK: - 日期格子 View
struct DayCell: View {
    let date: Date
    let isWorkoutDay: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    isWorkoutDay
                        ? Color(.primary)
                        : Color.gray.opacity(0.08)
                )
            Text("\(calendar.component(.day, from: date))")
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isWorkoutDay ? .white : Color(.darkBackground))
        }
        .frame(height: 36)
    }
}

// MARK: - 近期運動記錄行 View
struct RecentWorkoutRow: View {
    let workout: WorkoutHistory
    private let calendar = Calendar.current
    
    var body: some View {
        HStack(spacing: 15) {
            // 日期標記
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.primary))
                VStack(spacing: 2) {
                    Text(formatDate(workout.completedAt.dateValue()))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                .foregroundColor(.white)
                .padding(6)
            }
            .frame(width: 50, height: 50)
            
            // 運動資訊
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.planName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(.darkBackground))
                Text(formatDuration(workout.totalDuration))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // 箭頭
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(.darkBackground).opacity(0.5))
        }
        .padding()
        .frame(height: 64)
        .background(Color(.white))
        .cornerRadius(16)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.black).opacity(0.1), style: StrokeStyle(lineWidth: 1))
        }
        .padding(.horizontal, 15)
    }
    
    // MARK: - 輔助方法
    
    /// 格式化日期為月/日格式
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
    
    /// 格式化運動時長
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)分鐘"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)小時"
            }
            return "\(hours)小時\(remainingMinutes)分"
        }
    }
}

#Preview {
    NavigationStack {
        MonthlySportsView()
    }
}
