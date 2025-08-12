import SwiftUI

struct exerciseInfoButton: View {
    let title: String
    let onTap: () -> Void
    let imageURL: String
    let onSelect: (() -> Void)?
    let isSelected: Bool?

    var body: some View {
        let image: Image = {
            if !imageURL.isEmpty, UIImage(named: imageURL) != nil {
                return Image(imageURL)
            } else {
                return Image(systemName: "photo")
            }
        }()

        let backgroundColor: Color = {
            if isSelected ?? false {
                return Color(.accent)
            } else {
                return Color(.primary)
            }
        }()

        HStack(alignment: .bottom) {
            Button(action: {
                onSelect?()
            }) {
                VStack(alignment: .leading) {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 50)
                        .frame(height: 50)
                        .foregroundColor(imageURL.isEmpty ? .gray : nil)

                    Text(title)
                        .font(.title3)
                        .foregroundColor((isSelected ?? false) ? .white : .black)
                }
            }

            Spacer()

            Button(action: onTap) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .frame(width: UIScreen.main.bounds.width * 0.45, height: 120)
        .background(backgroundColor)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(lineWidth: 1)
                .foregroundColor(.black)
        )
    }
}
