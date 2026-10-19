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

    init(id: UUID = UUID(), kind: Kind, title: String, delta: Int,
         iconName: String? = nil, desc: String, kidID: UUID? = nil) {
        self.id = id
        self.kind = kind
        self.title = title
        self.delta = delta
        self.iconName = iconName
        self.desc = desc
        self.kidID = kidID
    }
}
