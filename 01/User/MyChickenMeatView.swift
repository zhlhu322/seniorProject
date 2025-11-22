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
                ScrollView {
                    VStack(spacing: 20) {
                        // 頂部氨基酸顯示
                        HStack {
                            Spacer()
                            HStack(spacing: 5) {
                                Image("animo_acid")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text("x \(chickenManager.aminoCoin)")
                                    .font(.subheadline)
                                    .foregroundColor(Color(.darkBackground))
                            }
                            .padding(.trailing)
                        }
                        .padding(.top, 10)
                        
                        // 標題
                        Text("我的肌胸肉")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color(.darkBackground))
                            .padding(.top, 10)
                        
                        // 階段顯示
                        HStack {
                            Text("階段")
                                .font(.caption)
                                .foregroundColor(Color(.darkBackground))
                            Text(stageName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(.darkBackground))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color(.myMint))
                        .cornerRadius(20)
                        
                        // XP 進度條
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("XP \(chickenManager.xp)/\(maxXP)")
                                    .font(.headline)
                                    .foregroundColor(Color(.darkBackground))
                                Spacer()
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // 背景
                                    Rectangle()
                                        .fill(Color.brown.opacity(0.3))
                                        .cornerRadius(8)
                                    
                                    // 進度條
                                    if maxXP > 0 {
                                        Rectangle()
                                            .fill(Color.brown)
                                            .frame(width: max(0, min(geometry.size.width, geometry.size.width * CGFloat(min(chickenManager.xp, maxXP)) / CGFloat(maxXP))))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .frame(height: 20)
                        }
                        .padding(.horizontal, 20)
                        
                        // 三個屬性顯示
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("力量:")
                                    .font(.body)
                                    .foregroundColor(Color(.darkBackground))
                                Spacer()
                                Text("\(chickenManager.strength)")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(.darkBackground))
                            }
                            
                            HStack {
                                Text("耐力:")
                                    .font(.body)
                                    .foregroundColor(Color(.darkBackground))
                                Spacer()
                                Text("\(chickenManager.endurance)")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(.darkBackground))
                            }
                            
                            HStack {
                                Text("柔軟度:")
                                    .font(.body)
                                    .foregroundColor(Color(.darkBackground))
                                Spacer()
                                Text("\(chickenManager.flexibility)")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(.darkBackground))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 15)
                        .background(Color.white.opacity(0.5))
                        .cornerRadius(15)
                        .padding(.horizontal, 20)
                        
                        // 角色圖片
                        Image("example")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 250, height: 300)
                            .padding()
                        
                        // 兩個按鈕
                        HStack(spacing: 20) {
                            // 調味按鈕
                            Button(action: {
                                // TODO: 實現調味功能
                                print("調味按鈕被點擊")
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
                                print("造型按鈕被點擊")
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
                    .padding(.top, 20)
                }
            }
        }
        .navigationTitle("我的肌胸肉")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("BackgroundColor"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
                    print("XP: \(chickenManager.xp)")
                    print("力量: \(chickenManager.strength)")
                    print("耐力: \(chickenManager.endurance)")
                    print("柔軟度: \(chickenManager.flexibility)")
                    print("氨基酸: \(chickenManager.aminoCoin)")
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

