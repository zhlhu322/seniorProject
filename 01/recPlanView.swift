//
//  recPlanView.swift
//  01
//
//  Created by 李恩亞 on 2025/5/19.
//

import SwiftUI

struct WorkoutPlan: Codable, Hashable {  //不能亂改變數名稱！！ 要跟JSON檔中的名稱相同
    let name: String
    let details: [PlanDetails]
}

struct PlanDetails: Identifiable,Codable, Hashable {
    let id: String
    let name: String
    let sets: Int
    let targetCount: Int?
    let targetTime: Int?
    let rest_seconds: Int

    enum CodingKeys: String, CodingKey {
        case id, name, sets, targetCount, targetTime, rest_seconds
    }
}

func loadWorkoutPlans() -> [WorkoutPlan] {
    guard let url = Bundle.main.url(forResource: "workout_recommendations", withExtension: "json"),
          let data = try? Data(contentsOf: url) else {
        print("找不到檔案")
        return []
    }
    do {
        let json = try JSONDecoder().decode([String: [WorkoutPlan]].self, from: data)
        let plans = json["workout_sets"] ?? []
        print("Loaded plans: \(plans)")
        if let first = plans.first {
            print("First plan details: \(first.details)")
        }
        return plans
    } catch {
        print("Decode error: \(error)")
        return []
    }
}

struct WorkoutPlanButtonRow: View {
    let plan: WorkoutPlan
    let isSelected: Bool
    let onTap: () -> Void
    let onInfoTap: () -> Void

    var body: some View {
        workoutPlanButton(
            title: plan.name,
            isSelected: isSelected,
            onTap: onTap,
            onInfoTap: onInfoTap
        )
    }
}

struct recPlanView: View {
    @Binding var path: [PlanRoute]
    @State private var selectedPlan: WorkoutPlan? = nil
    let plans: [WorkoutPlan] = loadWorkoutPlans()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            VStack {
                
                
                ScrollView {
                    Text("熱門動作組")
                        .font(.subheadline)
                        .padding()
                        .frame(maxWidth:UIScreen.main.bounds.width,alignment: .leading)
                    planButtons.padding()
                }
                .frame(width:UIScreen.main.bounds.width)
                .background(Color.white)
                
                
                Button(action: {
                     if let plan = selectedPlan {
                        path.append(.blePairing(plan: plan))
                    }
                }) {
                    Text("開始運動")
                        .font(.system(size: 20, design: .default))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                        .frame(width: 345, height: 64)
                        .background(selectedPlan != nil ? Color.accentColor : Color.gray)
                        .cornerRadius(16)
                }
                .disabled(selectedPlan == nil)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("推薦組合")
        .toolbarBackground(Color(.background), for: .navigationBar)
        //背景色在螢幕往下滑的時候才會出現，不動就是白色
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("Mint"))
                        
                        Text("返回")
                            .foregroundStyle(Color("Mint"))
                    }
                }
            }
        }
        
        
    }
    
    private var planButtons: some View {
        VStack(spacing: 20) {
            ForEach(plans, id: \.self) { plan in
                WorkoutPlanButtonRow(
                    plan: plan,
                    isSelected: selectedPlan == plan,
                    onTap: { selectedPlan = plan },
                    onInfoTap: {
                        selectedPlan = plan
                        path.append(.planInfo(plan))
                    }
                )
            }
        }
    }
}

#Preview {
    recPlanView(path: .constant([]))
}
