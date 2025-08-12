import SwiftUI

struct exerciseDetailView: View {
    let detail: ExerciseDetail
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                HStack {
                    Text(detail.name)
                        .font(.largeTitle)
                        .padding(.bottom, 8)
                    Spacer()
                    if !detail.image_name.isEmpty {
                        Image(detail.image_name)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                    }
                }
                .padding(.horizontal)
                
                
                Text("目標肌群：\(detail.target_muscle)")
                Text("使用器材：\(detail.equipment)")
                Text("類型：\(detail.type)")
                if detail.band_position != "X" {
                    Text("手環穿戴位置：\(detail.band_position)")
                }
                Text("執行步驟：")
                    .font(.headline)
                ForEach(detail.steps, id: \.self) { step in
                    Text("• " + step)
                }
                
                Divider()
                
                Text("能力值累計：").foregroundStyle(Color(.white))
                if let s = detail.strength { Text("力量：\(s)").foregroundStyle(Color(.white)) }
                if let e = detail.endurance { Text("耐力：\(e)").foregroundStyle(Color(.white)) }
                if let f = detail.flexibility { Text("柔軟度：\(f)").foregroundStyle(Color(.white)) }
            }
            .padding()
            .frame(height: UIScreen.main.bounds.height * 0.8)
            .background(Color("BackgroundColor").opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
        }
        .padding()
        .navigationTitle("動作說明")
        .background(Color(.primary))
    }
}

#Preview {
    exerciseDetailView(detail: ExerciseDetail(
        id: "1",
        name: "手臂彎舉",
        image_name: "biceps",
        lottie_url:"https://cdn.lottielab.com/l/9iiJoCxhnaQMY7.json",
        target_muscle: "二頭肌",
        equipment: "彈力帶/水瓶",
        type: "動態 計次",
        band_position: "手腕",
        steps: ["站立姿勢，雙腳與肩同寬，手持彈力帶或水瓶，手臂自然下垂。", "保持上臂固定，彎曲肘部，將負重向上拉至肩部附近。", "緩慢放下回到起始位置，完成一個完整動作。"],
        strength: 2,
        endurance: 1,
        flexibility: nil
    ))
}

