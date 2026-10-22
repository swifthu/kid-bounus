import Foundation
import SwiftData

@Model
final class PointItem {
    @Attribute(.unique) var id: UUID
    var kind: Kind
    var title: String
    var delta: Int
    var iconName: String?
    var desc: String
    /// 归属孩子。nil 表示两个孩子通用，老数据迁移上来时也是 nil。
    var kidID: UUID?
    /// 用过多少次，首页按它排「最近常用」
    /// 带默认值，老数据迁移上来时这一列才不会是空的
    var usageCount: Int = 0

    init(id: UUID = UUID(), kind: Kind, title: String, delta: Int,
         iconName: String? = nil, desc: String, kidID: UUID? = nil, usageCount: Int = 0) {
        self.id = id
        self.kind = kind
        self.title = title
        self.delta = delta
        self.iconName = iconName
        self.desc = desc
        self.kidID = kidID
        self.usageCount = usageCount
    }
}
