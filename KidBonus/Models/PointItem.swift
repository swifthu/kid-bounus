import Foundation
import SwiftData

@Model
final class PointItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var pointCost: Int
    var kind: Kind
    var isActive: Bool
    var iconName: String
    var desc: String

    init(
        id: UUID = UUID(),
        title: String,
        pointCost: Int,
        kind: Kind,
        isActive: Bool = true,
        iconName: String = "",
        desc: String = ""
    ) {
        self.id = id
        self.title = title
        self.pointCost = pointCost
        self.kind = kind
        self.isActive = isActive
        self.iconName = iconName
        self.desc = desc
    }
}
