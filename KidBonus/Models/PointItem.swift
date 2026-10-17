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

    init(id: UUID = UUID(), kind: Kind, title: String, delta: Int, iconName: String? = nil, desc: String) {
        self.id = id
        self.kind = kind
        self.title = title
        self.delta = delta
        self.iconName = iconName
        self.desc = desc
    }
}
