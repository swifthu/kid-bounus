import Foundation
import SwiftData

/// 加减分项按归属孩子过滤：kidID 为 nil 的通用项对两个孩子都可见。
enum ItemFilter {
    /// 「两个孩子通用」在 Picker 里的占位 tag，不是合法 UUID。
    static let allKidsTag = "*"

    static func visible(_ items: [PointItem], kidID: UUID?) -> [PointItem] {
        guard let kidID else {
            // 孩子还没从 store 加载出来时，宁可只显示通用项，也不要闪出别人的专属项
            return items.filter { $0.kidID == nil }
        }
        return items.filter { $0.kidID == nil || $0.kidID == kidID }
    }
}
