//
//  ComparisonSummaryCard.swift
//  01
//
//  顯示「本期 vs 上期」比較摘要的共用卡片元件
//

import SwiftUI

// MARK: - 資料模型
struct ComparisonItem {
    let icon: String
    let iconColor: Color
    let label: String
    let currentText: String
    /// nil = 無上期資料可比較
    let changePercent: Double?
    let previousText: String?

    /// 計算百分比變化；previous == 0 且 current == 0 → nil（無意義）
    static func percent(current: Int, previous: Int) -> Double? {
        if previous == 0 { return current > 0 ? 100.0 : nil }
        return Double(current - previous) / Double(previous) * 100.0
    }

    static func percent(current: Double, previous: Double) -> Double? {
        if previous == 0 { return current > 0 ? 100.0 : nil }
        return (current - previous) / previous * 100.0
    }
}

// MARK: - 主元件
struct ComparisonSummaryCard: View {
    let title: String
    let items: [ComparisonItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 標題列
            HStack(spacing: 6) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.darkBackground))
            }

            // 指標列
            HStack(alignment: .top, spacing: 0) {
                ForEach(items.indices, id: \.self) { i in
                    itemCell(items[i])
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if i < items.count - 1 {
                        Divider()
                            .frame(height: 64)
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - 單一指標格
    @ViewBuilder
    private func itemCell(_ item: ComparisonItem) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            // icon + label
            HStack(spacing: 5) {
                Image(systemName: item.icon)
                    .font(.caption2)
                    .foregroundColor(item.iconColor)
                Text(item.label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // 本期數值
            Text(item.currentText)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(Color(.darkBackground))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            // 變化標籤
            if let pct = item.changePercent {
                changeBadge(pct, previousText: item.previousText)
            } else {
                Text("暫無上期資料")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - 漲跌標籤
    @ViewBuilder
    private func changeBadge(_ percent: Double, previousText: String?) -> some View {
        let isFlat = abs(percent) < 0.5
        let isUp   = percent > 0

        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: isFlat ? "minus" : (isUp ? "arrow.up" : "arrow.down"))
                    .font(.caption2)
                Text(isFlat ? "持平" : "\(Int(abs(percent).rounded()))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .foregroundColor(badgeColor(isFlat: isFlat, isUp: isUp))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(badgeColor(isFlat: isFlat, isUp: isUp).opacity(0.12))
            .cornerRadius(8)

            if let prev = previousText {
                Text("上期 \(prev)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }

    private func badgeColor(isFlat: Bool, isUp: Bool) -> Color {
        isFlat ? .gray : (isUp ? Color("MyMint") : .red)
    }
}
