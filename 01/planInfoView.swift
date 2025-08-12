//
//  planInfoView.swift
//  01
//
//  Created by 李恩亞 on 2025/7/9.
//(crashed if opened)
//

import SwiftUI


struct planInfoView: View {
    let plan: WorkoutPlan
    @Binding var path: [PlanRoute]
    @State private var allDetails: [ExerciseDetail] = []  //先載入全部的運動（workout_exercises）
    
    var matchedDetails: [ExerciseDetail] {
        allDetails.filter { detail in
            plan.details.contains(where: { $0.id == detail.id })
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment:.leading, spacing: 16) {
                Text("動作組")
                    .font(.title2)
                    .padding(.top)
                
                Divider()
                
                ForEach(matchedDetails) { detail in
                    exerciseInfoButton(
                        title: detail.name,
                        onTap: { path.append(.exerciseDetail(detail)) },
                        imageURL:detail.image_name,
                        onSelect: nil,
                        isSelected: nil
                    )
                }
               
            }
        }
        .padding()
        .navigationTitle(plan.name)
        .onAppear {
            allDetails = loadAllExerciseDetails()
        }
        .toolbarBackground(Color("PrimaryColor"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}


//#Preview {
//    let sampleExercises = [
//        Exercise(id: "elbow_extension", name:"手臂伸展", sets: 3, targetCount: 15, targetTime: nil, rest_seconds: 30,lottie_url:"https://cdn.lottielab.com/l/9iiJoCxhnaQMY7.json"),
//        Exercise(id: "squat", name:"深蹲", sets: 2, targetCount: 20, targetTime: nil, rest_seconds: 45,lottie_url:"https://cdn.lottielab.com/l/9iiJoCxhnaQMY7.json")
//    ]
//
//    let samplePlan = WorkoutPlan(name: "上肢訓練", exercises: sampleExercises)
//
//    
//    
//    // 如果有用到 ExerciseDetail，也提供對應的 sample detail
//    let sampleDetails = [
//        ExerciseDetail(
//            id: "elbow_extension",
//            name: "手臂伸展",
//            image_name: "elbow_extension",
//            target_muscle: "三頭肌",
//            equipment: "彈力帶",
//            type: "力量訓練",
//            band_position: "腳底",
//            steps: ["站立姿勢", "彎曲手肘", "伸直手臂"],
//            strength: 3,
//            endurance: 2,
//            flexibility: 1
//        )
//    ]
//    exerciseInfoButton(title: "手臂伸展", onTap: {},ImageURL: "biceps")
//    planInfoView(plan: samplePlan, path: .constant([]))
//    
//}





