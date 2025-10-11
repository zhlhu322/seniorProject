//
//  LevelUpView.swift
//  01
//
//  Created by 李橘亞 on 2025/4/6.
//

import SwiftUI

struct LevelUpView: View {
    @Binding var path: [PlanRoute]
    @State private var showReward = false
    @State private var currentXP = 45
    @State private var maxXP = 100
    @State private var gainedXP = 15
    
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
                            Text("氨基酸 x 30")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("PrimaryColor"))
                        .cornerRadius(12)
                        
                        // 咖哩飯
                        HStack(spacing: 8) {
                            Image("curry")
                                .resizable()
                                .frame(width: 30, height: 30)
                            Text("咖哩飯 x 1")
                                .font(.subheadline)
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
                .padding(.horizontal, 30) // 左右留空
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
                            // 背景進度條
                            Rectangle()
                                .fill(Color.brown)
                                .frame(height: 15)
                                .cornerRadius(4)
                            
                            // 已填充進度條
                            Rectangle()
                                .fill(Color(.accent))
                                .frame(width: geometry.size.width * CGFloat(currentXP) / CGFloat(maxXP), height: 15)
                                .cornerRadius(4)
                        }
                        .frame(height: 8)
                    }
                    .frame(height: 8)
                    
                    // 三個能力值卡片
                    HStack(spacing: 15) {
                        // 力量
                        VStack(spacing: 8) {
                            Text("力量")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Text("+5")
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
                            Text("+7")
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
                            Text("+3")
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
                .padding(.horizontal, 30) // 左右留空
            }
            
            Spacer()
            
            // 按鈕區域
            VStack(spacing: 15) {
                Button(action: {
                    if !showReward {
                        // 第一次按鈕:顯示獎勵動畫
                        withAnimation(.easeInOut(duration: 0.8)) {
                            showReward = true
                        }
                    } else {
                        // 第二次按鈕:跳轉到首頁
                        path.append(.home)
                    }
                }) {
                    Text("繼續")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.accent))
                        .cornerRadius(15)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("BackgroundColor"))
        .navigationBarHidden(true)
        .animation(.easeInOut(duration: 0.8), value: showReward)
    }
}

#Preview {
    LevelUpView(path: .constant([]))
}