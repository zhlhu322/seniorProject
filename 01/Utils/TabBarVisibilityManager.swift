import SwiftUI
import Combine

/// 管理 tab bar 顯示狀態，支援計數式 hide requests（request/release 模式）
final class TabBarVisibilityManager: ObservableObject {
    @Published private(set) var isVisible: Bool = true
    private var hideRequests: Int = 0

    /// 要求隱藏 tab bar（可重複呼叫）
    func requestHide() {
        DispatchQueue.main.async {
            self.hideRequests += 1
            self.isVisible = (self.hideRequests == 0)
        }
    }

    /// 釋放隱藏請求（當所有 requester 都釋放後，tab bar 才會顯示）
    func releaseHide() {
        DispatchQueue.main.async {
            self.hideRequests = max(0, self.hideRequests - 1)
            self.isVisible = (self.hideRequests == 0)
        }
    }

    /// 直接更新可見性（fallback）
    func update(isVisible: Bool) {
        DispatchQueue.main.async {
            self.hideRequests = isVisible ? 0 : 1
            self.isVisible = isVisible
        }
    }
}
