//  MyChickenMeatView.swift
//  01
//
//  Created by 李恩亞 on 2025/5/2.
//

import SwiftUI
import Lottie

struct MyChickenMeatView: View {
    @ObservedObject private var chickenManager = MyChickenManager.shared
    @Binding var path: [ShopRoute]
    @State private var isLoading = false
    @State private var loadError: String?
    private let animationManager = AnimationManager.shared

    // 根據 XP 計算階段名稱
    private var stageName: String {
        let xp = chickenManager.xp

        if xp < 10 {
            switch chickenManager.Stage {
            case "healthy":
                return "健康肌胸"
            case "thin":
                return "瘦瘦肌胸"
            case "fat":
                return "胖胖肌胸"
            case "baby":
                fallthrough
            default:
                return "寶寶肌胸"
            }
        } else if xp <= 20 {
            return "健康肌胸"
        } else {
            return "壯壯肌胸"
        }
    }

    // 優先根據已儲存的 Stage 載入對應動畫，若沒有再回退到 XP 規則
    private var idleAnimationURLString: String? {
        let currentStyleRaw = chickenManager.style["currently"] as? String ?? Style.idle.rawValue
        let currentStyle = Style(rawValue: currentStyleRaw) ?? .idle
        return animationManager.getAnimationURL(stage: chickenManager.Stage, xp: chickenManager.xp, style: currentStyle)
    }
    
    // 是否為 healthy_idle 動畫（用 XP 判斷避免 URL 版本變動）
    private var isHealthyIdle: Bool {
        chickenManager.xp >= 3
    }

    private var maxXP: Int {
        chickenManager.xp <= 10 ? 10 : 50
    }
    
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
                        // 左上角按鈕（前往商店頁面）
                        Button {
                            guard path.last != .store else { return }
                            path.append(.store)
                        } label: {
                            Image("store")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .padding(16)
                                .background(Color("PrimaryColor"))
                                .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 60, height: 60)
                        .contentShape(Rectangle())
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(lineWidth: 1)
                        }
                        
                        Spacer()
                        
                        // 標題
                        Text("我的肌胸肉")
                            .font(.system(size: 30))
                            .fontWeight(.bold)
                            .foregroundColor(Color(.darkBackground))
    
                        
                        Spacer()
                        
                        // 右上角氨基酸顯示
                        HStack(spacing: 5) {
                            Image("animo_acid")
                                .resizable()
                                .frame(width: 25, height: 25)
                            Text("x \(chickenManager.aminoCoin)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // MARK: - 主要內容區
                    HStack(alignment: .top, spacing: 15) {
                        VStack(alignment: .leading,) {
                            Text("階段")
                                .font(.caption)
                                .foregroundColor(Color(.darkBackground).opacity(0.7))
                                .font(.system(size: 35))
                            Text(stageName)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.darkBackground))
                                .font(.system(size: 40))
                        }
                        .frame(width: 180, height: 120)
                        .background(
                            Image("chicken_stageBG")
                                .resizable()
                                .scaledToFill()
                                .scaleEffect(1.2)
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
                                    .font(.system(size: 35))
                                
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
                                        .font(.system(size: 35))
                                    Text("\(chickenManager.strength)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(.darkBackground))
                                        .font(.system(size: 35))
                                }
                                
                                HStack {
                                    Text("耐力：")
                                        .font(.subheadline)
                                        .foregroundColor(Color(.darkBackground))
                                        .font(.system(size: 35))
                                    Text("\(chickenManager.endurance)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(.darkBackground))
                                        .font(.system(size: 35))
                                }
                                
                                HStack {
                                    Text("柔軟度：")
                                        .font(.subheadline)
                                        .foregroundColor(Color(.darkBackground))
                                        .font(.system(size: 35))
                                    Text("\(chickenManager.flexibility)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(.darkBackground))
                                        .font(.system(size: 35))
                                }
                            }
                        }
                        .frame(width: 150)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                    // MARK: - 角色圖片
                    if let idleAnimationURLString,
                       let url = URL(string: idleAnimationURLString) {
                        LottieViewStorage2(url: url)
                            .frame(width: isHealthyIdle ? 150 : 120,
                                   height: isHealthyIdle ? 150 : 120)
                            .frame(maxWidth: .infinity)
                            .offset(y: -20)
                            .padding(.bottom, 30)
                    }
                    
                    Spacer()
                    // MARK: - 底部按鈕
                    HStack(spacing: 20) {
                        // 調味按鈕
                        NavigationLink(value: ShopRoute.flavor) {
                            Text("調味")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("PrimaryColor"))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .overlay{RoundedRectangle(cornerRadius:10)
                            .stroke(lineWidth: 1)}
                        
                        // 造型按鈕
                        NavigationLink(value: ShopRoute.style) {
                            Text("造型")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("PrimaryColor"))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
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
        MyChickenMeatView(path: .constant([]))
    }
}
