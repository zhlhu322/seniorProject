//
//  restView.swift
//  01
//
//  Created by 李恩亞 on 2025/5/12.
//

import SwiftUI

struct restView: View {
    @Binding var path: [PlanRoute]
    let plan: WorkoutPlan
    let exerciseIndex: Int
    let setIndex: Int
    
    @State private var timeRemaining: Int = 10 // 你可以根據 plan.exercises[exerciseIndex].rest_seconds 設定
    
    var currentExercise: PlanDetails {
        plan.details[exerciseIndex]
    }
    
    var body: some View {
        VStack{
            HStack{
                Image(systemName: "xmark")
                    .font(.system(size: 25, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Image(systemName: "pause")
                    .font(.system(size: 25, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            
            Spacer().frame(height:100)
            
            VStack {
                Text("休息").foregroundColor(Color(.white))
                    .font(.system(size: 32))
                Text("倒數計時：\(timeRemaining)")
                    .foregroundColor(Color(.white))
                    .font(.system(size: 20))
                ZStack {
                    Color("PrimaryColor")        // 背景色
                        .frame(width: 300, height: 300)
                        .cornerRadius(20)
                    Image(currentExercise.image_name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                        .padding()
                }
            }
            Text("預備動作：\(currentExercise.name)")
                .foregroundColor(Color(.white))
                .font(.system(size: 28))
                .padding(.bottom,80)
                .onAppear {
                    // 固定倒數從 9 到 0
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                        if timeRemaining > 0 {
                            timeRemaining -= 1
                        } else {
                            timer.invalidate()
                            // 倒數結束後自動回 workoutView
                            if let idValue = Int(currentExercise.id), idValue >= 6 {
                                path.append(.workoutTiming(plan: plan, exerciseIndex: exerciseIndex, setIndex: setIndex))
                            }
                            else{
                                path.append(.workout(plan: plan, exerciseIndex: exerciseIndex, setIndex: setIndex))
                            }
                        }
                    }
                    /*enya origin edtion
                     timeRemaining = plan.details[exerciseIndex].rest_seconds
                     Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                     if timeRemaining > 0 {
                     timeRemaining -= 1
                     } else {
                     timer.invalidate()
                     // 回到 workoutView
                     path.append(.workout(plan: plan, exerciseIndex: exerciseIndex, setIndex: setIndex))
                     }
                     }*/
                }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.myMint))
    }
}

//#Preview {
//    restView(path: .constant([]))
//}
