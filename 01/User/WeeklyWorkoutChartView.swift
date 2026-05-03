//
//  WeeklyWorkoutChartView.swift
//  01
//  在UserView點擊完成訓練卡片中後進入的畫面，顯示指定週每日的訓練次數統計圖表。
//  Created by 李恩亞 on 2025/10/22.
//

import SwiftUI
import Charts

struct WeeklyWorkoutChartView: View {
    @StateObject private var historyManager = WorkoutHistoryManager.shared
    @State private var weekStart: Date = Self.currentWeekStartDate()
    @State private var cachedWeekDailyData: [(label: String, count: Int, date: Date)] = []
    @State private var cachedMaxCount: Int = 1
    @State private var cachedTotalCount: Int = 0
    private let calendar = Calendar.current

    // 只建立一次，避免每次 render 重新 alloc
    private static let yearMonthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "yyyy年M月"
        return f
    }()
    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "M/d"
        return f
    }()

    // MARK: - 計算當週起始日（系統日曆第一天，通常為週日）
    private static func currentWeekStartDate() -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return cal.date(from: comps) ?? Date()
    }

    private var isCurrentWeek: Bool {
        calendar.isDate(weekStart, equalTo: Self.currentWeekStartDate(), toGranularity: .weekOfYear)
    }

    // MARK: - 週範圍標題
    private var weekRangeString: String { Self.yearMonthFormatter.string(from: weekStart) }

    private var weekShortRangeString: String {
        let endDate = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? weekStart
        return "\(Self.shortDateFormatter.string(from: weekStart)) ~ \(Self.shortDateFormatter.string(from: endDate))"
    }

    // MARK: - 快取計算（避免 body 每次 render 都重複運算）
    private func recomputeCache(from workouts: [WorkoutHistory]) {
        let labels = ["日", "一", "二", "三", "四", "五", "六"]
        let data: [(label: String, count: Int, date: Date)] = (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: weekStart) ?? weekStart
            let count = workouts.filter {
                calendar.isDate($0.completedAt.dateValue(), inSameDayAs: day)
            }.count
            let weekdayIdx = calendar.component(.weekday, from: day) - 1
            return (label: labels[weekdayIdx], count: count, date: day)
        }
        cachedWeekDailyData = data
        cachedMaxCount = max(data.map { $0.count }.max() ?? 0, 1)
        cachedTotalCount = data.reduce(0) { $0 + $1.count }
    }

    // MARK: - 上週次數（跨月時合併 lastMonthWorkouts）
    private var lastWeekTotal: Int {
        guard let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart),
              let lastWeekEnd = calendar.date(byAdding: .day, value: 7, to: lastWeekStart) else { return 0 }
        let allWorkouts = historyManager.monthlyWorkouts + historyManager.lastMonthWorkouts
        return allWorkouts.filter {
            let d = $0.completedAt.dateValue()
            return d >= lastWeekStart && d < lastWeekEnd
        }.count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryCard
                chartCard
                comparisonCard
            }
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.background))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadData()
            applyNavigationBarStyle()
            recomputeCache(from: historyManager.monthlyWorkouts)
        }
        .onChange(of: historyManager.monthlyWorkouts) { _, workouts in
            recomputeCache(from: workouts)
        }
        .onChange(of: weekStart) { _, _ in
            recomputeCache(from: historyManager.monthlyWorkouts)
        }
    }

    // MARK: - 與上週比較摘要卡片
    private var comparisonCard: some View {
        let curTotal = cachedTotalCount
        let prevTotal = lastWeekTotal
        // 平均每日（只算有資料的天，避免除以零）
        let curAvg = curTotal > 0 ? Double(curTotal) / 7.0 : 0.0
        let prevAvg = prevTotal > 0 ? Double(prevTotal) / 7.0 : 0.0

        return ComparisonSummaryCard(
            title: "與上週相比",
            items: [
                ComparisonItem(
                    icon: "dumbbell.fill",
                    iconColor: Color(.myMint),
                    label: "本週次數",
                    currentText: "\(curTotal)次",
                    changePercent: ComparisonItem.percent(current: curTotal, previous: prevTotal),
                    previousText: prevTotal > 0 ? "\(prevTotal)次" : nil
                ),
                ComparisonItem(
                    icon: "chart.bar.fill",
                    iconColor: Color(.myMint),
                    label: "日均次數",
                    currentText: String(format: "%.1f次", curAvg),
                    changePercent: ComparisonItem.percent(current: curAvg, previous: prevAvg),
                    previousText: prevAvg > 0 ? String(format: "%.1f次", prevAvg) : nil
                )
            ]
        )
    }

    // MARK: - 本週總覽卡片
    @ViewBuilder
    private var summaryCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.myMint).opacity(0.25))
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(.myMint))
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(weekShortRangeString)
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(cachedTotalCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.darkBackground))
                    Text("次")
                        .font(.subheadline)
                        .foregroundColor(Color(.darkBackground).opacity(0.7))
                }
                Text("完成訓練")
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

    // MARK: - 長條圖卡片
    @ViewBuilder
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("每日訓練次數")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.darkBackground))
                Spacer()
                weekNavigation
            }

            weeklyChart
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

    // MARK: - 週切換元件
    private var weekNavigation: some View {
        HStack(spacing: 10) {
            Button(action: previousWeek) {
                Image(systemName: "chevron.left")
                    .font(.caption)
                    .foregroundColor(Color(.darkBackground))
            }
            Text(weekShortRangeString)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(minWidth: 90, alignment: .center)
            Button(action: nextWeek) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(isCurrentWeek ? Color.gray.opacity(0.3) : Color(.myMint))
            }
            .disabled(isCurrentWeek)
        }
    }

    // MARK: - Swift Charts 長條圖（每日）
    @ViewBuilder
    private var weeklyChart: some View {
        if cachedTotalCount == 0 {
            emptyPlaceholder
        } else {
            Chart(cachedWeekDailyData, id: \.label) { day in
                BarMark(
                    x: .value("星期", day.label),
                    y: .value("次數", max(day.count, 0))
                )
                .foregroundStyle(barColor(for: day.count))
                .cornerRadius(day.count > 0 ? 6 : 0, style: .continuous)
                .annotation(position: .top, alignment: .center, spacing: 4) {
                    barLabel(for: day.count)
                }
            }
            .chartYScale(domain: 0...Double(cachedMaxCount + 1))
            .chartYAxis {
                AxisMarks(position: .leading, values: .stride(by: Double(max(1, cachedMaxCount / 4)))) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                                .font(.caption2)
                                .foregroundStyle(Color.gray)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(Color.gray)
                }
            }
            .frame(height: 200)
        }
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "dumbbell")
                .font(.system(size: 36))
                .foregroundColor(.gray.opacity(0.4))
            Text("該週尚無訓練紀錄")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 輔助方法
    private func barColor(for count: Int) -> Color {
        if count == 0 { return Color.gray.opacity(0.15) }
        return count == cachedMaxCount ? Color(.myMint) : Color(.myMint).opacity(0.55)
    }

    @ViewBuilder
    private func barLabel(for count: Int) -> some View {
        if count > 0 {
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(
                    count == cachedMaxCount
                        ? Color(.myMint)
                        : Color(.darkBackground).opacity(0.7)
                )
        }
    }

    private func loadData() {
        let components = calendar.dateComponents([.year, .month], from: weekStart)
        if let year = components.year, let month = components.month {
            historyManager.loadMonthlyWorkouts(year: year, month: month)
        }
    }

    private func previousWeek() {
        if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: weekStart) {
            weekStart = newDate
            loadData()
        }
    }

    private func nextWeek() {
        guard !isCurrentWeek else { return }
        if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart) {
            weekStart = newDate
            loadData()
        }
    }

    private func applyNavigationBarStyle() {
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
        WeeklyWorkoutChartView()
            .onAppear {
                WorkoutHistoryManager.shared.loadMockData()
                AuthenticationViewModel.shared.loginAsMockUser()
            }
    }
}
