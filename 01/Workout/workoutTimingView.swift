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
    @State private var hasCompletedExercise = false

    var currentExercise: PlanDetails {
        plan.details[exerciseIndex]
    }

    private var lottieURL: URL? {
        URL(string: currentExercise.lottie_url)
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
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("倒數")
                        Text("計時")
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 35))

                    Text("\(remainingSeconds)")
                        .foregroundColor(.white)
                        .font(.system(size: 80, weight: .bold))

                    Text("秒")
                        .foregroundColor(.white)
                        .font(.system(size: 35))
                        .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)

                if let lottieURL {
                    ExerciseLottieView(url: lottieURL)
                        .frame(width: 220, height: 220)
                } else {
                    Image(currentExercise.image_name)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 220, height: 220)
                }
                
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
        timer?.invalidate()
        hasCompletedExercise = false
        currentRound = 1
        remainingSeconds = 30
        isResting = false
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                handleTimerComplete()
            }
        }
    }
    
    private func handleTimerComplete() {
        completeExercise()
    }
    
    private func completeExercise() {
        guard !hasCompletedExercise else { return }
        hasCompletedExercise = true
        timer?.invalidate()
        
        if exerciseIndex + 1 < plan.details.count {
            // ▶️ 當前動作做完，進入下一個動作
            let nextExerciseID = plan.details[exerciseIndex + 1].id
            bluetoothManager.sendActionType(nextExerciseID)
            print("📤 傳送下一個動作ID: \(nextExerciseID)")
            path.append(.rest(plan: plan, exerciseIndex: exerciseIndex + 1, setIndex: 0))
        } else {
            // 🏁 全部完成
            bluetoothManager.sendActionType(String(0))
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
