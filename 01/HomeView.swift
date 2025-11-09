//
//  HomeView.swift
//  01
//
//  Created by 李恩亞 on 2025/4/29.
//

import SwiftUI

struct HomeView: View {
    @Binding var path: [PlanRoute]
    let week = ["週一","週二","週三","週四","週五","週六","週日"]
    @StateObject var viewModel = WorkoutWeekViewModel()
    @StateObject var historyManager = WorkoutHistoryManager.shared
    
    func getDateForWeekdayOffset(_ offset: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today) // 1: Sunday ~ 7: Saturday
        let startOfWeek = calendar.date(byAdding: .day, value: -((weekday + 5) % 7), to: today)!
        return calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        formatter.locale = Locale(identifier: "zh_TW")
        return formatter.string(from: date)
    }
    
    // 根據運動名稱返回對應的圖片名稱
    func getExerciseImageName(_ exerciseName: String) -> String {
        switch exerciseName {
        case "手臂彎舉":
            return "biceps"
        case "肩推":
            return "shoulder_press"
        case "手臂伸展":
            return "elbow_extension"
        case "胸推":
            return "chest_press"
        case "坐姿划船":
            return "seated_row"
        case "超人":
            return "superman"
        case "太空椅深蹲":
            return "wall_squat"
        case "側躺抬腿":
            return "side_leg_raises"
        case "棒式":
            return "plank"
        case "側棒式":
            return "side_plank"
        default:
            return "figure.strengthtraining.traditional"
        }
    }
    
    // 獲取最近運動記錄的所有動作（展開成一維陣列）
    func getAllRecentExercises() -> [(String, String)] {
        var exercises: [(String, String)] = []
        let recentWorkouts = Array(historyManager.recentWorkouts.prefix(3))
        
        for workout in recentWorkouts {
            let workoutExercises = Array(workout.exercises.prefix(3))
            for exercise in workoutExercises {
                // 使用 exerciseId + exerciseName 作為唯一 ID
                let uniqueId = "\(workout.id ?? UUID().uuidString)_\(exercise.exerciseId)"
                exercises.append((uniqueId, exercise.exerciseName))
            }
        }
        
        return exercises
    }
    
    var body: some View {
        ZStack{
            Color(.background).ignoresSafeArea()
            VStack{
                Text("本週運動")
                    .padding(.bottom,10)
                    .padding(.leading,25)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack {
                    ForEach(0..<7) { item in
                        let date = getDateForWeekdayOffset(item)
                        let dateString = viewModel.formattedDate(date)
                        let didWorkout = viewModel.workoutDays.contains(dateString)

                        VStack {
                            Text("\(week[item])").padding(.bottom,15)
                            Image(systemName: "flame.fill")
                                .font(.system(size:28))
                                .foregroundStyle(didWorkout ? .red : Color(.lightGray))
                        }
                        .padding(.horizontal,3)
                    }
                }
                .frame(maxWidth:.infinity)
                .padding()
                .background(Color(.white).opacity(0.5))
                .overlay{RoundedRectangle(cornerRadius:10)
                    .stroke(lineWidth: 1)}
                .padding(.bottom,20)
                .padding(.horizontal,15)
            
                VStack {
                    Text("近期紀錄")
                        .padding(.bottom,10)
                        .padding(.leading,25)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing:15){
                            if historyManager.recentWorkouts.isEmpty {
                                // 沒有運動記錄時顯示提示
                                VStack {
                                    Image(systemName: "figure.walk")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                    Text("還沒有運動記錄")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(width:110,height:120)
                            } else {
                                // 顯示最近運動記錄的動作
                                ForEach(getAllRecentExercises(), id: \.0) { item in
                                    ExerciseCardView(exerciseName: item.1, imageName: getExerciseImageName(item.1))
                                }
                            }
                        }
                        .padding(.horizontal,15)
                    }
                }
                .frame(height:210)
                .background(Color(.white))
                .onAppear {
                    // 載入最近的運動記錄
                    historyManager.loadRecentWorkouts(limit: 5)
                    // 重新載入本週運動記錄
                    viewModel.fetchWorkoutThisWeek()
                }
                
               
                Button(action: {
                    path.append(.choosePlan)
                }) {
                    Text("選擇運動計劃")
                        .font(.title3)
                        .fontWeight(.semibold)
                        
                }
                .frame(width:360,height:70)
                .background(Color(.accent))
                .foregroundStyle(Color(.white))
                .cornerRadius(20)
                .overlay{RoundedRectangle(cornerRadius:20)
                        .stroke(lineWidth: 1)}
                .padding(.top,30)
                .padding(.bottom,30)
                
                HStack{
                    Image("chicken_health")
                        .resizable().scaledToFit()
                        .frame(width:200)
                        .scaleEffect(x: -1, y: 1)
                    
                    Text("呱呱 今天做什麼呢？")
                        .font(.callout)
                        .foregroundStyle(Color("DarkBackgroundColor"))
                        .frame(width: 170, height:50)
                        .overlay(
                            RoundedRectangle(cornerRadius:20)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundStyle(Color(.darkBackground))
                        )
                        .padding(.leading,-30)
                        .padding(.bottom,70)
                }
                Spacer()
                
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("CountBuddy")
                    .font(.system(size: 24 , weight:.semibold))
                    .foregroundColor(.black)
            }
        }
    }
}

// MARK: - 運動動作卡片組件
struct ExerciseCardView: View {
    let exerciseName: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 8) {
            // 顯示動作圖片
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
            
            // 顯示動作名稱
            Text(exerciseName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 110, height: 120)
        .background(Color(.primary).opacity(0.9))
        .cornerRadius(10)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(lineWidth: 1)
        }
    }
}
