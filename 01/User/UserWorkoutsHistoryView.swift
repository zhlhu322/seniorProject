//
//  UserWorkoutsHistoryView.swift
//  01
//
//  Created by AI Assistant on 2025/10/26.
//

import SwiftUI
import FirebaseFirestore

struct UserWorkoutsHistoryView: View {
    @StateObject private var historyManager = WorkoutHistoryManager.shared
    @State private var selectedDate: Date?
    
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack {
            Color(.background)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if historyManager.monthlyWorkouts.isEmpty {
                    // 沒有運動記錄時的空狀態
                    VStack(spacing: 20) {
                        Image(systemName: "figure.walk.circle")
                            .font(.system(size: 80))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("還沒有運動記錄")
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        Text("完成運動後，記錄會顯示在這裡")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 有運動記錄時顯示列表
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(groupedWorkouts.keys.sorted(by: >), id: \.self) { date in
                                Section {
                                    // 日期標題
                                    HStack {
                                        Text(formatSectionDate(date))
                                            .font(.headline)
                                            .foregroundColor(Color(.darkBackground))
                                        Spacer()
                                        Text("\(groupedWorkouts[date]?.count ?? 0) 次運動")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.top, 10)
                                    
                                    // 該日的運動記錄
                                    ForEach(groupedWorkouts[date] ?? []) { workout in
                                        WorkoutHistoryCard(workout: workout)
                                            .padding(.horizontal, 15)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 20)
                    }
                }
            }
        }
        .navigationTitle("運動歷史")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentMonthWorkouts()
        }
    }
    
    // MARK: - 計算屬性
    
    /// 將運動記錄按日期分組
    private var groupedWorkouts: [Date: [WorkoutHistory]] {
        Dictionary(grouping: historyManager.monthlyWorkouts) { workout in
            calendar.startOfDay(for: workout.completedAt.dateValue())
        }
    }
    
    // MARK: - 方法
    
    /// 載入本月的運動記錄
    private func loadCurrentMonthWorkouts() {
        let components = calendar.dateComponents([.year, .month], from: Date())
        guard let year = components.year, let month = components.month else { return }
        historyManager.loadMonthlyWorkouts(year: year, month: month)
    }
    
    /// 格式化日期標題（顯示「今天」、「昨天」或具體日期）
    private func formatSectionDate(_ date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "今天"
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_TW")
            formatter.dateFormat = "M月d日 EEEE"
            return formatter.string(from: date)
        }
    }
}

// MARK: - 運動記錄卡片
struct WorkoutHistoryCard: View {
    let workout: WorkoutHistory
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 主要資訊
            HStack(spacing: 15) {
                // 時間標記
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.primary).opacity(0.9))
                    VStack(spacing: 2) {
                        Text(formatTime(workout.completedAt.dateValue()))
                            .font(.caption2)
                            .fontWeight(.semibold)
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title3)
                    }
                    .foregroundColor(.white)
                }
                .frame(width: 50, height: 50)
                
                // 運動資訊
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.planName)
                        .font(.headline)
                        .foregroundColor(Color(.darkBackground))
                    
                    HStack(spacing: 15) {
                        Label("\(workout.totalExercises) 個動作", systemImage: "list.bullet")
                        Label("\(formatDuration(workout.totalDuration))", systemImage: "clock")
                    }
                    .font(.caption)
                    .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 展開/收合按鈕
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(Color(.darkBackground))
                }
            }
            .padding()
            
            // 展開的詳細資訊
            if isExpanded {
                Divider()
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("運動項目")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    ForEach(workout.exercises, id: \.exerciseId) { exercise in
                        HStack {
                            Circle()
                                .fill(Color(.primary).opacity(0.3))
                                .frame(width: 6, height: 6)
                            
                            Text(exercise.exerciseName)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            if let count = exercise.targetCount {
                                Text("\(exercise.sets) 組 × \(count) 次")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else if let time = exercise.targetTime {
                                Text("\(exercise.sets) 組 × \(time) 秒")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.white))
        .cornerRadius(16)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.black).opacity(0.1), lineWidth: 1)
        }
    }
    
    // MARK: - 輔助方法
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)分鐘"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)小時\(remainingMinutes)分"
        }
    }
}

#Preview("有資料") {
    NavigationStack {
        UserWorkoutsHistoryView()
            .onAppear {
                // 建立假資料
                let manager = WorkoutHistoryManager.shared
                
                // 清空現有資料
                manager.monthlyWorkouts = []
                
                // 建立假的運動記錄
                let calendar = Calendar.current
                let today = Date()
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
                let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
                let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!
                
                // 今天的運動記錄
                let workout1 = WorkoutHistory(
                    id: "1",
                    userId: "preview-user",
                    planName: "上肢訓練",
                    exercises: [
                        ExerciseRecord(
                            exerciseId: "chest_press",
                            exerciseName: "胸部推舉",
                            sets: 3,
                            targetCount: 12,
                            targetTime: nil,
                            completedSets: 3
                        ),
                        ExerciseRecord(
                            exerciseId: "biceps_curl",
                            exerciseName: "二頭彎舉",
                            sets: 3,
                            targetCount: 15,
                            targetTime: nil,
                            completedSets: 3
                        ),
                        ExerciseRecord(
                            exerciseId: "shoulder_press",
                            exerciseName: "肩部推舉",
                            sets: 3,
                            targetCount: 10,
                            targetTime: nil,
                            completedSets: 3
                        )
                    ],
                    completedAt: Timestamp(date: today),
                    totalDuration: 1800,
                    totalSets: 9,
                    totalExercises: 3
                )
                
                // 昨天的運動記錄
                let workout2 = WorkoutHistory(
                    id: "2",
                    userId: "preview-user",
                    planName: "核心訓練",
                    exercises: [
                        ExerciseRecord(
                            exerciseId: "plank",
                            exerciseName: "棒式",
                            sets: 3,
                            targetCount: nil,
                            targetTime: 60,
                            completedSets: 3
                        ),
                        ExerciseRecord(
                            exerciseId: "side_plank",
                            exerciseName: "側棒式",
                            sets: 3,
                            targetCount: nil,
                            targetTime: 45,
                            completedSets: 3
                        )
                    ],
                    completedAt: Timestamp(date: yesterday),
                    totalDuration: 900,
                    totalSets: 6,
                    totalExercises: 2
                )
                
                // 3天前的運動記錄
                let workout3 = WorkoutHistory(
                    id: "3",
                    userId: "preview-user",
                    planName: "下肢訓練",
                    exercises: [
                        ExerciseRecord(
                            exerciseId: "squat",
                            exerciseName: "深蹲",
                            sets: 4,
                            targetCount: 15,
                            targetTime: nil,
                            completedSets: 4
                        ),
                        ExerciseRecord(
                            exerciseId: "leg_raise",
                            exerciseName: "抬腿",
                            sets: 3,
                            targetCount: 20,
                            targetTime: nil,
                            completedSets: 3
                        )
                    ],
                    completedAt: Timestamp(date: threeDaysAgo),
                    totalDuration: 2400,
                    totalSets: 7,
                    totalExercises: 2
                )
                
                // 5天前的運動記錄（兩次）
                let workout4 = WorkoutHistory(
                    id: "4",
                    userId: "preview-user",
                    planName: "全身訓練",
                    exercises: [
                        ExerciseRecord(
                            exerciseId: "burpee",
                            exerciseName: "波比跳",
                            sets: 3,
                            targetCount: 10,
                            targetTime: nil,
                            completedSets: 3
                        ),
                        ExerciseRecord(
                            exerciseId: "push_up",
                            exerciseName: "伏地挺身",
                            sets: 3,
                            targetCount: 15,
                            targetTime: nil,
                            completedSets: 3
                        ),
                        ExerciseRecord(
                            exerciseId: "mountain_climber",
                            exerciseName: "登山者",
                            sets: 3,
                            targetCount: 20,
                            targetTime: nil,
                            completedSets: 3
                        )
                    ],
                    completedAt: Timestamp(date: fiveDaysAgo.addingTimeInterval(3600 * 10)),
                    totalDuration: 2700,
                    totalSets: 9,
                    totalExercises: 3
                )
                
                let workout5 = WorkoutHistory(
                    id: "5",
                    userId: "preview-user",
                    planName: "伸展放鬆",
                    exercises: [
                        ExerciseRecord(
                            exerciseId: "stretch_1",
                            exerciseName: "大腿伸展",
                            sets: 2,
                            targetCount: nil,
                            targetTime: 30,
                            completedSets: 2
                        ),
                        ExerciseRecord(
                            exerciseId: "stretch_2",
                            exerciseName: "肩膀伸展",
                            sets: 2,
                            targetCount: nil,
                            targetTime: 30,
                            completedSets: 2
                        )
                    ],
                    completedAt: Timestamp(date: fiveDaysAgo.addingTimeInterval(3600 * 18)),
                    totalDuration: 600,
                    totalSets: 4,
                    totalExercises: 2
                )
                
                // 將假資料加入 manager
                manager.monthlyWorkouts = [workout1, workout2, workout3, workout4, workout5]
            }
    }
}

#Preview("空狀態") {
    NavigationStack {
        UserWorkoutsHistoryView()
            .onAppear {
                // 清空資料以顯示空狀態
                let manager = WorkoutHistoryManager.shared
                manager.monthlyWorkouts = []
            }
    }
}
