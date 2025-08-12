import Foundation
import FirebaseAuth
import FirebaseFirestore

class WorkoutWeekViewModel: ObservableObject {
    @Published var workoutDays: Set<String> = [] // 儲存格式："2025-07-29"

    private let db = Firestore.firestore()
    
    init() {
        fetchWorkoutThisWeek()
    }

    func fetchWorkoutThisWeek() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) // 1: Sunday ~ 7: Saturday
        let startOfWeek = calendar.date(byAdding: .day, value: -((weekday + 5) % 7), to: today)! // 調整成週一

        for offset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
            let dateString = formattedDate(date)
            let docRef = db.collection("users").document(userId)
                .collection("workouts").document(dateString)
            
            docRef.getDocument { docSnapshot, error in
                if let data = docSnapshot?.data(),
                   let didWorkout = data["didWorkout"] as? Bool,
                   didWorkout {
                    DispatchQueue.main.async {
                        self.workoutDays.insert(dateString)
                    }
                }
            }
        }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
