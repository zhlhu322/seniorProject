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

    var currentExercise: PlanDetails {
        plan.details[exerciseIndex]
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
                    await LottieAnimation.loadedFrom(url: URL(string: currentExercise.lottie_url)!)
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
            print("進入動作頁面")
            // times = 0 // This line is removed as per the new_code
        }
        .onChange(of: bluetoothManager.currentCount) { oldValue, newValue in
            // 🔸 當運動次數改變時觸發（舊值→oldValue，新值→newValue）
            if newValue >= (currentExercise.targetCount ?? 10) {
                if exerciseIndex + 1 < plan.details.count {
                    // ▶️ 當前動作做完，進入下一個動作
                    // 將 id（字串）轉成 Int
                    if let idValue = Int(plan.details[exerciseIndex + 1].id) {
                        // 乘以 10
                        let multiplied = idValue * 10
                        // 傳送給 micro:bit
                        bluetoothManager.sendActionType(String(multiplied))
                        print("📤 傳送乘以10後的ID: \(multiplied)")
                    } else {
                        print("⚠️ 錯誤：無法將 id 轉成整數，內容為 \(plan.details[exerciseIndex].id)")
                    }
                    // 切換到下一個動作
                    path.append(.rest(plan: plan, exerciseIndex: exerciseIndex + 1, setIndex: 0))
                }
                else {
                    // 🏁 全部完成
                    bluetoothManager.sendActionType(String(0))
                    path.append(.workoutComplete(plan: plan))
                }
            }
        }

    }
}

//#Preview {
//    let sampleExercises = [
//        Exercise(id: "elbow_extension", name:"手臂伸展", sets: 3, targetCount: 15, targetTime: nil, rest_seconds: 30,lottie_url:"https://cdn.lottielab.com/l/9iiJoCxhnaQMY7.json"),
//        Exercise(id: "squat", name:"深蹲", sets: 2, targetCount: 20, targetTime: nil, rest_seconds: 45,lottie_url:"https://cdn.lottielab.com/l/9iiJoCxhnaQMY7.json")
//    ]
//    let samplePlan = WorkoutPlan(name: "上肢訓練", exercises: sampleExercises)
//    
//    workoutView(path: .constant([]), plan: samplePlan, exerciseIndex: 1, setIndex: 0)
//        .environmentObject(BluetoothManager())
//}
