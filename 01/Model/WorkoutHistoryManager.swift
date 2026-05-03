//
//  WorkoutHistoryManager.swift
//  01
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class WorkoutHistoryManager: ObservableObject {
    static let shared = WorkoutHistoryManager()
    
    @Published var recentWorkouts: [WorkoutHistory] = []
    @Published var monthlyWorkouts: [WorkoutHistory] = []
    @Published var weeklyWorkoutCounts: [(label: String, count: Int)] = []

    private let db = Firestore.firestore()

    /// 目前已載入的月份，用來跳過重複的 Firestore 請求
    private var cachedYear: Int? = nil
    private var cachedMonth: Int? = nil

    /// 防止同時打出多個 loadMonthlyWorkouts 請求
    private var isLoadingMonthly = false

    // MARK: - 上個月資料（用於摘要比較）
    @Published var lastMonthWorkouts: [WorkoutHistory] = []
    private var cachedLastYear: Int? = nil
    private var cachedLastMonth: Int? = nil
    private var isLoadingLastMonthly = false

    private init() {}
    
    // MARK: - 儲存運動記錄到 Firestore
    func saveWorkoutHistory(plan: WorkoutPlan, duration: Int, completion: @escaping (Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(NSError(domain: "WorkoutHistory", code: -1, userInfo: [NSLocalizedDescriptionKey: "使用者未登入"]))
            return
        }
        
        // 將 WorkoutPlan 轉換為 ExerciseRecord 陣列
        let exercises = plan.details.map { detail in
            ExerciseRecord(
                exerciseId: detail.id,
                exerciseName: detail.name,
                sets: detail.sets,
                targetCount: detail.targetCount,
                targetTime: detail.targetTime,
                completedSets: detail.sets  // 假設全部完成
            )
        }
        
        let totalSets = plan.details.reduce(0) { $0 + $1.sets }
        
        let workoutHistory = WorkoutHistory(
            id: nil,
            userId: userId,
            planName: plan.name,
            exercises: exercises,
            completedAt: Timestamp(date: Date()),
            totalDuration: duration,
            totalSets: totalSets,
            totalExercises: plan.details.count
        )
        
        do {
            let _ = try db.collection("workoutHistory").addDocument(from: workoutHistory) { error in
                if let error = error {
                    print("❌ 儲存運動記錄失敗: \(error.localizedDescription)")
                    completion(error)
                } else {
                    print("✅ 運動記錄已儲存")
                    // 儲存成功後重新載入最近的記錄
                    self.loadRecentWorkouts(limit: 5)
                    completion(nil)
                }
            }
        } catch {
            print("❌ 編碼運動記錄失敗: \(error.localizedDescription)")
            completion(error)
        }
    }
    
    // MARK: - 預載當月資料（app 啟動或登入後立即呼叫，減少進入分析頁的卡頓）
    func preloadCurrentMonth() {
        let components = Calendar.current.dateComponents([.year, .month], from: Date())
        if let year = components.year, let month = components.month {
            loadMonthlyWorkouts(year: year, month: month)
        }
        loadRecentWorkouts()
        loadLastMonthWorkouts()
    }

    // MARK: - 載入上個月資料（用於摘要比較）
    func loadLastMonthWorkouts(forceReload: Bool = false) {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let calendar = Calendar.current
        guard let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: Date()) else { return }
        let comps = calendar.dateComponents([.year, .month], from: lastMonthDate)
        guard let year = comps.year, let month = comps.month else { return }

        if !forceReload && cachedLastYear == year && cachedLastMonth == month && !lastMonthWorkouts.isEmpty {
            return
        }
        guard !isLoadingLastMonthly else { return }
        isLoadingLastMonthly = true

        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        guard let startDate = calendar.date(from: dateComponents),
              let endDate = calendar.date(byAdding: DateComponents(month: 1), to: startDate) else {
            isLoadingLastMonthly = false
            return
        }

        db.collection("workoutHistory")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                defer { self.isLoadingLastMonthly = false }
                guard error == nil, let documents = snapshot?.documents else {
                    self.lastMonthWorkouts = []
                    return
                }
                let all = documents.compactMap { try? $0.data(as: WorkoutHistory.self) }
                self.lastMonthWorkouts = all.filter {
                    let d = $0.completedAt.dateValue()
                    return d >= startDate && d < endDate
                }
                self.cachedLastYear = year
                self.cachedLastMonth = month
            }
    }

    // MARK: - 上月統計（用於摘要比較）
    func getLastMonthWorkoutTime() -> Int {
        lastMonthWorkouts.reduce(0) { $0 + $1.totalDuration }
    }

    func getLastMonthWorkoutCount() -> Int {
        lastMonthWorkouts.count
    }

    func getLastMonthWorkoutDays() -> Int {
        let calendar = Calendar.current
        return Set(lastMonthWorkouts.map { calendar.startOfDay(for: $0.completedAt.dateValue()) }).count
    }

    func getLastMonthConsecutiveDays() -> Int {
        guard !lastMonthWorkouts.isEmpty else { return 0 }
        let calendar = Calendar.current
        let sorted = Array(
            Set(lastMonthWorkouts.map { calendar.startOfDay(for: $0.completedAt.dateValue()) })
        ).sorted(by: >)
        var streak = 1
        var prev = sorted[0]
        for date in sorted.dropFirst() {
            if calendar.dateComponents([.day], from: date, to: prev).day == 1 {
                streak += 1
                prev = date
            } else { break }
        }
        return streak
    }

    /// 本月有運動的天數
    func getMonthlyWorkoutDays() -> Int {
        let calendar = Calendar.current
        return Set(monthlyWorkouts.map { calendar.startOfDay(for: $0.completedAt.dateValue()) }).count
    }

    // MARK: - 載入最近的運動記錄（用於主頁顯示）
    // 注意：此查詢需要 Firestore 複合索引 (userId ASC, completedAt DESC)
    // 若出現 index 錯誤，請依 Firestore 錯誤訊息中的連結建立索引
    func loadRecentWorkouts(limit: Int = 5) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ 使用者未登入，無法載入運動記錄")
            return
        }

        print("🔍 開始載入使用者 \(userId) 的運動記錄...")

        db.collection("workoutHistory")
            .whereField("userId", isEqualTo: userId)
            .order(by: "completedAt", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 載入最近運動記錄失敗: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.recentWorkouts = []
                    return
                }

                print("📦 找到 \(documents.count) 筆文件")

                self.recentWorkouts = documents.compactMap { doc -> WorkoutHistory? in
                    do {
                        return try doc.data(as: WorkoutHistory.self)
                    } catch {
                        print("❌ 解析失敗: \(error)")
                        return nil
                    }
                }

                print("✅ 載入了 \(self.recentWorkouts.count) 筆最近運動記錄")
            }
    }
    
    // MARK: - 載入指定月份的運動記錄（用於 MonthlySports 頁面）
    func loadMonthlyWorkouts(year: Int, month: Int, forceReload: Bool = false) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ 使用者未登入，無法載入運動記錄")
            return
        }

        // 同一月份已載入且非強制更新，直接跳過，避免重複打 Firestore
        if !forceReload && cachedYear == year && cachedMonth == month && !monthlyWorkouts.isEmpty {
            print("⚡ \(year)年\(month)月 資料已快取，跳過 Firestore 請求")
            return
        }

        // 防止同時打出多個相同請求（進入分析頁時多個 tab 同時觸發）
        guard !isLoadingMonthly else {
            print("⚡ 已有請求進行中，跳過重複的 loadMonthlyWorkouts")
            return
        }
        isLoadingMonthly = true

        print("🔍 開始載入 \(year)年\(month)月 的運動記錄...")
        
        // 計算該月的起始和結束日期
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        guard let startDate = calendar.date(from: components),
              let endDate = calendar.date(byAdding: DateComponents(month: 1), to: startDate) else {
            print("❌ 日期計算失敗")
            return
        }
        
        print("📅 日期範圍: \(startDate) ~ \(endDate)")
        
        // 只用 userId 過濾，日期範圍在客戶端處理
        db.collection("workoutHistory")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 載入月份運動記錄失敗: \(error.localizedDescription)")
                    print("💡 錯誤詳情: \(error)")
                    self.isLoadingMonthly = false
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ 該月沒有運動記錄")
                    self.monthlyWorkouts = []
                    self.isLoadingMonthly = false
                    return
                }
                
                print("📦 找到 \(documents.count) 筆文件")
                
                // 解析並過濾該月的記錄
                let allWorkouts = documents.compactMap { doc -> WorkoutHistory? in
                    do {
                        return try doc.data(as: WorkoutHistory.self)
                    } catch {
                        print("❌ 解析失敗: \(error)")
                        return nil
                    }
                }
                
                // 在客戶端過濾日期範圍
                self.monthlyWorkouts = allWorkouts.filter { workout in
                    let workoutDate = workout.completedAt.dateValue()
                    return workoutDate >= startDate && workoutDate < endDate
                }.sorted { $0.completedAt.dateValue() < $1.completedAt.dateValue() }

                print("✅ 載入了 \(self.monthlyWorkouts.count) 筆該月運動記錄")
                self.cachedYear = year
                self.cachedMonth = month
                self.isLoadingMonthly = false
                self.computeWeeklyWorkoutCounts()
            }
    }
    
    // MARK: - 取得指定日期的運動記錄（用於行事曆點擊）
    func getWorkoutsForDate(_ date: Date) -> [WorkoutHistory] {
        let calendar = Calendar.current
        return monthlyWorkouts.filter { workout in
            let workoutDate = workout.completedAt.dateValue()
            return calendar.isDate(workoutDate, inSameDayAs: date)
        }
    }
    
    // MARK: - 取得該月有運動的日期集合（用於行事曆標記）
    func getWorkoutDates() -> Set<Date> {
        let calendar = Calendar.current
        var dates = Set<Date>()
        
        for workout in monthlyWorkouts {
            let workoutDate = workout.completedAt.dateValue()
            if let startOfDay = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: workoutDate)) {
                dates.insert(startOfDay)
            }
        }
        
        return dates
    }
    
    // MARK: - 計算統計數據
    func getTotalWorkoutTime() -> Int {
        return recentWorkouts.reduce(0) { $0 + $1.totalDuration }
    }

    func getTotalWorkoutCount() -> Int {
        return recentWorkouts.count
    }

    /// 本月總運動時間（秒）
    func getMonthlyWorkoutTime() -> Int {
        return monthlyWorkouts.reduce(0) { $0 + $1.totalDuration }
    }

    /// 本月完成訓練次數
    func getMonthlyWorkoutCount() -> Int {
        return monthlyWorkouts.count
    }
    
    func getConsecutiveDays() -> Int {
        guard !monthlyWorkouts.isEmpty else { return 0 }

        let calendar = Calendar.current

        // 去重：同一天多筆訓練只算一天
        let uniqueSortedDates = Array(
            Set(monthlyWorkouts.map { calendar.startOfDay(for: $0.completedAt.dateValue()) })
        ).sorted(by: >)

        guard !uniqueSortedDates.isEmpty else { return 0 }

        var consecutiveDays = 1
        var previousDate = uniqueSortedDates[0]

        for date in uniqueSortedDates.dropFirst() {
            if let diff = calendar.dateComponents([.day], from: date, to: previousDate).day,
               diff == 1 {
                consecutiveDays += 1
                previousDate = date
            } else {
                break
            }
        }

        return consecutiveDays
    }
    
    // MARK: - 計算本月每週訓練次數（從 monthlyWorkouts 衍生，用於WeeklyWorkoutCharts）
    func computeWeeklyWorkoutCounts() {
        let calendar = Calendar.current
        let now = Date()

        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let range = calendar.range(of: .day, in: .month, for: now) else {
            weeklyWorkoutCounts = []
            return
        }

        let daysInMonth = range.count
        var weeks: [(label: String, count: Int)] = []
        var weekStart = 0
        var weekNum = 1

        while weekStart < daysInMonth {
            let weekEnd = min(weekStart + 7, daysInMonth)

            guard let weekStartDate = calendar.date(byAdding: .day, value: weekStart, to: startOfMonth),
                  let weekEndDate  = calendar.date(byAdding: .day, value: weekEnd,  to: startOfMonth) else {
                weekStart += 7
                weekNum += 1
                continue
            }

            let count = monthlyWorkouts.filter {
                let d = $0.completedAt.dateValue()
                return d >= weekStartDate && d < weekEndDate
            }.count

            weeks.append((label: "第\(weekNum)週", count: count))
            weekStart += 7
            weekNum += 1
        }

        weeklyWorkoutCounts = weeks
    }
}
