//
//  ChickenFlavorView.swift
//  01
//
//  Created by Codex on 2025/02/14.
//

import SwiftUI
import Lottie

struct ChickenFlavorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var chickenManager = MyChickenManager.shared
    private let animationManager = AnimationManager.shared

    @State private var selectedFlavor: Style = .idle
    @State private var currentAnimationURL = ""
    @State private var isSavingFlavor = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var isAnimationLoading = true

    private let flavorOptions: [FlavorOption] = [
        FlavorOption(title: "原味", imageName: "xmark", flavor: .idle, isSystemImage: true),
        FlavorOption(title: "香草味", imageName: "style_vanilla", flavor: .vanilla),
        FlavorOption(title: "辣味", imageName: "style_spicy", flavor: .spicy)
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
                    ZStack {
                        if isAnimationLoading {
                            ProgressView()
                                .controlSize(.large)
                                .scaleEffect(1.4)
                        }

                        LottieViewStorage(
                            url: url,
                            onLoadingStateChange: { isLoading in
                                isAnimationLoading = isLoading
                            }
                        )
                        .id(currentAnimationURL)
                        .allowsHitTesting(false)
                        .opacity(isAnimationLoading ? 0 : 1)
                    }
                    .frame(width: animationSize, height: animationSize)
                    .frame(maxWidth: .infinity)
                    .offset(y: -20)
                    .padding(.bottom, 30)
                } else {
                    ProgressView()
                        .controlSize(.large)
                        .scaleEffect(1.4)
                        .frame(maxWidth: .infinity)
                        .frame(width: animationSize, height: animationSize)
                        .offset(y: -20)
                        .padding(.bottom, 30)
                }

                Spacer()

                flavorPickerSection
            }

            if showAlert {
                flavorAlertOverlayView
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            chickenManager.loadChickenData { _ in
                let storedFlavorRaw = chickenManager.style["currently"] as? String ?? Style.idle.rawValue
                selectedFlavor = supportedFlavor(from: storedFlavorRaw)
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

            Text("調味")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color(.darkBackground))

            Spacer()

            Color.clear
                .frame(width: 56, height: 24)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    private var flavorPickerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("選擇一個喜歡的口味吧")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(.darkBackground))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(flavorOptions) { option in
                        FlavorCard(
                            option: option,
                            isSelected: selectedFlavor == option.flavor,
                            ownedCount: ownedCount(for: option.flavor),
                            isDisabled: !canSelect(option.flavor)
                        )
                        .onTapGesture {
                            applyFlavor(option.flavor)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }

    private var flavorAlertOverlayView: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissFlavorAlert()
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
                    dismissFlavorAlert()
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

    private func supportedFlavor(from rawValue: String) -> Style {
        switch Style(rawValue: rawValue) {
        case .spicy:
            return .spicy
        case .vanilla:
            return .vanilla
        default:
            return .idle
        }
    }

    private func ownedCount(for flavor: Style) -> Int? {
        guard flavor != .idle else { return nil }
        return chickenManager.flavoring[flavor.rawValue] ?? 0
    }

    private func canSelect(_ flavor: Style) -> Bool {
        guard flavor != .idle else { return true }
        return (chickenManager.flavoring[flavor.rawValue] ?? 0) > 0
    }

    private func applyFlavor(_ flavor: Style) {
        guard !isSavingFlavor else { return }

        guard canSelect(flavor) else {
            alertMessage = "尚未擁有這個調味"
            showAlert = true
            return
        }

        let previousFlavor = selectedFlavor
        selectedFlavor = flavor
        updateAnimation()
        isSavingFlavor = true

        chickenManager.updateCurrentFlavor(flavor) { error in
            isSavingFlavor = false

            if let error {
                selectedFlavor = previousFlavor
                updateAnimation()
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }

    private func updateAnimation() {
        isAnimationLoading = true
        currentAnimationURL = animationManager.getAnimationURL(stage: chickenManager.Stage, xp: chickenManager.xp, style: selectedFlavor) ?? ""
    }

    private func dismissFlavorAlert() {
        showAlert = false
    }
}

private struct FlavorOption: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let flavor: Style
    var isSystemImage = false
}

private struct FlavorCard: View {
    let option: FlavorOption
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

                if let ownedCount {
                    Text("x\(ownedCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color(.darkBackground).opacity(0.65))
                }
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
        ChickenFlavorView()
    }
}
