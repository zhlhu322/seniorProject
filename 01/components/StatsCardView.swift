//
//  StatsCardView.swift
//  01
//
//  Created by 李恩亞 on 2025/10/22.
//

import SwiftUI

struct StatsCardView: View {
    let iconName: String
    let value: String
    let label: String
    
    var body: some View {
        VStack {
            Image(systemName: iconName)
                .resizable().scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundStyle(Color(.primary))
            Text(value).font(.subheadline)
            Text(label).font(.caption)
        }
        .frame(width: 110, height: 120)
        .background(.white)
        .cornerRadius(10)
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(.myMint), style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
    }
}
