//
//  MonthlyHoursTab.swift
//  01
//
//  Created by 李恩亞 on 2026/04/12.
//  運動分析頁面 Tab 1：本月每日運動時數折線圖

import SwiftUI
import Charts

struct MonthlyHoursTab: View {
    @ObservedObject private var historyManager = WorkoutHistoryManager.shared
    @State private var displayedDate: Date = Date()
    @State private var cachedDailyMinutes: [(day: Int, minutes: Double)] = []
    @State private var cachedTotalMinutes: Double = 0
    @State private var cachedMaxMinutes: Double = 1
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

    private var currentMonthString: String { Self.longFormatter.string(from: displayedDate) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryCard
                chartCard
            }
            .padding(.top, 20)
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

    // MARK: - 快取計算（避免 body 每次 render 都重複運算）
    private func recomputeCache(from workouts: [WorkoutHistory]) {
        var map: [Int: Double] = [:]
        for workout in workouts {
            let day = calendar.component(.day, from: workout.completedAt.dateValue())
            map[day, default: 0] += Double(workout.totalDuration) / 60.0
        }
        let daily = (1...max(daysInMonth, 1)).map { day in
            (day: day, minutes: map[day] ?? 0)
        }
        cachedDailyMinutes = daily
        cachedTotalMinutes = daily.reduce(0) { $0 + $1.minutes }
        let m = daily.map { $0.minutes }.max() ?? 0
        cachedMaxMinutes = max(m.isNaN || m.isInfinite ? 0 : m, 1)
    }

    // MARK: - 本月總覽卡片
    private var summaryCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.myMint).opacity(0.25))
                Image(systemName: "timer")
                    .font(.system(size: 28))
                    .foregroundColor(Color(.myMint))
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 4) {
                Text(currentMonthString)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(formatMinutes(cachedTotalMinutes))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.darkBackground))
                Text("總運動時數")
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

    // MARK: - 折線圖卡片
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("每日運動時數")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.darkBackground))
                Spacer()
                monthNavigation
            }

            if cachedTotalMinutes == 0 {
                emptyPlaceholder
            } else {
                lineChart
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

    private var shortMonthString: String { Self.shortFormatter.string(from: displayedDate) }

    // MARK: - Swift Charts 折線圖
    private var lineChart: some View {
        Chart(cachedDailyMinutes, id: \.day) { point in
            AreaMark(
                x: .value("日", point.day),
                y: .value("分鐘", point.minutes)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color(.myMint).opacity(0.3), Color(.myMint).opacity(0.0)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            LineMark(
                x: .value("日", point.day),
                y: .value("分鐘", point.minutes)
            )
            .foregroundStyle(Color(.myMint))
            .lineStyle(StrokeStyle(lineWidth: 2))
            .interpolationMethod(.catmullRom)
        }
        .chartXScale(domain: 1...daysInMonth)
        .chartYScale(domain: 0...(cachedMaxMinutes * 1.25))
        .chartXAxis {
            AxisMarks(values: stride(from: 1, through: daysInMonth, by: 7).map { $0 }) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Text("\(v)日")
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(v < 60 ? "\(Int(v))分" : "\(Int(v / 60))時")
                            .font(.caption2)
                            .foregroundStyle(Color.gray)
                    }
                }
            }
        }
        .frame(height: 200)
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 36))
                .foregroundColor(.gray.opacity(0.4))
            Text("該月尚無運動紀錄")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 輔助方法
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

    private func formatMinutes(_ minutes: Double) -> String {
        let total = Int(minutes)
        if total < 60 { return "\(total)分鐘" }
        let h = total / 60, m = total % 60
        return m == 0 ? "\(h)小時" : "\(h)小時\(m)分"
    }
}

#Preview {
    NavigationStack {
        MonthlyHoursTab()
            .onAppear {
                WorkoutHistoryManager.shared.loadMockData()
            }
    }
}
