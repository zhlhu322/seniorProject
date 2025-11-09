import SwiftUI
import Combine

/// 管理 tab bar 顯示狀態，可在多處觀察與更新
final class TabBarVisibilityManager: ObservableObject {
    @Published var isVisible: Bool = true

    func update(isVisible: Bool) {
        DispatchQueue.main.async {
            self.isVisible = isVisible
        }
    }
}
