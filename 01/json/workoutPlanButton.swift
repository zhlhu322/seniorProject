import SwiftUI

struct workoutPlanButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    let onInfoTap: () -> Void

    var body: some View {
        HStack {
            Button(action: onTap) {
                Text(title)
                    .font(.system(size: 18, design: .default))
                    .foregroundStyle(isSelected ? Color.white : Color.black)
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: onInfoTap) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .frame(width: 340, height: 80)
        .background(isSelected ? Color.accentColor : Color(.primary))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(lineWidth: 1)
                .foregroundStyle(Color(.black))
        )
    }
} 
