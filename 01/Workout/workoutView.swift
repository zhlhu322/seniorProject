//
//  Workout page.swift
//  01
//
//  Created by 李恩亞 on 2025/4/6.
//

import SwiftUI
import Lottie

struct workoutView: View {
    @Binding var path: [PlanRoute]
    let plan: WorkoutPlan
    let exerciseIndex: Int
    let setIndex: Int
    @EnvironmentObject var bluetoothManager: BluetoothManager

    var currentExercise: Exercise {
        plan.exercises[exerciseIndex]
    }

    var body: some View {
        VStack(alignment: .center) {
            HStack{
                Button(action:{
                    
                }){
                    Image(systemName: "xmark")
                        .font(.system(size: 25, weight: .black))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Text(" \(setIndex+1)/\(currentExercise.sets)") // 顯示目前是第幾組
                    .font(.system(size: 25))
                    .foregroundColor(Color(.white))
                    .frame(maxWidth: .infinity, alignment: .center)
                Image(systemName: "pause")
                    .font(.system(size: 25, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            
            Spacer()
                .frame(height:UIScreen.main.bounds.height*0.15)
            
            VStack {
                Text("次數: \(bluetoothManager.currentCount)/\(currentExercise.targetCount ?? 1)")  // 顯示目前次數
                    .foregroundColor(Color(.white))
                    .font(.system(size: 20))
                LottieView {
                    await LottieAnimation.loadedFrom(url: URL(string: currentExercise.lottie_url)! )
                }
                .playing(loopMode:.loop)
                .resizable()
                .frame(width:300,height:300)
                
                Text("\(currentExercise.name)")
                    .font(.title)
                    .foregroundStyle(Color(.white))
            }
            .padding(.bottom,80)
            
            Spacer()
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("PrimaryColor"))
        .onAppear {
            // times = 0 // This line is removed as per the new_code
        }
        .onChange(of: bluetoothManager.currentCount) { newCount in
            if newCount >= (currentExercise.targetCount ?? 1) {
                bluetoothManager.sendActionType("0", count: 0)
                // 決定下一步
                let nextSet = setIndex + 1
                if nextSet < currentExercise.sets {
                    // 還有下一組，進入 rest
                    path.append(.rest(plan: plan, exerciseIndex: exerciseIndex, setIndex: nextSet))
                } else if exerciseIndex + 1 < plan.exercises.count {
                    // 換下一個動作
                    path.append(.rest(plan: plan, exerciseIndex: exerciseIndex + 1, setIndex: 0))
                } else {
                    // 全部完成
                    path.append(.home)
                }
            }
        }
    }
}

#Preview {
    let sampleExercises = [
        Exercise(id: "elbow_extension", name:"手臂伸展", sets: 3, targetCount: 15, targetTime: nil, rest_seconds: 30,lottie_url:"https://cdn.lottielab.com/l/9iiJoCxhnaQMY7.json"),
        Exercise(id: "squat", name:"深蹲", sets: 2, targetCount: 20, targetTime: nil, rest_seconds: 45,lottie_url:"https://cdn.lottielab.com/l/9iiJoCxhnaQMY7.json")
    ]
    let samplePlan = WorkoutPlan(name: "上肢訓練", exercises: sampleExercises)
    
    workoutView(path: .constant([]), plan: samplePlan, exerciseIndex: 1, setIndex: 0)
        .environmentObject(BluetoothManager())
}
