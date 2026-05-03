//
//  ConsecutiveDaysTab.swift
//  01
//
//  Created by 李恩亞 on 2026/04/12.
//  運動分析頁面 Tab 2：本月連續天數與運動日曆

import SwiftUI

struct ConsecutiveDaysTab: View {
    @ObservedObject private var historyManager = WorkoutHistoryManager.shared
    @State private var displayedDate: Date = Date()
    @State private var cachedWorkoutDays: Set<Int> = []
    @State private var cachedStreak: Int = 0
    private let calendar = Calendar.current

    // 只建立一次，避免每次 render 重新 alloc
    private static let longFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "yyyy年M月"
        return f
    }()
    private static let shortFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "yyyy/M"
        return f
    }()

    private var displayedYear: Int { calendar.component(.year, from: displayedDate) }
    private var displayedMonth: Int { calendar.component(.month, from: displayedDate) }

    private var isCurrentMonth: Bool {
        calendar.isDate(displayedDate, equalTo: Date(), toGranularity: .month)
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: displayedDate)?.count ?? 30
    }

    private var firstWeekdayOffset: Int {
        var comps = calendar.dateComponents([.year, .month], from: displayedDate)
        comps.day = 1
        guard let firstDay = calendar.date(from: comps),
              let weekday = calendar.dateComponents([.weekday], from: firstDay).weekday else { return 0 }
        return (weekday - 1) % 7
    }

    private var currentMonthString: String { Self.longFormatter.string(from: displayedDate) }
    private var shortMonthString: String { Self.shortFormatter.string(from: displayedDate) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                streakCard
                calendarCard
                comparisonCard
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.background))
        .onAppear {
            loadData()
            recomputeCache(from: historyManager.monthlyWorkouts)
        }
        .onChange(of: historyManager.monthlyWorkouts) { _, workouts in
            recomputeCache(from: workouts)
        }
    }

    // MARK: - 與上月比較摘要卡片
    private var comparisonCard: some View {
        let curDays = historyManager.getMonthlyWorkoutDays()
        let prevDays = historyManager.getLastMonthWorkoutDays()
        let curStreak = cachedStreak
        let prevStreak = historyManager.getLastMonthConsecutiveDays()

        return ComparisonSummaryCard(
            title: "與上月相比",
            items: [
                ComparisonItem(
                    icon: "calendar",
                    iconColor: .orange,
                    label: "運動天數",
                    currentText: "\(curDays)天",
                    changePercent: ComparisonItem.percent(current: curDays, previous: prevDays),
                    previousText: prevDays > 0 ? "\(prevDays)天" : nil
                ),
                ComparisonItem(
                    icon: "flame.fill",
                    iconColor: .orange,
                    label: "連續天數",
                    currentText: "\(curStreak)天",
                    changePercent: ComparisonItem.percent(current: curStreak, previous: prevStreak),
                    previousText: prevStreak > 0 ? "\(prevStreak)天" : nil
                )
            ]
        )
    }

    // MARK: - 快取計算
    private func recomputeCache(from workouts: [WorkoutHistory]) {
        cachedWorkoutDays = Set(workouts.map {
            calendar.component(.day, from: $0.completedAt.dateValue())
        })
        cachedStreak = historyManager.getConsecutiveDays()
    }

    // MARK: - 連續天數卡片
    private var streakCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange.opacity(0.2))
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(currentMonthString)
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(cachedStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.darkBackground))
                    Text("天")
                        .font(.subheadline)
                        .foregroundColor(Color(.darkBackground).opacity(0.7))
                }
                Text("連續紀錄")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 本月運動日曆卡片
    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("運動紀錄")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.darkBackground))
                Spacer()
                monthNavigation
            }

            // 星期標題
            HStack(spacing: 0) {
                ForEach(["日", "一", "二", "三", "四", "五", "六"], id: \.self) { label in
                    Text(label)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            // 日曆格子
            let cells = makeCells()
            let todayDay = isCurrentMonth ? calendar.component(.day, from: Date()) : -1
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                spacing: 4
            ) {
                ForEach(cells.indices, id: \.self) { i in
                    if let day = cells[i] {
                        let isToday = day == todayDay
                        let isWorkout = cachedWorkoutDays.contains(day)
                        ZStack {
                            Circle()
                                .fill(
                                    isWorkout
                                        ? Color(.primary)
                                        : (isToday ? Color(.myMint).opacity(0.15) : Color.gray.opacity(0.08))
                                )
                            Text("\(day)")
                                .font(.caption2)
                                .fontWeight(isToday ? .bold : .regular)
                                .foregroundColor(isWorkout ? .white : Color(.darkBackground))
                        }
                        .frame(height: 36)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 月份切換元件
    private var monthNavigation: some View {
        HStack(spacing: 10) {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.caption)
                    .foregroundColor(Color(.darkBackground))
            }
            Text(shortMonthString)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(minWidth: 50, alignment: .center)
            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(isCurrentMonth ? Color.gray.opacity(0.3) : Color(.darkBackground))
            }
            .disabled(isCurrentMonth)
        }
    }

    // MARK: - 輔助方法
    private func makeCells() -> [Int?] {
        var cells: [Int?] = Array(repeating: nil, count: firstWeekdayOffset)
        cells += (1...daysInMonth).map { Optional($0) }
        return cells
    }

    private func loadData() {
        historyManager.loadMonthlyWorkouts(year: displayedYear, month: displayedMonth)
    }

    private func previousMonth() {
        if let newDate = calendar.date(byAdding: .month, value: -1, to: displayedDate) {
            displayedDate = newDate
            loadData()
        }
    }

    private func nextMonth() {
        guard !isCurrentMonth else { return }
        if let newDate = calendar.date(byAdding: .month, value: 1, to: displayedDate) {
            displayedDate = newDate
            loadData()
        }
    }
}

#Preview {
    NavigationStack {
        ConsecutiveDaysTab()
            .onAppear {
                WorkoutHistoryManager.shared.loadMockData()
            }
    }
}
