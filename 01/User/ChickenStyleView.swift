//
//  ChickenStyleView.swift
//  01
//
//  Created by 許雅涵 on 2025/11/24.
//

import SwiftUI
import Lottie

struct ChickenStyleView: View {
    
    // Firebase Storage Lottie JSON URL
    private let idleURL = "https://firebasestorage.googleapis.com/v0/b/countbuddy-app.firebasestorage.app/o/Stage%2Fbaby_idle.json?alt=media&token=2636bbab-0463-45e4-9a8b-c5e6eff87570"
    
    private let bananaURL = "https://firebasestorage.googleapis.com/v0/b/countbuddy-app.firebasestorage.app/o/Stage%2Fbaby_banana.json?alt=media&token=845cbf33-2797-44cc-bc5e-90060d1a19ef"
    
    private let roastURL = "https://firebasestorage.googleapis.com/v0/b/countbuddy-app.firebasestorage.app/o/Stage%2Fbaby_roast.json?alt=media&token=21c111b9-82ec-4d38-a5b4-3888ad6279da"
    
    @State private var selectedSeasoning: String? = "無"
    @State private var currentAnimationURL: String = ""
    
    let seasonings = [
        SeasoningItem(name: "無", imageName: "xmark", isDefault: true),
        SeasoningItem(name: "Chicken Banana", imageName: "BananaStyle"),
        SeasoningItem(name: "Chicken Roast", imageName: "RoastStyle")
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 導航欄
            HStack {
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16))
                        Text("返回")
                            .font(.system(size: 17))
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                }
                
                Spacer()
                
                Text("我的肌胸肉")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16))
                    Text("返回")
                        .font(.system(size: 17))
                }
                .opacity(0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 50)
            .padding(.bottom, 16)
            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
            
            
            // 主要內容區域
            VStack(spacing: 0) {
                
                Spacer()
                
                // 使用 Lottie 動畫 (Firebase Storage JSON)
                if let url = URL(string: currentAnimationURL) {
                    LottieViewStorage(url: url)
                        .frame(height: 400)
                }
                
                Spacer()
                
                HStack {
                    Text("我的調味")
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(seasonings) { seasoning in
                            SeasoningCard(
                                seasoning: seasoning,
                                isSelected: selectedSeasoning == seasoning.name
                            )
                            .onTapGesture {
                                selectedSeasoning = seasoning.name
                                updateAnimationForSeasoning()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 40)
            }
            .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        }
        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            currentAnimationURL = idleURL
        }
    }
    
    
    private func updateAnimationForSeasoning() {
        switch selectedSeasoning {
        case "Chicken Banana":
            currentAnimationURL = bananaURL
        case "Chicken Roast":
            currentAnimationURL = roastURL
        default:
            currentAnimationURL = idleURL
        }
    }
}


// MARK: - Lottie 動畫支援

struct LottieViewStorage: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView()
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop
        
        LottieAnimation.loadedFrom(url: url) { animation in
            view.animation = animation
            view.play()
        }
        return view
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}


// MARK: - Models + Cards

struct SeasoningItem: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    var isDefault: Bool = false
}

struct SeasoningCard: View {
    let seasoning: SeasoningItem
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Text(seasoning.name)
                .font(.system(size: 15))
                .foregroundColor(.black)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(seasoning.isDefault ? Color(red: 0.85, green: 0.85, blue: 0.85) : .white)
                    .frame(width: 100, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.8, green: 0.8, blue: 0.8), lineWidth: 1)
                    )
                
                if seasoning.isDefault {
                    Image(systemName: seasoning.imageName)
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                }
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
