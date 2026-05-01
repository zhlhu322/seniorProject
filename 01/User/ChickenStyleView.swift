//
//  ChickenStyleView.swift
//  01
//
//  Created by 許雅涵 on 2025/11/24.
//

import SwiftUI
import Lottie

struct ChickenStyleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var chickenManager = MyChickenManager.shared
    private let animationManager = AnimationManager.shared

    @State private var selectedStyle: Style = .idle
    @State private var currentAnimationURL = ""
    @State private var isSavingStyle = false
    @State private var alertMessage = ""
    @State private var showAlert = false

    private let styleOptions: [StyleOption] = [
        StyleOption(title: "原味", imageName: "xmark", style: .idle, isSystemImage: true),
        StyleOption(title: "香蕉皮", imageName: "style_banana", style: .banana),
        StyleOption(title: "烤火雞", imageName: "style_roast", style: .roast)
    ]

    private var animationSize: CGFloat {
        chickenManager.xp >= 10 ? 150 : 120
    }

    var body: some View {
        ZStack {
            Color("BackgroundColor")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer()

                if let url = URL(string: currentAnimationURL), !currentAnimationURL.isEmpty {
                    LottieViewStorage(url: url)
                        .id(currentAnimationURL)
                        .allowsHitTesting(false)
                        .frame(width: animationSize, height: animationSize)
                        .frame(maxWidth: .infinity)
                        .offset(y: -20)
                        .padding(.bottom, 30)
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.45))
                        .frame(width: animationSize, height: animationSize)
                        .overlay {
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity)
                        .offset(y: -20)
                        .padding(.bottom, 30)
                }

                Spacer()

                stylePickerSection
            }

            if showAlert {
                styleAlertOverlayView
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            chickenManager.loadChickenData { _ in
                let storedStyleRaw = chickenManager.style["currently"] as? String ?? Style.idle.rawValue
                selectedStyle = Style(rawValue: storedStyleRaw) ?? .idle
                updateAnimation()
            }
        }
        .onChange(of: chickenManager.xp) { _, _ in
            updateAnimation()
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 17, weight: .medium))
                }
                .foregroundStyle(Color(red: 0.45, green: 0.30, blue: 0.18))
            }

            Spacer()

            Text("造型")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color(.darkBackground))

            Spacer()

            Color.clear
                .frame(width: 56, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var stylePickerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("選擇一個喜歡的造型吧")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(.darkBackground))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(styleOptions) { option in
                        StyleCard(
                            option: option,
                            isSelected: selectedStyle == option.style,
                            ownedCount: ownedCount(for: option.style),
                            isDisabled: !canSelect(option.style)
                        )
                        .onTapGesture {
                            applyStyle(option.style)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }

    private var styleAlertOverlayView: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissStyleAlert()
                }

            VStack(spacing: 18) {
                Text("提示")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.darkBackground))

                Text(alertMessage)
                    .font(.headline)
                    .foregroundColor(Color(.darkBackground).opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Button {
                    dismissStyleAlert()
                } label: {
                    Text("確定")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("PrimaryColor"))
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.18), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 28)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
        }
        .zIndex(1)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: showAlert)
    }

    private func ownedCount(for style: Style) -> Int? {
        guard style != .idle else { return nil }
        return chickenManager.style[style.rawValue] as? Int ?? 0
    }

    private func canSelect(_ style: Style) -> Bool {
        guard style != .idle else { return true }
        return (chickenManager.style[style.rawValue] as? Int ?? 0) > 0
    }

    private func applyStyle(_ style: Style) {
        guard !isSavingStyle else { return }

        guard canSelect(style) else {
            alertMessage = "尚未擁有這個造型"
            showAlert = true
            return
        }

        let previousStyle = selectedStyle
        selectedStyle = style
        updateAnimation()
        isSavingStyle = true

        chickenManager.updateCurrentStyle(style) { error in
            isSavingStyle = false

            if let error {
                selectedStyle = previousStyle
                updateAnimation()
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }

    private func updateAnimation() {
        currentAnimationURL = animationManager.getAnimationURL(xp: chickenManager.xp, style: selectedStyle) ?? ""
    }

    private func dismissStyleAlert() {
        showAlert = false
    }
}

struct LottieViewStorage: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView()
        view.contentMode = .scaleAspectFit
        view.loopMode = .loop

        loadAnimation(into: view, context: context)

        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        guard context.coordinator.currentURL != url else { return }

        loadAnimation(into: uiView, context: context)
    }

    private func loadAnimation(into view: LottieAnimationView, context: Context) {
        context.coordinator.currentURL = url

        LottieAnimation.loadedFrom(url: url, closure: { animation in
            guard let animation else { return }
            DispatchQueue.main.async {
                view.stop()
                view.animation = animation
                view.play()
            }
        }, animationCache: nil)
    }

    final class Coordinator {
        var currentURL: URL?
    }
}

private struct StyleOption: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let style: Style
    var isSystemImage = false
}

private struct StyleCard: View {
    let option: StyleOption
    let isSelected: Bool
    let ownedCount: Int?
    let isDisabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(option.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(red: 0.43, green: 0.35, blue: 0.28))

                Spacer()
            }

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)

                if option.isSystemImage {
                    Image(systemName: option.imageName)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Color(.darkBackground).opacity(0.55))
                } else {
                    Image(option.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(18)
                }
            }
            .frame(width: 118, height: 118)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? Color("PrimaryColor") : Color(red: 0.55, green: 0.53, blue: 0.50),
                        lineWidth: isSelected ? 3 : 1.5
                    )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isSelected ? Color.white : Color.white.opacity(0.92))
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        .opacity(isDisabled ? 0.55 : 1)
    }
}

#Preview {
    NavigationStack {
        ChickenStyleView()
    }
}
