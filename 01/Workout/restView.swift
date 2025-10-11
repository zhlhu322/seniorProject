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

    @State private var timeRemaining: Int = 5 // 你可以根據 plan.exercises[exerciseIndex].rest_seconds 設定
    
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
            
            Spacer().frame(height:200)
            
            VStack {
                Text("\(timeRemaining)")
                    .foregroundColor(Color(.white))
                    .font(.system(size: 20))
                Image("rest")
                    .resizable()
                    .frame(width:200,height:200)
                    .padding()
                Text("休息").foregroundColor(Color(.white))
                    .font(.system(size: 32))
            }
            .padding(.bottom,80)
            .onAppear {
                // 固定倒數從 9 到 0
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    } else {
                        timer.invalidate()
                        // 倒數結束後自動回 workoutView
                        path.append(.workout(plan: plan, exerciseIndex: exerciseIndex, setIndex: setIndex))
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
        .background(Color("Mint"))
    }
}

//#Preview {
//    restView(path: .constant([]))
//}
