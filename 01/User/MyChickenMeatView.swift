//  MyChickenMeatView.swift
//  01
//
//  Created by 李橋亞 on 2025/5/2.
//

import SwiftUI
import Lottie

struct MyChickenMeatView: View {
    @ObservedObject private var chickenManager = MyChickenManager.shared
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var showSeasoningView = false

    // 根據 XP 計算階段名稱
    private var stageName: String {
        let xp = chickenManager.xp
        if xp < 3 {
            return "寶寶肌胸"
        } else if xp < 6 {
            return "健康肌胸"
        } else if xp < 9 {
            return "強壯肌胸"
        } else if xp < 12 {
            return "完美肌胸"
        } else {
            return "終極肌胸"
        }
    }

    // 根據 XP 計算對應的 idle 動畫 URL（不進行賦值，只是衍生）
    private var idleAnimationURLString: String {
        let xp = chickenManager.xp
        if xp < 3 {
            return "https://firebasestorage.googleapis.com/v0/b/countbuddy-app.firebasestorage.app/o/Stage%2Fbaby_idle.json?alt=media&token=2636bbab-0463-45e4-9a8b-c5e6eff87570"
        } else {
            // 之後可依不同階段替換不同動畫，目前示範 healthy_idle3
            print("使用 healthy_idle 動畫")
            return "https://firebasestorage.googleapis.com/v0/b/countbuddy-app.firebasestorage.app/o/Stage%2Fhealthy_idle3.json?alt=media&token=728e7165-ac73-4ae7-8e96-a97835c43101"
        }
    }
    
    // 是否為 healthy_idle 動畫（用 XP 判斷避免 URL 版本變動）
    private var isHealthyIdle: Bool {
        chickenManager.xp >= 3
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
                    if let url = URL(string: idleAnimationURLString) {
                        LottieViewStorage2(url: url)
                            .frame(width: isHealthyIdle ? 150 : 120,
                                   height: isHealthyIdle ? 150 : 120)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 30)
                    }
                    
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
                                .cornerRadius(10)
                        }
                        .overlay{RoundedRectangle(cornerRadius:10)
                            .stroke(lineWidth: 1)}
                        
                        // 造型按鈕
                        NavigationLink(destination: ChickenStyleView()) {
                            Text("造型")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("PrimaryColor"))
                                .cornerRadius(10)
                        }
                        .overlay{RoundedRectangle(cornerRadius:10)
                            .stroke(lineWidth: 1)}
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 每次進入頁面都重新載入一次資料，觸發 XP 與動畫 URL 的最新判斷
            loadChickenData()
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
                    print("✅ 小雞資料已載入，xp=\(chickenManager.xp)")
                }
            }
        }
    }
}

struct LottieViewStorage2: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView()
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop

        LottieAnimation.loadedFrom(url: url, closure: { animation in
            guard let animation = animation else {
                print("❌ Lottie 動畫載入失敗")
                return
            }
            DispatchQueue.main.async {
                view.animation = animation
                view.play()
            }
        }, animationCache: nil)

        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}

#Preview {
    NavigationStack {
        MyChickenMeatView()
    }
}
