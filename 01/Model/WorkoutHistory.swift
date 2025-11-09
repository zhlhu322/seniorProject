//
//  WorkoutHistory.swift
//  01
//
//  Created by AI Assistant on 2025/10/26.
//

import Foundation
import FirebaseFirestore

// MARK: - 運動記錄 Model
struct WorkoutHistory: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let userId: String
    let planName: String
    let exercises: [ExerciseRecord]
    let completedAt: Timestamp
    let totalDuration: Int  // 總運動時間（秒）
    let totalSets: Int      // 總組數
    let totalExercises: Int // 總動作數
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case planName
        case exercises
        case completedAt
        case totalDuration
        case totalSets
        case totalExercises
    }
}

// MARK: - 單個運動項目記錄
struct ExerciseRecord: Codable, Hashable {
    let exerciseId: String
    let exerciseName: String
    let sets: Int
    let targetCount: Int?
    let targetTime: Int?
    let completedSets: Int  // 實際完成的組數
    
    enum CodingKeys: String, CodingKey {
        case exerciseId
        case exerciseName
        case sets
        case targetCount
        case targetTime
        case completedSets
    }
}

// MARK: - 用於統計的簡化結構
struct WorkoutSummary: Identifiable {
    let id: String
    let date: Date
    let planName: String
    let totalExercises: Int
    let totalDuration: Int
}
