//
//  Workout page.swift
//  01
//
//

import SwiftUI

struct workoutTimingView: View {
    @Binding var path: [PlanRoute]
    let plan: WorkoutPlan
    let exerciseIndex: Int
    let setIndex: Int
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    @State private var remainingSeconds: Int = 0
    @State private var isResting: Bool = false
    @State private var currentRound: Int = 0
    @State private var timer: Timer?

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
                Text("\(isResting ? "休息" : "運動"): \(remainingSeconds)秒")  // 顯示倒數秒數
                    .foregroundColor(Color(.white))
                    .font(.system(size: 20))
                Image(isResting ? "rest" : currentExercise.image_name)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:200,height:200)
                
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
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        // 根據動作ID初始化
        if let idValue = Int(currentExercise.id) {
            if idValue == 7 { // 深蹲：10秒運動 + 5秒休息，重複3次
                currentRound = 1
                remainingSeconds = 10
                isResting = false
            } else if idValue == 9 { // 棒式：30秒運動
                currentRound = 1
                remainingSeconds = 30
                isResting = false
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                handleTimerComplete()
            }
        }
    }
    
    private func handleTimerComplete() {
        if let idValue = Int(currentExercise.id) {
            if idValue == 7 { // 深蹲
                if !isResting && currentRound < 3 {
                    // 運動完成，進入休息
                    isResting = true
                    remainingSeconds = 5
                } else if isResting && currentRound < 3 {
                    // 休息完成，進入下一輪運動
                    isResting = false
                    currentRound += 1
                    remainingSeconds = 10
                } else {
                    // 完成3輪，進入下一個動作或完成
                    completeExercise()
                }
            } else if idValue == 9 { // 棒式
                // 30秒完成，進入下一個動作或完成
                completeExercise()
            }
        }
    }
    
    private func completeExercise() {
        timer?.invalidate()
        
        if exerciseIndex + 1 < plan.details.count {
            // ▶️ 當前動作做完，進入下一個動作
            path.append(.rest(plan: plan, exerciseIndex: exerciseIndex + 1, setIndex: 0))
        } else {
            // 🏁 全部完成
            path.append(.workoutComplete(plan: plan))
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
