//
//  WorkoutCompleteView.swift
//  01
//
//  Created by 李恩亞 on 2025/4/6.
//

import SwiftUI

struct WorkoutCompleteView: View {
    @Binding var path: [PlanRoute]
    let plan: WorkoutPlan
    @StateObject private var historyManager = WorkoutHistoryManager.shared
    @State private var workoutDuration: Int = 0  // 運動持續時間（秒）
    @State private var isSaving = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // 完成標題
            Text("訓練完成！")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(.accent))
                .padding(.top, 20)
            Text("呱呱 你超棒的！")
                    .font(.callout)
                    .foregroundStyle(Color(.darkBackground))
                    .padding()
                    .overlay(
                            RoundedRectangle(cornerRadius: 20)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                            .foregroundStyle(Color(.darkBackground))
                    )
                
                    Image("chicken_strong")
                        .resizable()
                        .frame(width: 250, height: 300)
                    .padding()
                
                Button(action: {
                    isSaving = true
                    // 儲存運動記錄到 Firestore
                    historyManager.saveWorkoutHistory(plan: plan, duration: workoutDuration) { error in
                        isSaving = false
                        if let error = error {
                            print("❌ 儲存運動記錄失敗: \(error.localizedDescription)")
                        } else {
                            print("✅ 運動記錄已儲存")
                        }
                        path.append(.levelup)
                    }
                }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 5)
                        }
                        Text(isSaving ? "儲存中..." : "前往升級")
                            .font(.headline)
                            .foregroundColor(Color(.white))
                    }
                    .padding()
                    .frame(width: 300, height: 60)
                    .background(Color(.accent))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isSaving)
                    
            // 運動計劃名稱
            /*Text(plan.name)
                .font(.title2)
                .foregroundColor(.white.opacity(0.8))
            
            // 統計資訊
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.white)
                    Text("總動作數: \(plan.details.count)")
                        .foregroundColor(.white)
                }
                
                HStack {
                    Image(systemName: "repeat")
                        .foregroundColor(.white)
                    Text("總組數: \(plan.details.reduce(0) { $0 + $1.sets })")
                        .foregroundColor(.white)
                }
            }*/
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(15)
            
            Spacer()
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.myMint))
        .navigationBarHidden(true)
    }
}

#Preview {
    let samplePlan = WorkoutPlan(
        name: "上肢訓練",
        details: [
            
        ]
    )
    
    WorkoutCompleteView(path: .constant([]), plan: samplePlan)
}
