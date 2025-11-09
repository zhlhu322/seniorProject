//
//  TestDataHelper.swift
//  01
//
//  用於加入測試資料到 Firebase
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class TestDataHelper {
    static let shared = TestDataHelper()
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - 加入假資料
    func addTestWorkoutData(completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ 使用者未登入")
            completion(false)
            return
        }
        
        let testWorkouts = createTestWorkouts(userId: userId)
        
        var successCount = 0
        let totalCount = testWorkouts.count
        
        for workout in testWorkouts {
            do {
                let _ = try db.collection("workoutHistory").addDocument(from: workout) { error in
                    if let error = error {
                        print("❌ 加入假資料失敗: \(error.localizedDescription)")
                    } else {
                        successCount += 1
                        print("✅ 成功加入假資料 (\(successCount)/\(totalCount))")
                        
                        if successCount == totalCount {
                            print("🎉 所有假資料已加入完成！")
                            completion(true)
                        }
                    }
                }
            } catch {
                print("❌ 編碼假資料失敗: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 創建測試資料
    private func createTestWorkouts(userId: String) -> [WorkoutHistory] {
        var workouts: [WorkoutHistory] = []
        let calendar = Calendar.current
        
        // 假資料 1：今天
        workouts.append(WorkoutHistory(
            id: nil,
            userId: userId,
            planName: "上肢運動",
            exercises: [
                ExerciseRecord(exerciseId: "4", exerciseName: "胸推", sets: 3, targetCount: 12, targetTime: nil, completedSets: 3),
                ExerciseRecord(exerciseId: "1", exerciseName: "手臂彎舉", sets: 3, targetCount: 15, targetTime: nil, completedSets: 3),
                ExerciseRecord(exerciseId: "2", exerciseName: "肩推", sets: 3, targetCount: 10, targetTime: nil, completedSets: 3)
            ],
            completedAt: Timestamp(date: Date()),
            totalDuration: 1800, // 30分鐘
            totalSets: 9,
            totalExercises: 3
        ))
        
        // 假資料 2：3天前
        if let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: Date()) {
            workouts.append(WorkoutHistory(
                id: nil,
                userId: userId,
                planName: "下肢運動",
                exercises: [
                    ExerciseRecord(exerciseId: "7", exerciseName: "太空椅深蹲", sets: 3, targetCount: nil, targetTime: 30, completedSets: 3),
                    ExerciseRecord(exerciseId: "8", exerciseName: "側躺抬腿", sets: 3, targetCount: 15, targetTime: nil, completedSets: 3)
                ],
                completedAt: Timestamp(date: threeDaysAgo),
                totalDuration: 1200, // 20分鐘
                totalSets: 6,
                totalExercises: 2
            ))
        }
        
        // 假資料 3：5天前
        if let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: Date()) {
            workouts.append(WorkoutHistory(
                id: nil,
                userId: userId,
                planName: "核心運動",
                exercises: [
                    ExerciseRecord(exerciseId: "9", exerciseName: "棒式", sets: 3, targetCount: nil, targetTime: 60, completedSets: 3),
                    ExerciseRecord(exerciseId: "10", exerciseName: "側棒式", sets: 3, targetCount: nil, targetTime: 45, completedSets: 3),
                    ExerciseRecord(exerciseId: "6", exerciseName: "超人", sets: 3, targetCount: 15, targetTime: nil, completedSets: 3)
                ],
                completedAt: Timestamp(date: fiveDaysAgo),
                totalDuration: 1500, // 25分鐘
                totalSets: 9,
                totalExercises: 3
            ))
        }
        
        // 假資料 4：7天前
        if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) {
            workouts.append(WorkoutHistory(
                id: nil,
                userId: userId,
                planName: "全身運動",
                exercises: [
                    ExerciseRecord(exerciseId: "4", exerciseName: "胸推", sets: 2, targetCount: 10, targetTime: nil, completedSets: 2),
                    ExerciseRecord(exerciseId: "7", exerciseName: "太空椅深蹲", sets: 2, targetCount: 12, targetTime: nil, completedSets: 2),
                    ExerciseRecord(exerciseId: "9", exerciseName: "棒式", sets: 2, targetCount: nil, targetTime: 45, completedSets: 2)
                ],
                completedAt: Timestamp(date: sevenDaysAgo),
                totalDuration: 2400, // 40分鐘
                totalSets: 6,
                totalExercises: 3
            ))
        }
        
        // 假資料 5：10天前
        if let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: Date()) {
            workouts.append(WorkoutHistory(
                id: nil,
                userId: userId,
                planName: "上肢運動",
                exercises: [
                    ExerciseRecord(exerciseId: "1", exerciseName: "手臂彎舉", sets: 4, targetCount: 12, targetTime: nil, completedSets: 4),
                    ExerciseRecord(exerciseId: "3", exerciseName: "手臂伸展", sets: 4, targetCount: 12, targetTime: nil, completedSets: 4)
                ],
                completedAt: Timestamp(date: tenDaysAgo),
                totalDuration: 1320, // 22分鐘
                totalSets: 8,
                totalExercises: 2
            ))
        }
        
        // 假資料 6：15天前
        if let fifteenDaysAgo = calendar.date(byAdding: .day, value: -15, to: Date()) {
            workouts.append(WorkoutHistory(
                id: nil,
                userId: userId,
                planName: "核心運動",
                exercises: [
                    ExerciseRecord(exerciseId: "9", exerciseName: "棒式", sets: 3, targetCount: nil, targetTime: 50, completedSets: 3)
                ],
                completedAt: Timestamp(date: fifteenDaysAgo),
                totalDuration: 900, // 15分鐘
                totalSets: 3,
                totalExercises: 1
            ))
        }
        
        return workouts
    }
    
    // MARK: - 清除測試資料（小心使用！）
    func clearAllTestData(completion: @escaping (Bool) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("❌ 使用者未登入")
            completion(false)
            return
        }
        
        db.collection("workoutHistory")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 獲取資料失敗: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ 沒有資料可清除")
                    completion(true)
                    return
                }
                
                let batch = self.db.batch()
                documents.forEach { batch.deleteDocument($0.reference) }
                
                batch.commit { error in
                    if let error = error {
                        print("❌ 清除資料失敗: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ 已清除 \(documents.count) 筆資料")
                        completion(true)
                    }
                }
            }
    }
}
