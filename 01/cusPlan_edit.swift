//
//  cusPlan_edit.swift
//  01
//
//  Created by 李恩亞 on 2025/8/3.
//

import SwiftUI

struct cusPlan_edit: View {
    
    @Binding var path: [PlanRoute]
    let selectedExerciseIDs: Set<String>
    
    @State private var allDetails: [ExerciseDetail] = []  //先載入全部的運動（workout_exercises）
    
    @State private var selectedExercise: [ExerciseDetail] = []

    private var customWorkoutPlan: WorkoutPlan {
        WorkoutPlan(
            name: "自訂組合",
            details: selectedExercise.map { detail in
                return PlanDetails(
                    id: detail.id,
                    name: detail.name,
                    sets: 1,
                    targetCount: detail.isTimedExercise ? nil : 5,
                    targetTime: detail.isTimedExercise ? 30 : nil,
                    rest_seconds: 10,
                    lottie_url: detail.lottie_url,
                    image_name: detail.image_name
                )
            }
        )
    }

    
    var body: some View {
        
        VStack{
            
            Text("已選動作組合")
                .padding(.horizontal)
                .padding(.top, 10)
                .frame(maxWidth: .infinity,alignment: .leading)
            
            List($selectedExercise, editActions: .move){ $exercise in
                    HStack{
                        Text(exercise.name)
                            .foregroundStyle(Color(.background))
                        Spacer()
                        Text(exercise.isTimedExercise ? "計時" : "計次")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(.accent))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(.background))
                            .cornerRadius(10)
                        Image(systemName: "minus.circle.fill")
                            .frame(width:40, height:40)
                            .foregroundStyle(Color(.background))
                            .opacity(0.8)
                    }
                    .padding(.horizontal)
                    .frame(width:UIScreen.main.bounds.width*0.9 ,height:64)
                    .background(Color(.accent))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(lineWidth: 1)
                            .foregroundColor(.accent)
                    )
                    
                }
                .scrollContentBackground(.hidden) // 隱藏背景
                .background(Color.clear)
                .onAppear {
                    allDetails = loadAllExerciseDetails()
                    selectedExercise = allDetails.filter {
                        selectedExerciseIDs.contains($0.id) }
                    print(selectedExercise)
                }

            Button(action: {
                path.append(.blePairing(plan: customWorkoutPlan))
            }) {
                Text("開始運動")
                    .font(.system(size: 20, design: .default))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white)
                    .frame(width: 345, height: 64)
                    .background(selectedExercise.isEmpty ? Color.gray : Color.accentColor)
                    .cornerRadius(16)
            }
            .disabled(selectedExercise.isEmpty)
            .padding(.bottom, 30)
        }
        
    }
    
}




#Preview {
    cusPlan_edit(path: .constant([]), selectedExerciseIDs: .init())
}
