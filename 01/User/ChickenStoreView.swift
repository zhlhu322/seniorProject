import SwiftUI
//test bundler update

struct ChickenStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var chickenManager = MyChickenManager.shared
    @State private var isPurchasing = false
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var alertImageName: String?

    private let sections: [StoreSection] = [
        StoreSection(
            title: "調味",
            items: [
                StoreItem(title: "匈牙利紅椒粉", price: 15, imageName: "style_spicy", category: .flavoring, itemKey: "spicy"),
                StoreItem(title: "義式香草", price: 20, imageName: "style_vanilla", category: .flavoring, itemKey: "vanilla")
            ]
        ),
        StoreSection(
            title: "造型",
            items: [
                StoreItem(title: "香蕉皮服裝", price: 10, imageName: "style_banana", category: .style, itemKey: "banana"),
                StoreItem(title: "烤火雞服裝", price: 25, imageName: "style_roast", category: .style, itemKey: "roast")
            ]
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color("PrimaryColor")
                    .ignoresSafeArea()

                Image("StoreBG")
                    .resizable()
                    .scaledToFit() // 不裁切
                    .frame(
                        width: geometry.size.width * 1.1,
                        height: geometry.size.height * 1.1
                    )
                    .offset(x: -18)

                VStack(spacing: 0) {
                    topBar
                    welcomeBubble
                    Spacer(minLength: 0)
                    storePanel
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 8)
                .padding(.bottom, max(20, geometry.safeAreaInsets.bottom + 10))

                if showAlert {
                    storeAlertOverlayView
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            chickenManager.loadChickenData { _ in }
        }
    }

    private var topBar: some View {
        ZStack {
            Text("肌能時尚工坊")
                .font(.system(size: 25, weight: .bold))
                .foregroundColor(Color(.darkBackground))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(width: 180)
                .offset(x: -14)

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

                coinBadge
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
    }

    private var coinBadge: some View {
        HStack(spacing: 6) {
            ZStack {
                Image("animo_acid")
                    .font(.system(size: 11, weight: .bold))
            }

            Text("x \(chickenManager.aminoCoin)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.12))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.95, green: 0.70, blue: 0.28))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(red: 0.37, green: 0.24, blue: 0.13), lineWidth: 1.5)
        )
        .offset(x: -35)
    }

    private var welcomeBubble: some View {
        HStack {
            Spacer()

            Text("我是小肌胸老闆！您想買什麼呢～")
                .font(.system(size: 13, weight: .bold))
                .multilineTextAlignment(.leading)
                .foregroundStyle(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(width: 140)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.96, green: 0.72, blue: 0.34))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                        .foregroundStyle(.white.opacity(0.9))
                )
    
        }
        .padding(.horizontal, 18)
        .offset(x: -90, y: 180)
    }

    private var storePanel: some View {
        VStack {
            storeSections
        }
        .frame(maxWidth: 250)
        .padding(.bottom, 10)
        .padding(.horizontal, 15)
        .offset(x: -14, y: -100)
    }

    private var storeSections: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    Text(section.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color(red: 0.47, green: 0.37, blue: 0.30))

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8)
                        ],
                        spacing: 14
                    ) {
                        ForEach(section.items) { item in
                            StoreItemCard(
                                item: item,
                                isPurchasing: isPurchasing,
                                onPurchase: {
                                    purchase(item)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private var storeAlertOverlayView: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissStoreAlert()
                }

            VStack(spacing: 18) {
                Text("提示")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.darkBackground))

                if let alertImageName {
                    Image(alertImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                }

                Text(alertMessage)
                    .font(.headline)
                    .foregroundColor(Color(.darkBackground).opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Button {
                    dismissStoreAlert()
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

    private func purchase(_ item: StoreItem) {
        guard !isPurchasing else { return }

        guard chickenManager.aminoCoin >= item.price else {
            alertMessage = "AminoCoin 不足"
            alertImageName = nil
            showAlert = true
            return
        }

        isPurchasing = true
        chickenManager.purchaseItem(amount: item.price, category: item.category, itemKey: item.itemKey) { error in
            isPurchasing = false

            if let error {
                alertMessage = error.localizedDescription
                alertImageName = nil
            } else {
                alertMessage = "已購買 \(item.title)"
                alertImageName = item.imageName
            }

            showAlert = true
        }
    }

    private func dismissStoreAlert() {
        showAlert = false
        alertImageName = nil
    }
}

private struct StoreSection: Identifiable {
    let id = UUID()
    let title: String
    let items: [StoreItem]
}

private struct StoreItem: Identifiable {
    let id = UUID()
    let title: String
    let price: Int
    let imageName: String
    let category: StoreItemCategory
    let itemKey: String
}

private struct StoreItemCard: View {
    let item: StoreItem
    let isPurchasing: Bool
    let onPurchase: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.43, green: 0.35, blue: 0.28))
                    .frame(maxWidth: .infinity, minHeight: 20)

                ZStack {
                    Image(item.imageName)
                        .resizable()
                        .scaledToFit()
                }
                .frame(height: 40)
                .padding(.horizontal, 8)
            }
            .padding(.top, 12)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)

            Button(action: onPurchase) {
                HStack(spacing: 1) {
                    Image("animo_acid")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(red: 0.13, green: 0.64, blue: 0.79))

                    Text("\(item.price)")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Color(red: 0.35, green: 0.24, blue: 0.14))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(red: 0.95, green: 0.70, blue: 0.30))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 0.37, green: 0.24, blue: 0.13), lineWidth: 1.5)
                )
            }
            .buttonStyle(.plain)
            .disabled(isPurchasing)
            .opacity(isPurchasing ? 0.7 : 1)
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(red: 0.55, green: 0.53, blue: 0.50), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        .frame(width: 120)
    }
}



#Preview {
    NavigationStack {
        ChickenStoreView()
    }
}
