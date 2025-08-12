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
        }
        
    }
    
}




#Preview {
    cusPlan_edit(path: .constant([]), selectedExerciseIDs: .init())
}
