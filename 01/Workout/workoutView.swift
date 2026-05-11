//
//  Workout page.swift
//  01
//
//

import SwiftUI
import Lottie

struct workoutView: View {
    @Binding var path: [PlanRoute]
    let plan: WorkoutPlan
    let exerciseIndex: Int
    let setIndex: Int
    @EnvironmentObject var bluetoothManager: BluetoothManager
    private let exerciseAnimationSize: CGFloat = 180
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
                // 次數文字靠左
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("目前")
                        Text("次數")
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 35))
                    
                    Text("\(bluetoothManager.currentCount)/\(currentExercise.targetCount ?? 1)")
                        .foregroundColor(.white)
                        .font(.system(size: 80, weight: .bold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                
                // 動畫獨立一層，不與文字重疊
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
            hasCompletedExercise = false
            bluetoothManager.currentCount = 0
            UIApplication.shared.isIdleTimerDisabled = true  // 運動中禁止螢幕自動休眠
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false // 離開後恢復正常休眠
        }
        .onChange(of: bluetoothManager.currentCount) { oldValue, newValue in
            guard !hasCompletedExercise else { return }

            // 🔸 當運動次數改變時觸發（舊值→oldValue，新值→newValue）
            if newValue >= (currentExercise.targetCount ?? 10) {
                hasCompletedExercise = true

                if exerciseIndex + 1 < plan.details.count {
                    // ▶️ 當前動作做完，進入下一個動作
                    let nextExerciseID = plan.details[exerciseIndex + 1].id
                    bluetoothManager.sendActionType(nextExerciseID)
                    print("📤 傳送下一個動作ID: \(nextExerciseID)")
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

struct ExerciseLottieView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView()
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop
        view.clipsToBounds = false
        loadAnimation(into: view, context: context)
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        guard context.coordinator.currentURL != url else { return }
        loadAnimation(into: uiView, context: context)
    }

    private func loadAnimation(into view: LottieAnimationView, context: Context) {
        context.coordinator.currentURL = url

        LottieAnimation.loadedFrom(url: url, closure: { animation in
            DispatchQueue.main.async {
                guard let animation else {
                    print("Lottie 動畫載入失敗: \(url.absoluteString)")
                    return
                }

                view.stop()
                view.animation = animation
                view.play()
            }
        }, animationCache: nil)
    }

    final class Coordinator {
        var currentURL: URL?
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
