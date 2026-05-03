//
//  PreviewData.swift
//  01
//
//  提供 Xcode Preview 使用的假資料，不會連線到 Firebase。
//

#if DEBUG
import Foundation
import FirebaseFirestore

// MARK: - Mock 使用者資料
enum MockUser {
    static let name = "Enya"
    static let email = "enya@example.com"
    static let userId = "preview-user-001"
}

// MARK: - Mock 運動記錄
enum MockWorkoutHistory {

    /// 產生本月各週分佈的假訓練紀錄（共 8 筆，分布在第 1~4 週）
    static var monthlyWorkouts: [WorkoutHistory] {
        let calendar = Calendar.current
        let now = Date()

        guard let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ) else { return [] }

        // 每週第幾天（從月份第 1 天起算偏移天數）
        let offsets: [Int] = [
            2,   // 第1週
            8, 10, 12, 13,   // 第2週
            15, 17,  // 第3週
            22, 25   // 第4週
        ]

        let plans = ["上肢運動", "下肢運動", "核心運動", "全身運動",
                     "上肢運動", "核心運動", "下肢運動", "全身運動"]

        let durations = [1800, 1200, 1500, 2400, 1320, 900, 1650, 2100]

        return offsets.enumerated().compactMap { index, offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfMonth),
                  date <= now else { return nil }

            return WorkoutHistory(
                id: "mock-\(index)",
                userId: MockUser.userId,
                planName: plans[index % plans.count],
                exercises: sampleExercises,
                completedAt: Timestamp(date: date),
                totalDuration: durations[index % durations.count],
                totalSets: 9,
                totalExercises: 3
            )
        }
    }

    /// 最近幾筆（取 monthlyWorkouts 後 5 筆，時間倒序）
    static var recentWorkouts: [WorkoutHistory] {
        monthlyWorkouts
            .sorted { $0.completedAt.dateValue() > $1.completedAt.dateValue() }
            .prefix(5)
            .map { $0 }
    }

    // MARK: 範例動作清單
    private static var sampleExercises: [ExerciseRecord] {
        [
            ExerciseRecord(exerciseId: "4",  exerciseName: "胸推",   sets: 3, targetCount: 12, targetTime: nil, completedSets: 3),
            ExerciseRecord(exerciseId: "1",  exerciseName: "手臂彎舉", sets: 3, targetCount: 15, targetTime: nil, completedSets: 3),
            ExerciseRecord(exerciseId: "9",  exerciseName: "棒式",   sets: 3, targetCount: nil, targetTime: 60,  completedSets: 3)
        ]
    }
}

// MARK: - WorkoutHistoryManager Preview 注入
extension WorkoutHistoryManager {
    /// 在 Preview 中注入假資料（不觸碰 Firebase）
    func loadMockData() {
        self.monthlyWorkouts = MockWorkoutHistory.monthlyWorkouts
        self.recentWorkouts  = MockWorkoutHistory.recentWorkouts
        self.computeWeeklyWorkoutCounts()
    }
}

// MARK: - AuthenticationViewModel Preview 注入
extension AuthenticationViewModel {
    /// 在 Preview 中模擬已登入狀態
    func loginAsMockUser() {
        self.isLoggedIn = true
        self.currentUserName  = MockUser.name
        self.currentUserEmail = MockUser.email
    }
}
#endif
