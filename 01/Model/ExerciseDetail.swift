import Foundation
import SwiftUI

struct ExerciseDetail: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let image_name: String
    let lottie_url: String
    let target_muscle: String
    let equipment: String
    let type: String
    let band_position: String
    let steps: [String]
    let strength: Int?
    let endurance: Int?
    let flexibility: Int?
}

func loadAllExerciseDetails() -> [ExerciseDetail] {
    guard let url = Bundle.main.url(forResource: "workout_exercises", withExtension: "json"),
          let data = try? Data(contentsOf: url) else {
        print("找不到檔案")
        return []
    }
    do {
        let json = try JSONDecoder().decode([String: [ExerciseDetail]].self, from: data)
        return json["exercises"] ?? []
    } catch let DecodingError.keyNotFound(key, context) {
        print("Missing key: \(key) – \(context.debugDescription)")
        return []
    } catch let DecodingError.typeMismatch(type, context) {
        print("Type mismatch: \(type) – \(context.debugDescription)")
        return []
    } catch {
        print("Decode error: \(error)")
        return []
    }

}
