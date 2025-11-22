//
//  LevelUpView.swift
//  01
//
//  Created by 許雅涵 on 2025/10/27.
//

import SwiftUI

struct LevelUpView: View {
    @Binding var path: [PlanRoute]
    let plan: WorkoutPlan
    @ObservedObject private var chickenManager = MyChickenManager.shared
    @State private var showReward = false
    @State private var currentXP = 0
    @State private var maxXP = 0
    @State private var isLoading = false
    @State private var isUpdating = false
    @State private var hasLoadedData = false
    
    // 每個動作對應的能力值加成
    private let exerciseStats: [String: (strength: Int, endurance: Int, flexibility: Int)] = [
        "手臂彎舉": (2, 1, 0),
        "肩推": (2, 1, 1),
        "手臂伸展": (2, 0, 2),
        "胸推": (3, 1, 0),
        "划船": (3, 1, 0),
        "超人": (1, 2, 1),
        "靠牆太空椅深蹲": (2, 3, 0),
        "側躺抬腿": (1, 2, 1),
        "棒式": (1, 3, 0),
        "側棒式": (1, 3, 0)
    ]
    
    // 計算總能力值
    private var totalStrength: Int {
        plan.details.reduce(0) { total, detail in
            total + (exerciseStats[detail.name]?.strength ?? 0)
        }
    }
    
    private var totalEndurance: Int {
        plan.details.reduce(0) { total, detail in
            total + (exerciseStats[detail.name]?.endurance ?? 0)
        }
    }
    
    private var totalFlexibility: Int {
        plan.details.reduce(0) { total, detail in
            total + (exerciseStats[detail.name]?.flexibility ?? 0)
        }
    }
    
    // 計算健身分數（無條件進位）
    private var fitnessScore: Int {
        let score = (1.2 * Double(totalStrength) + 1.0 * Double(totalEndurance) + 0.8 * Double(totalFlexibility)) / 3.0
        return Int(ceil(score))
    }
    
    // 計算獲得的氨基酸（無條件進位）
    private var aminoCoin: Int {
        return Int(ceil(Double(fitnessScore) / 3.0))
    }
    
    // XP 增加量等於健身分數
    private var gainedXP: Int {
        return fitnessScore
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            // 升級標題
            if showReward {
                Text("獎勵一下!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.accent))
            } else {
                Text("Level Up!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.accent))
            }
            
            Image("chicken_strong")
                .resizable()
                .frame(width: 200, height: 240)
                .padding()
            
            // showReward 顯示的內容
            if showReward {
                VStack(alignment: .leading, spacing: 15) {
                    Text("運動獎勵")
                        .font(.headline)
                        .foregroundColor(Color.brown)
                    
                    HStack(spacing: 15) {
                        // 氨基酸
                        HStack(spacing: 8) {
                            Image("animo_acid")
                                .resizable()
                                .frame(width: 30, height: 30)
                            Text("氨基酸 x \(aminoCoin)")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(Color("PrimaryColor"))
                        .cornerRadius(12)
                        
                        // 咖哩飯（固定 1 個）
                        HStack(spacing: 8) {
                            Image("curry")
                                .resizable()
                                .frame(width: 30, height: 30)
                            Text("咖哩飯 x 1")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 80)
                        .background(Color("PrimaryColor"))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .cornerRadius(15)
                .padding(.horizontal, 30)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            } else {
                VStack(spacing: 15) {
                    HStack {
                        Text("XP \(currentXP)/\(maxXP)")
                            .font(.headline)
                            .foregroundColor(Color.brown)
                        
                        Spacer()
                        
                        Text("+\(gainedXP)")
                            .font(.headline)
                            .foregroundColor(Color.brown)
                    }
                    
                    // 經驗值進度條
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.brown)
                                .cornerRadius(4)
                            
                            if maxXP > 0 {
                                Rectangle()
                                    .fill(Color(.accent))
                                    .frame(width: max(0, min(geometry.size.width, geometry.size.width * CGFloat(currentXP) / CGFloat(maxXP))))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .frame(height: 15)
                    
                    // 三個能力值卡片（顯示實際計算結果）
                    HStack(spacing: 15) {
                        // 力量
                        VStack(spacing: 8) {
                            Text("力量")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("+\(totalStrength)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("PrimaryColor"))
                        .cornerRadius(12)
                        
                        // 耐力
                        VStack(spacing: 8) {
                            Text("耐力")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("+\(totalEndurance)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("PrimaryColor"))
                        .cornerRadius(12)
                        
                        // 柔軟度
                        VStack(spacing: 8) {
                            Text("柔軟度")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("+\(totalFlexibility)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("PrimaryColor"))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .cornerRadius(15)
                .padding(.horizontal, 30)
            }
            
            Spacer()
            
            // 按鈕區域
            VStack(spacing: 15) {
                Button(action: {
                    if !showReward {
                        // 更新小雞資料到 Firebase
                        updateChickenData()
                        withAnimation(.easeInOut(duration: 0.8)) {
                            showReward = true
                        }
                    } else {
                        path.append(.home)
                    }
                }) {
                    HStack {
                        if isUpdating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 5)
                        }
                        Text(isUpdating ? "更新中..." : (showReward ? "繼續" : "領取獎勵"))
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.accent))
                    .cornerRadius(15)
                }
                .disabled(isUpdating || isLoading)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundColor"))
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.8), value: showReward)
        .onAppear {
            if !hasLoadedData {
                loadChickenData()
            }
            print("📋 Plan 內容:")
            print("計劃名稱: \(plan.name)")
            print("動作數量: \(plan.details.count)")
            print("--- 能力值計算 ---")
            print("力量: +\(totalStrength)")
            print("耐力: +\(totalEndurance)")
            print("柔軟度: +\(totalFlexibility)")
            print("健身分數: \(fitnessScore)")
            print("獲得氨基酸: \(aminoCoin)")
            print("獲得 XP: \(gainedXP)")
        }
    }
    
    // MARK: - 載入小雞資料
    private func loadChickenData() {
        isLoading = true
        chickenManager.loadChickenData { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    print("❌ 載入小雞資料失敗: \(error.localizedDescription)")
                } else {
                    hasLoadedData = true
                    currentXP = chickenManager.xp
                    maxXP = 100  // 可以根據需要調整
                    print("✅ 小雞資料已載入")
                    print("當前 XP: \(chickenManager.xp)")
                    print("當前力量: \(chickenManager.strength)")
                    print("當前耐力: \(chickenManager.endurance)")
                    print("當前柔軟度: \(chickenManager.flexibility)")
                    print("當前氨基酸: \(chickenManager.aminoCoin)")
                }
            }
        }
    }
    
    // MARK: - 更新小雞資料
    private func updateChickenData() {
        guard hasLoadedData else {
            print("⚠️ 資料尚未載入，無法更新")
            return
        }
        
        isUpdating = true
        
        // 先保存舊值以便打印
        let oldXP = chickenManager.xp
        let oldStrength = chickenManager.strength
        let oldEndurance = chickenManager.endurance
        let oldFlexibility = chickenManager.flexibility
        let oldAminoCoin = chickenManager.aminoCoin
        let oldCurry = chickenManager.flavoring["curry"] ?? 0
        
        // 計算新的數值
        let newXP = oldXP + gainedXP
        let newStrength = oldStrength + totalStrength
        let newEndurance = oldEndurance + totalEndurance
        let newFlexibility = oldFlexibility + totalFlexibility
        let newAminoCoin = oldAminoCoin + aminoCoin
        
        // 更新咖哩飯數量（+1）
        var updatedFlavoring = chickenManager.flavoring
        updatedFlavoring["curry"] = oldCurry + 1
        
        // 更新到 MyChickenManager
        chickenManager.xp = newXP
        chickenManager.strength = newStrength
        chickenManager.endurance = newEndurance
        chickenManager.flexibility = newFlexibility
        chickenManager.aminoCoin = newAminoCoin
        chickenManager.flavoring = updatedFlavoring
        
        print("📊 更新小雞資料:")
        print("  XP: \(oldXP) -> \(newXP) (+\(gainedXP))")
        print("  力量: \(oldStrength) -> \(newStrength) (+\(totalStrength))")
        print("  耐力: \(oldEndurance) -> \(newEndurance) (+\(totalEndurance))")
        print("  柔軟度: \(oldFlexibility) -> \(newFlexibility) (+\(totalFlexibility))")
        print("  氨基酸: \(oldAminoCoin) -> \(newAminoCoin) (+\(aminoCoin))")
        print("  咖哩飯: \(oldCurry) -> \(updatedFlavoring["curry"] ?? 0) (+1)")
        
        // 更新到 Firebase
        chickenManager.updateChickenData { error in
            DispatchQueue.main.async {
                isUpdating = false
                if let error = error {
                    print("❌ 更新小雞資料到 Firebase 失敗: \(error.localizedDescription)")
                } else {
                    print("✅ 小雞資料已成功更新到 Firebase")
                    currentXP = newXP
                }
            }
        }
    }
}

#Preview {
    let samplePlan = WorkoutPlan(
        name: "測試計畫",
        details: []
    )
    
    LevelUpView(path: .constant([]), plan: samplePlan)
}
