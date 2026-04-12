//
//  ConsecutiveDaysTab.swift
//  01
//
//  Created by 李恩亞 on 2026/04/12.
//  運動分析頁面 Tab 2：本月連續天數與運動日曆

import SwiftUI

struct ConsecutiveDaysTab: View {
    @ObservedObject private var historyManager = WorkoutHistoryManager.shared
    private let calendar = Calendar.current

    private var streak: Int { historyManager.getConsecutiveDays() }

    private var workoutDays: Set<Int> {
        Set(historyManager.monthlyWorkouts.map {
            calendar.component(.day, from: $0.completedAt.dateValue())
        })
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: Date())?.count ?? 30
    }

    private var firstWeekdayOffset: Int {
        let comps = calendar.dateComponents([.year, .month], from: Date())
        guard let firstDay = calendar.date(from: comps),
              let weekday = calendar.dateComponents([.weekday], from: firstDay).weekday else { return 0 }
        return (weekday - 1) % 7
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
                streakCard
                calendarCard
            }
            .padding(.top, 20)
        }
        .background(Color(.background))
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
                    Text("\(streak)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.darkBackground))
                    Text("天")
                        .font(.subheadline)
                        .foregroundColor(Color(.darkBackground).opacity(0.7))
                }
                Text("目前連續紀錄")
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
            Text("本月運動紀錄")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(.darkBackground))

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
            let today = calendar.component(.day, from: Date())
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                spacing: 4
            ) {
                ForEach(cells.indices, id: \.self) { i in
                    if let day = cells[i] {
                        let isToday = day == today
                        let isWorkout = workoutDays.contains(day)
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

    // MARK: - 輔助方法
    private func makeCells() -> [Int?] {
        var cells: [Int?] = Array(repeating: nil, count: firstWeekdayOffset)
        cells += (1...daysInMonth).map { Optional($0) }
        return cells
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
