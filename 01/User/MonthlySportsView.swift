//
//  MonthlySportsView.swift
//  01
//
//  Created by 李恩亞 on 2025/10/22.
//

import SwiftUI

struct MonthlySportsView: View {
    @State private var currentDate = Date()
    @State private var workoutDates: Set<DateComponents> = []
    // 儲存有運動的日期
    @State private var path: [UserRoute] = []
    
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
            }
            .background(Color(.white))

            
            
            VStack{
                Text("近期紀錄")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                HStack(spacing: 15) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.primary))
                        Text("3/22")
                    }
                    .frame(width:50,height:50)
                    VStack(alignment: .leading) {
                        Text("上肢運動")
                        Text("30分鍾").font(.footnote)
                    }
                    Spacer()
                    Button(action: {path.append(.userWorkoutsHistory)}) {
                        Image(systemName:"chevron.right")
                            .font(.title3)
                            .foregroundColor(Color(.darkBackground))
                    }
                }
                .padding()
                .frame(width: 350, height: 64)
                .background(Color(.white))
                .cornerRadius(16)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.black), style: StrokeStyle(lineWidth: 1))
                }
                .foregroundColor(.black)
            }
            
            Spacer()
        }
        .background(Color(.background))
        .navigationTitle("本月運動")
        .navigationBarTitleDisplayMode(.inline)
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
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return workoutDates.contains(components)
    }
    /// 載入有運動的日期（從 Firestore 或本地資料）
    private func loadWorkoutDates() {
        // TODO: 從 Firestore 載入使用者的運動記錄
        // 目前使用測試資料
        let testDates: [Date] = [
            calendar.date(from: DateComponents(year: 2025, month: 10, day: 5))!,
            calendar.date(from: DateComponents(year: 2025, month: 10, day: 12))!,
            calendar.date(from: DateComponents(year: 2025, month: 10, day: 13))!,
            calendar.date(from: DateComponents(year: 2025, month: 10, day: 22))!
        ]
        
        workoutDates = Set(testDates.map { calendar.dateComponents([.year, .month, .day], from: $0) })
    }
}

// MARK: - 日期格子 View
struct DayCell: View {
    let date: Date
    let isWorkoutDay: Bool
    let isToday: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            if isWorkoutDay {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color(.primary)).opacity(0.8)
            }
            Text("\(calendar.component(.day, from: date))")
                .font(.headline)
                .fontWeight(isToday ? .heavy : .regular)
                .foregroundColor(isWorkoutDay ? .white : Color(.darkBackground))
        }
        .frame(height: 40)
    }
}

#Preview {
    NavigationStack {
        MonthlySportsView()
    }
}
