//
//  WeeklyWorkoutChartView.swift
//  01
//  在UserView點擊完成訓練卡片中後進入的畫面，顯示本月每週的訓練次數統計圖表和明細列表。
//  Created by 李恩亞 on 2025/10/22.
//

import SwiftUI
import Charts

struct WeeklyWorkoutChartView: View {
    @StateObject private var historyManager = WorkoutHistoryManager.shared

    private var weeklyData: [(label: String, count: Int)] {
        historyManager.weeklyWorkoutCounts
    }

    private var maxCount: Int {
        max(weeklyData.map { $0.count }.max() ?? 0, 1)
    }

    private var totalCount: Int {
        weeklyData.reduce(0) { $0 + $1.count }
    }

    private var currentMonthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: Date())
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
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            let components = Calendar.current.dateComponents([.year, .month], from: Date())
            if let year = components.year, let month = components.month {
                historyManager.loadMonthlyWorkouts(year: year, month: month)
            }
            applyNavigationBarStyle()
        }
    }

    // MARK: - 本月總覽卡片
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
                Text(currentMonthString)
                    .font(.caption)
                    .foregroundColor(.gray)
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(totalCount)")
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
            Text("每週訓練次數")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(.darkBackground))

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

    // MARK: - Swift Charts 長條圖
    @ViewBuilder
    private var weeklyChart: some View {
        Chart(weeklyData, id: \.label) { week in
            BarMark(
                x: .value("週次", week.label),
                y: .value("次數", week.count)
            )
            .foregroundStyle(barColor(for: week.count))
            .cornerRadius(6, style: .continuous)
            .annotation(position: .top, alignment: .center, spacing: 4) {
                barLabel(for: week.count)
            }
        }
        .chartYScale(domain: 0...(maxCount + 1))
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: Double(max(1, maxCount / 4)))) { value in
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

    // MARK: - 輔助方法
    private func barColor(for count: Int) -> Color {
        if count == 0 { return Color.gray.opacity(0.15) }
        return count == maxCount ? Color(.myMint) : Color(.myMint).opacity(0.55)
    }

    @ViewBuilder
    private func barLabel(for count: Int) -> some View {
        if count > 0 {
            Text("\(count)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(
                    count == maxCount
                        ? Color(.myMint)
                        : Color(.darkBackground).opacity(0.7)
                )
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
