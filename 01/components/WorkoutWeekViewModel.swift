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
        guard let userId = Auth.auth().currentUser?.uid else {
            print("⚠️ 使用者未登入，無法載入本週運動記錄")
            return
        }

        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) // 1: Sunday ~ 7: Saturday
        let startOfWeek = calendar.date(byAdding: .day, value: -((weekday + 5) % 7), to: today)! // 調整成週一
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        
        print("🔍 開始載入本週運動記錄...")
        print("📅 本週範圍: \(startOfWeek) ~ \(endOfWeek)")
        
        // 從 workoutHistory collection 讀取本週的運動記錄
        db.collection("workoutHistory")
            .whereField("userId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 載入本週運動記錄失敗: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("⚠️ 沒有運動記錄")
                    return
                }
                
                print("📦 找到 \(documents.count) 筆運動記錄")
                
                var newWorkoutDays: Set<String> = []
                
                for doc in documents {
                    if let timestamp = doc.data()["completedAt"] as? Timestamp {
                        let workoutDate = timestamp.dateValue()
                        
                        // 檢查是否在本週範圍內
                        if workoutDate >= startOfWeek && workoutDate < endOfWeek {
                            let dateString = self.formattedDate(workoutDate)
                            newWorkoutDays.insert(dateString)
                            print("✅ 本週運動: \(dateString)")
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.workoutDays = newWorkoutDays
                    print("✅ 本週共有 \(self.workoutDays.count) 天運動記錄")
                }
            }
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
