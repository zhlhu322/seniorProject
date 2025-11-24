import SwiftUI

enum PlanRoute: Hashable {
    case home
    case choosePlan
    case recPlan
    case cusPlan
    case cusPlan_edit(selectedExerciseIDs: Set<String>)
    case planInfo(WorkoutPlan)
    case blePairing(plan: WorkoutPlan)
    case workoutTiming(plan: WorkoutPlan, exerciseIndex: Int, setIndex: Int)
    case workout(plan: WorkoutPlan, exerciseIndex: Int, setIndex: Int)
    case rest(plan: WorkoutPlan, exerciseIndex: Int, setIndex: Int)
    case workoutComplete(plan: WorkoutPlan)
    case levelup(plan: WorkoutPlan)
    case signUp
    case signUp2
    case signIn
    case exerciseDetail(ExerciseDetail)
}

struct ContentView: View {
    @State private var path: [PlanRoute] = []
    var body: some View {
        NavigationStack(path: $path) {
            IntroView(path: $path)
                .navigationDestination(for: PlanRoute.self) { route in
                    switch route {
                    case .home:
                        HomeView(path: $path)
                    case .choosePlan:
                        workoutPlanTypeView(path: $path)
                    case .signUp:
                        signUpView(path: $path)
                    case .signUp2:
                        signUpView2(path: $path)
                    case .signIn:
                        signInView(path: $path)
                    case .recPlan:
                        recPlanView(path: $path)
                    case .cusPlan:
                        cusPlanView(path:$path)
                    case .cusPlan_edit(let selectedExerciseIDs):
                        cusPlan_edit(path: $path, selectedExerciseIDs: selectedExerciseIDs)
                    case .planInfo(let plan):
                        planInfoView(plan: plan, path: $path)
                    case .blePairing(let plan):
                        blePairingView(path: $path, plan: plan)
                            .environmentObject(BluetoothManager())
                    case .workout(let plan, let exerciseIndex, let setIndex):
                        workoutView(path: $path, plan: plan, exerciseIndex: exerciseIndex, setIndex: setIndex)
                            .environmentObject(BluetoothManager())
                    case .workoutTiming(let plan, let exerciseIndex, let setIndex):
                        workoutTimingView(path: $path, plan: plan, exerciseIndex: exerciseIndex, setIndex: setIndex)
                            .environmentObject(BluetoothManager())
                    case .rest(let plan, let exerciseIndex, let setIndex):
                        restView(path: $path, plan: plan, exerciseIndex: exerciseIndex, setIndex: setIndex)
                            .environmentObject(BluetoothManager())
                    case .workoutComplete(let plan):
                        WorkoutCompleteView(path: $path, plan: plan)
                    case .levelup(let plan):
                        LevelUpView(path: $path, plan: plan)
                    case .exerciseDetail(let detail):
                        exerciseDetailView(detail: detail)
                    }
                }
        }
    }
}
