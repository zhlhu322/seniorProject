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
    private let calendar = Calendar.current

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
    }

    private var dailyMinutes: [(day: Int, minutes: Double)] {
        var map: [Int: Double] = [:]
        for workout in historyManager.monthlyWorkouts {
            let day = calendar.component(.day, from: workout.completedAt.dateValue())
            map[day, default: 0] += Double(workout.totalDuration) / 60.0
        }
        return (1...daysInMonth).map { day in
            (day: day, minutes: map[day] ?? 0)
        }
    }

    private var totalMinutes: Double {
        dailyMinutes.reduce(0) { $0 + $1.minutes }
    }

    private var maxMinutes: Double {
        max(dailyMinutes.map { $0.minutes }.max() ?? 0, 1)
    }

    private var currentMonthString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_TW")
        f.dateFormat = "yyyy年M月"
        return f.string(from: Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryCard
                chartCard
            }
            .padding(.top, 20)
        }
        .background(Color(.background))
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
                Text(formatMinutes(totalMinutes))
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
            Text("每日運動時數")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(.darkBackground))

            if totalMinutes == 0 {
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

    // MARK: - Swift Charts 折線圖
    private var lineChart: some View {
        Chart(dailyMinutes, id: \.day) { point in
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
        .chartYScale(domain: 0...(maxMinutes * 1.25))
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
            Text("本月尚無運動紀錄")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 輔助方法
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
