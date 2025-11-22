//
//  MyChickenMeatView.swift
//  01
//
//  Created by 李橋亞 on 2025/5/2.
//

import SwiftUI

struct MyChickenMeatView: View {
    @ObservedObject private var chickenManager = MyChickenManager.shared
    @State private var isLoading = false
    @State private var loadError: String?
    
    // 根據 XP 計算階段
    private var stageName: String {
        let xp = chickenManager.xp
        if xp < 30 {
            return "寶寶肌胸"
        } else if xp < 60 {
            return "健康肌胸"
        } else if xp < 100 {
            return "強壯肌胸"
        } else if xp < 150 {
            return "完美肌胸"
        } else {
            return "終極肌胸"
        }
    }
    
    // 最大 XP（用於進度條）
    private let maxXP: Int = 100
    
    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView("載入中...")
                    .foregroundColor(Color(.darkBackground))
            } else if let error = loadError {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text("載入失敗")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("重試") {
                        loadChickenData()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                VStack(spacing: 0) {
                    // MARK: - 頂部導航列
                    HStack {
                        // 左上角按鈕（可自訂功能）
                        Button(action: {
                            // TODO: 左上角按鈕功能
                        }) {
                            Image("store")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color("PrimaryColor"))
                                .cornerRadius(10)
                        }
                        .overlay{RoundedRectangle(cornerRadius:10)
                            .stroke(lineWidth: 1)}
                        
                        Spacer()
                        
                        // 標題
                        Text("我的肌胸肉")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(.darkBackground))
                        
                        Spacer()
                        
                        // 右上角氨基酸顯示
                        HStack(spacing: 5) {
                            Image("animo_acid")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("x \(chickenManager.aminoCoin)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color("PrimaryColor"))
                        .cornerRadius(10)
                        .overlay{RoundedRectangle(cornerRadius:10)
                            .stroke(lineWidth: 1)}
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // MARK: - 主要內容區
                    HStack(alignment: .top, spacing: 15) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("階段")
                                .font(.caption)
                                .foregroundColor(Color(.darkBackground).opacity(0.7))
                            Text(stageName)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.darkBackground))
                        }
                        .padding(20)
                        .frame(width: 140, height: 100)
                        .background(
                            Image("chicken_stageBG")
                                .resizable()
                                .scaledToFill()
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        
                        Spacer()
                        
                        // 右側：XP 和屬性
                        VStack(alignment: .leading, spacing: 10) {
                            // XP 進度條
                            VStack(alignment: .leading, spacing: 5) {
                                Text("XP \(chickenManager.xp)/\(maxXP)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(.darkBackground))
                                
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        // 背景
                                        Rectangle()
                                            .fill(Color.brown.opacity(0.3))
                                            .cornerRadius(6)
                                        
                                        // 進度條
                                        if maxXP > 0 {
                                            Rectangle()
                                                .fill(Color("PrimaryColor"))
                                                .frame(width: max(0, min(geometry.size.width, geometry.size.width * CGFloat(min(chickenManager.xp, maxXP)) / CGFloat(maxXP))))
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                                .frame(height: 12)
                            }
                            
                            // 三個屬性
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("力量：")
                                        .font(.subheadline)
                                        .foregroundColor(Color(.darkBackground))
                                    Text("\(chickenManager.strength)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(.darkBackground))
                                }
                                
                                HStack {
                                    Text("耐力：")
                                        .font(.subheadline)
                                        .foregroundColor(Color(.darkBackground))
                                    Text("\(chickenManager.endurance)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(.darkBackground))
                                }
                                
                                HStack {
                                    Text("柔軟度：")
                                        .font(.subheadline)
                                        .foregroundColor(Color(.darkBackground))
                                    Text("\(chickenManager.flexibility)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(.darkBackground))
                                }
                            }
                        }
                        .frame(width: 150)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    // MARK: - 角色圖片
                    Image(chickenManager.Stage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 180, height: 216)
                    
                    Spacer()
                    
                    // MARK: - 底部按鈕
                    HStack(spacing: 20) {
                        // 調味按鈕
                        Button(action: {
                            // TODO: 實現調味功能
                        }) {
                            Text("調味")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("PrimaryColor"))
                                .cornerRadius(15)
                        }
                        
                        // 造型按鈕
                        Button(action: {
                            // TODO: 實現造型功能
                        }) {
                            Text("造型")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("PrimaryColor"))
                                .cornerRadius(15)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if chickenManager.xp == 0 && chickenManager.strength == 0 {
                loadChickenData()
            }
        }
    }
    
    // MARK: - 載入小雞資料
    private func loadChickenData() {
        isLoading = true
        loadError = nil
        
        chickenManager.loadChickenData { error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    loadError = error.localizedDescription
                    print("❌ 載入小雞資料失敗: \(error.localizedDescription)")
                } else {
                    print("✅ 小雞資料已載入")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MyChickenMeatView()
    }
}
